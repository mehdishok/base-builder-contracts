// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Escrow
/// @notice Simple escrow between buyer and seller
contract Escrow {
    enum State { Created, Funded, Completed, Refunded, Disputed }

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    State public currentState;

    error InvalidState();
    error NotBuyer();
    error NotSeller();
    error NotArbiter();
    error IncorrectAmount();
    error TransferFailed();

    event Funded(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);
    event Disputed(address indexed by);

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.Created;
    }

    function fund() external payable {
        if (msg.sender != buyer) revert NotBuyer();
        if (currentState != State.Created) revert InvalidState();
        if (msg.value == 0) revert IncorrectAmount();

        amount = msg.value;
        currentState = State.Funded;

        emit Funded(msg.sender, msg.value);
    }

    function release() external {
        if (msg.sender != buyer && msg.sender != arbiter) revert NotBuyer();
        if (currentState != State.Funded && currentState != State.Disputed) revert InvalidState();

        currentState = State.Completed;

        (bool success, ) = payable(seller).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Released(seller, amount);
    }

    function refund() external {
        if (msg.sender != seller && msg.sender != arbiter) revert NotSeller();
        if (currentState != State.Funded && currentState != State.Disputed) revert InvalidState();

        currentState = State.Refunded;

        (bool success, ) = payable(buyer).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Refunded(buyer, amount);
    }

    function dispute() external {
        if (msg.sender != buyer && msg.sender != seller) revert NotBuyer();
        if (currentState != State.Funded) revert InvalidState();

        currentState = State.Disputed;
        emit Disputed(msg.sender);
    }

    function getState() external view returns (string memory) {
        if (currentState == State.Created) return "Created";
        if (currentState == State.Funded) return "Funded";
        if (currentState == State.Completed) return "Completed";
        if (currentState == State.Refunded) return "Refunded";
        return "Disputed";
    }
}