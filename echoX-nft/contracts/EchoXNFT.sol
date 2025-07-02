// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EchoXNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI = "ipfs://bafkreicaeorv426fpnh6n3u6h32yju2o7ddeirxvnjks6adz6byiqd5uvi";

    uint256 public maxSupply = 10000000000;
    bool public isMintEnabled;

    event TokenMinted(address to, uint256 tokenId);

    constructor() ERC721("EcahoXNFT", "EXNFT") {
        isMintEnabled = true;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setIsMintEnabled(bool _isMintEnabled) public onlyOwner {
        isMintEnabled = _isMintEnabled;
    }

    function mintThreeNFTs(address to) public {
        require(isMintEnabled, "Minting is not enabled");
        require(_tokenIds.current() + 3 <= maxSupply, "Max supply exceeded");

        _mintNFT(to);
        _mintNFT(to);
        _mintNFT(to);
    }

    function _mintNFT(address to) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        emit TokenMinted(to, newItemId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}
