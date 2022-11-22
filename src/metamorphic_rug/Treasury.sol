// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Treasury {
    address public owner;
    IERC20 public token;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initialize(IERC20 _token) external {
        require(owner == address(0), "Initialized");
        owner = msg.sender;
        token = _token;
        // approve all to owner - multisig contract
        token.approve(owner, type(uint256).max);
    }
}
