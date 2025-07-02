// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IECahoXNFT {
    function mintThreeNFTs(address to) external;
}

contract EcahoXNFTMinter {
    IECahoXNFT public nftContract;

    constructor(address _nftAddress) {
        nftContract = IECahoXNFT(_nftAddress);
    }

    function mint() external {
        nftContract.mintThreeNFTs(msg.sender);
    }
}
