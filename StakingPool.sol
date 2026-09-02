// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title StakingPool
/// @notice Simple ETH staking with reward rate
contract StakingPool {
    address public immutable owner;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public constant SCALE = 1e18;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => StakeInfo) public stakes;

    error ZeroAmount();
    error InsufficientStake();
    error TransferFailed();
    error NotOwner();

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function stake() external payable {
        if (msg.value == 0) revert ZeroAmount();

        _updateReward(msg.sender);

        stakes[msg.sender].amount += msg.value;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (stakes[msg.sender].amount < amount) revert InsufficientStake();

        _updateReward(msg.sender);

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external {
        _updateReward(msg.sender);

        uint256 reward = stakes[msg.sender].rewardDebt;
        if (reward == 0) revert ZeroAmount();

        stakes[msg.sender].rewardDebt = 0;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        if (!success) revert TransferFailed();

        emit RewardClaimed(msg.sender, reward);
    }

    function _updateReward(address user) internal {
        StakeInfo storage userStake = stakes[user];
        if (userStake.amount > 0) {
            uint256 timeDiff = block.timestamp - userStake.lastUpdate;
            uint256 pending = (userStake.amount * rewardRate * timeDiff) / SCALE;
            userStake.rewardDebt += pending;
        }
        userStake.lastUpdate = block.timestamp;
    }

    function pendingReward(address user) external view returns (uint256) {
        StakeInfo memory userStake = stakes[user];
        if (userStake.amount == 0) return userStake.rewardDebt;

        uint256 timeDiff = block.timestamp - userStake.lastUpdate;
        uint256 pending = (userStake.amount * rewardRate * timeDiff) / SCALE;
        return userStake.rewardDebt + pending;
    }

    function setRewardRate(uint256 newRate) external {
        if (msg.sender != owner) revert NotOwner();
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    function getStake(address user) external view returns (uint256) {
        return stakes[user].amount;
    }
}