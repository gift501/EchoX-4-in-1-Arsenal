// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEchoXNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(uint256 quantity) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool approved) external;
}

interface IEchoXToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint() external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IEchoXPoints {
    function recordNftForExSwap(address user) external;
    function recordNftForNftSwap(address user) external;
    function recordReferralTaskCompletion(address referrer, address referredUser) external;
    function recordBatchSwap(address user, uint256 nftCount) external;
    function recordLpParticipation(address user, address pool) external;
    function recordDailySwap(address user) external;
    function recordPoolCreation(address user) external;
    function recordPoolTransaction(address poolCreator) external;
    function recordMemeCreation(address user) external;
    function recordMemeTransaction(address memeCreator) external;
    function recordDexAggregatorTrade(address user, uint256 amountUsd) external;
    function giveBonus(address user, uint256 amount, string calldata reason) external;
    function getPoints(address user) external view returns (uint256);
}
