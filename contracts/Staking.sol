// stake: Lock tokens into our smart contract
// withdraw: Unlock tokens and pull out of the contract
// claimReward: users get their reward tokens

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//custom errors
error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {
    IERC20 public s_stakingToken; //note: storage vars are expensive to read and write
    IERC20 public s_rewardToken;    //note: the reward and staking tokens can be the same if we choose
    
    //map someone's address -> how much they staked
    mapping(address => uint256) public s_balances;
    //mapping of how much each addr has in rewards available for claim
    mapping(address => uint256) public s_rewards;
    //mapping of how much each addr has been paid in rewards
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;
    uint256 public constant REWARD_RATE = 100;

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount==0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns(uint256) {
        uint256 currentBalance = s_balances[account];
        // how much theyve been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return _earned;
    }

    //based on time elapsed since last snapshot
    function rewardPerToken() public view returns(uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    //only allow specific token. if any token were allowed, use Chainlink to get prices between tokens
    //using external bc it's cheaper than public - meaning only accounts outside of this function can call these. with public, can be called externally or by interal functions
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        //keep track of user's supply staked
        //keep track of total supply staked
        //trasnfer tokens to this contract
        s_balances[msg.sender] = s_balances[msg.sender] + amount; //need to update storage vars BEFORE the transfer function to avoid reentrancy attacks
        s_totalSupply = s_totalSupply + amount;
        //TODO: emit event
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        // require(success, "Failed"); //not using require success bc the string for Failed is expensive. instead using the custom error below
        if(!success) {
            revert Staking__TransferFailed();
        }
    }
    
    //TODO: use OpenZeppelin's reentrancy guard
    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        // bool success = s_stakingToken.transferFrom(address(this), msg.sender, amount); //same as line below
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
        //TODO: emit event
    }

    function claimReward() external updateReward(msg.sender) {
        //How much reward to give out per unit time? Other factors such as metadata of an NFT?
        //This contract is going to emit X tokens per second
        //And disperse them to all token stakers
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if(!success) {
            revert Staking__TransferFailed();
        }
        //TODO: emit event
    }





}