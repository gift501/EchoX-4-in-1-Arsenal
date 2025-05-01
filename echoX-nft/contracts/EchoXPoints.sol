// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EchoXPoints {
    mapping(address => uint256) public userPoints;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function addPoints(address user, uint256 amount) external onlyOwner {
        userPoints[user] += amount;
    }

    function getPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }
}
