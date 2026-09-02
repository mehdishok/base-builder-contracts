// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title SimpleAuction
/// @notice English auction for a single item
contract SimpleAuction {
    address public immutable seller;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public immutable endTime;
    bool public ended;
    bool public sellerWithdrawn;

    mapping(address => uint256) public pendingReturns;

    error AuctionAlreadyEnded();
    error AuctionNotYetEnded();
    error BidTooLow();
    error NotSeller();
    error AlreadyWithdrawn();
    error TransferFailed();

    event HighestBidIncreased(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(uint256 _biddingTimeInMinutes) {
        seller = msg.sender;
        endTime = block.timestamp + (_biddingTimeInMinutes * 1 minutes);
    }

    function bid() external payable {
        if (block.timestamp > endTime) revert AuctionAlreadyEnded();
        if (msg.value <= highestBid) revert BidTooLow();

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) return false;

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            pendingReturns[msg.sender] = amount;
            return false;
        }

        emit Withdrawal(msg.sender, amount);
        return true;
    }

    function endAuction() external {
        if (block.timestamp < endTime) revert AuctionNotYetEnded();
        if (ended) revert AuctionAlreadyEnded();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function sellerWithdraw() external {
        if (msg.sender != seller) revert NotSeller();
        if (!ended) revert AuctionNotYetEnded();
        if (sellerWithdrawn) revert AlreadyWithdrawn();

        sellerWithdrawn = true;

        (bool success, ) = payable(seller).call{value: highestBid}("");
        if (!success) revert TransferFailed();
    }

    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }
}