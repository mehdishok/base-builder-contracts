// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Crowdfund
/// @notice Simple crowdfunding contract with goal and deadline
contract Crowdfund {
    address public immutable creator;
    uint256 public immutable goal;
    uint256 public immutable deadline;
    uint256 public totalRaised;
    bool public goalReached;
    bool public fundsWithdrawn;

    mapping(address => uint256) public contributions;

    error DeadlinePassed();
    error DeadlineNotReached();
    error GoalNotReached();
    error AlreadyWithdrawn();
    error ZeroContribution();
    error TransferFailed();

    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 total);
    event FundsWithdrawn(address indexed creator, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);

    constructor(uint256 _goal, uint256 _durationInDays) {
        require(_goal > 0, "Goal must be > 0");
        require(_durationInDays > 0, "Duration must be > 0");
        creator = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() external payable {
        if (block.timestamp > deadline) revert DeadlinePassed();
        if (msg.value == 0) revert ZeroContribution();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit Contribution(msg.sender, msg.value);

        if (totalRaised >= goal && !goalReached) {
            goalReached = true;
            emit GoalReached(totalRaised);
        }
    }

    function withdrawFunds() external {
        if (msg.sender != creator) revert TransferFailed();
        if (!goalReached) revert GoalNotReached();
        if (fundsWithdrawn) revert AlreadyWithdrawn();

        fundsWithdrawn = true;
        uint256 amount = address(this).balance;

        (bool success, ) = payable(creator).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(creator, amount);
    }

    function refund() external {
        if (block.timestamp <= deadline) revert DeadlineNotReached();
        if (goalReached) revert GoalNotReached();

        uint256 amount = contributions[msg.sender];
        if (amount == 0) revert ZeroContribution();

        contributions[msg.sender] = 0;
        totalRaised -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Refund(msg.sender, amount);
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    function getContribution(address user) external view returns (uint256) {
        return contributions[user];
    }
}