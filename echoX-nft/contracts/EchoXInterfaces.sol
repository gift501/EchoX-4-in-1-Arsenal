// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEchoXNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(uint256 quantity) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IEchoXToken {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint() external;
}
