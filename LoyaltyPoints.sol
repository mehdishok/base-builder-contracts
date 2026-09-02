// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title LoyaltyPoints
/// @notice Simple points system that can be earned and redeemed
contract LoyaltyPoints {
    address public immutable owner;
    string public name;
    string public symbol;
    uint8 public constant decimals = 0;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isMerchant;

    error NotOwner();
    error NotMerchant();
    error InsufficientPoints();
    error ZeroAmount();
    error ZeroAddress();

    event PointsEarned(address indexed user, uint256 amount, address indexed merchant);
    event PointsRedeemed(address indexed user, uint256 amount, address indexed merchant);
    event MerchantUpdated(address indexed merchant, bool status);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        isMerchant[msg.sender] = true;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyMerchant() {
        if (!isMerchant[msg.sender]) revert NotMerchant();
        _;
    }

    function setMerchant(address merchant, bool status) external onlyOwner {
        if (merchant == address(0)) revert ZeroAddress();
        isMerchant[merchant] = status;
        emit MerchantUpdated(merchant, status);
    }

    function earnPoints(address user, uint256 amount) external onlyMerchant {
        if (user == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        balanceOf[user] += amount;
        totalSupply += amount;

        emit PointsEarned(user, amount, msg.sender);
        emit Transfer(address(0), user, amount);
    }

    function redeemPoints(address user, uint256 amount) external onlyMerchant {
        if (user == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (balanceOf[user] < amount) revert InsufficientPoints();

        balanceOf[user] -= amount;
        totalSupply -= amount;

        emit PointsRedeemed(user, amount, msg.sender);
        emit Transfer(user, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        if (balanceOf[msg.sender] < amount) revert InsufficientPoints();

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function getBalance(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}