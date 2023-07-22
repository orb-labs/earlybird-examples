// utils/TestToken.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(uint256 amount) public {
        _mint(_msgSender(), amount);
    }
}
