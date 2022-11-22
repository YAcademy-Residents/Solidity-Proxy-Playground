// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Destroy {
    function transfer() public {
 		selfdestruct(payable(msg.sender));
 	}
}
