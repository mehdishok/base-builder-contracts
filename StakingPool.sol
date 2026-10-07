// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title StakingPool
/// @notice Simple staking pool with reward calculation and minimum stake
contract StakingPool {
    address public immutable owner;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public constant MIN_STAKE = 0.001 ether;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastUpdate;

    error NotOwner();
    error BelowMinStake();
    error InsufficientBalance();
    error TransferFailed();

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function _updateReward(address user) internal {
        if (stakedBalance[user] > 0) {
            uint256 pending = (block.timestamp - lastUpdate[user]) * stakedBalance[user] * rewardRate / 1e18;
            rewardDebt[user] += pending;
        }
        lastUpdate[user] = block.timestamp;
    }

    function stake() external payable {
        if (msg.value < MIN_STAKE) revert BelowMinStake();

        _updateReward(msg.sender);
        stakedBalance[msg.sender] += msg.value;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        if (stakedBalance[msg.sender] < amount) revert InsufficientBalance();

        _updateReward(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external {
        _updateReward(msg.sender);
        uint256 reward = rewardDebt[msg.sender];
        if (reward == 0) return;

        rewardDebt[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        if (!success) revert TransferFailed();

        emit RewardClaimed(msg.sender, reward);
    }

    function getPendingReward(address user) external view returns (uint256) {
        uint256 pending = rewardDebt[user];
        if (stakedBalance[user] > 0) {
            pending += (block.timestamp - lastUpdate[user]) * stakedBalance[user] * rewardRate / 1e18;
        }
        return pending;
    }

    function getStakedBalance(address user) external view returns (uint256) {
        return stakedBalance[user];
    }
}
