// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EchoXNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    string public constant metadataURI = "ipfs://bafkreicaeorv426fpnh6n3u6h32yju2o7ddeirxvnjks6adz6byiqd5uvi";

    constructor() ERC721("EchoX NFT", "EXNFT") Ownable(msg.sender) {}

    function mintThreeNFTs(address to) public {
        for (uint256 i = 0; i < 3; i++) {
            uint256 newTokenId = tokenCounter;
            _safeMint(to, newTokenId);
            _setTokenURI(newTokenId, metadataURI);
            tokenCounter++;
        }
    }
}
