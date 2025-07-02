// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EchoXToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 500_000_000 * 10 ** 18;

    constructor() ERC20("EchoX Test Token", "EX") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mintHundred() public {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
}
