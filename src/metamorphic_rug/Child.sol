// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Child {
    address public owner;
	
	constructor() {
		owner = msg.sender;
	}
    function destroy() public {
 		selfdestruct(payable(msg.sender));
 	}
}
