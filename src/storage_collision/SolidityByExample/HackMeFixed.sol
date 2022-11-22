// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HackMeFixed {
    uint256 public someNumber; // Moving this variable to the first storage slot instead of the 3rd fixes the issue
    address public lib;
    address public owner;

    constructor(address _lib) {
        lib = _lib;
        owner = msg.sender;
    }

    function doSomething(uint256 _num) public {
        lib.delegatecall(abi.encodeWithSignature("doSomething(uint256)", _num));
    }
}
