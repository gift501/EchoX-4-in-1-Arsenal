// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EchoXInterfaces.sol";
import "./EchoXPool.sol";
import "./EchoXPoints.sol";

contract EchoXCore {
    address public owner;
    IEchoXNFT public nft;
    IEchoXToken public ex;
    EchoXPoints public points;

    uint256 public nftPriceInEx = 0.5 ether;

    mapping(address => address[]) public userPools;

    event PoolCreated(address indexed pool, address indexed creator);
    event NFTSwapped(address user, uint256[] tokenIds);
    event EXStaked(address user, uint256 amount);
    event PointsEarned(address indexed user, uint256 points);

    constructor(address _nft, address _ex, address _points) {
        owner = msg.sender;
        nft = IEchoXNFT(_nft);
        ex = IEchoXToken(_ex);
        points = EchoXPoints(_points);
    }

    function createPool(string memory name) external {
        EchoXPool pool = new EchoXPool(msg.sender, address(nft), address(ex), name, address(points));
        userPools[msg.sender].push(address(pool));
        emit PoolCreated(address(pool), msg.sender);
    }

    function swapNFTForEX(address poolAddr, uint256 tokenId) external {
        EchoXPool pool = EchoXPool(poolAddr);
        nft.safeTransferFrom(msg.sender, poolAddr, tokenId);
        pool.swapForEX(msg.sender, tokenId);
        points.addPoints(msg.sender, 5);
        emit NFTSwapped(msg.sender, _asSingletonArray(tokenId));
    }

    function swapNFTForNFT(address poolAddr, uint256 fromTokenId, uint256 toTokenId) external {
        EchoXPool(poolAddr).swapNFTtoNFT(msg.sender, fromTokenId, toTokenId);
        points.addPoints(msg.sender, 5);
    }

    function batchSwap(address poolAddr, uint256[] calldata tokenIds) external {
        require(tokenIds.length >= 5, "Minimum 5 NFTs");
        EchoXPool(poolAddr).batchSwap(msg.sender, tokenIds);
        points.addPoints(msg.sender, 6);
        emit NFTSwapped(msg.sender, tokenIds);
    }

    function provideLiquidity(address poolAddr, uint256 amount) external {
        ex.transferFrom(msg.sender, poolAddr, amount);
        EchoXPool(poolAddr).stakeEX(msg.sender, amount);
        points.addPoints(msg.sender, 3);
        emit EXStaked(msg.sender, amount);
    }

function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory arr) {
    arr = new uint256[](1); // Specify the size as 1
    arr[0] = element;
}

}
