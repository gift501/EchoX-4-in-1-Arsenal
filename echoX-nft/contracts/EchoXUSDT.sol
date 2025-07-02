// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EchoXUSDT is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 10_000_000_000 * 10 ** 18;

    mapping(address => bool) private hasMintedOneBillion;

    constructor() ERC20("EchoX USDT", "EXTUSDT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mintOneBillion() public {
        require(!hasMintedOneBillion[msg.sender], "You have already minted 1 billion tokens.");

        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());

        hasMintedOneBillion[msg.sender] = true;
    }
}
