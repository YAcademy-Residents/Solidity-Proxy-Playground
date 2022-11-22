// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreasuryToken is ERC20, Ownable {
    constructor() ERC20("TreasuryToken", "TST") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
