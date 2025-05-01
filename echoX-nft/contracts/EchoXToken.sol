// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EchoXToken is ERC20 {
    constructor() ERC20("EchoX Test Token", "EX") {
        _mint(msg.sender, 500_000_000 * 10 ** decimals()); // Mint initial supply to the contract creator
    }

    // Make this public so anyone can mint one EX token
    function mintOne() public {
        _mint(msg.sender, 1 * 10 ** decimals());
    }
}
