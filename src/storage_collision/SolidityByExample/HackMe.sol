// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HackMe {
    address public lib;
    address public owner;
    uint256 public someNumber;

    constructor(address _lib) {
        lib = _lib;
        owner = msg.sender;
    }

    function doSomething(uint256 _num) public {
        lib.delegatecall(abi.encodeWithSignature("doSomething(uint256)", _num));
    }
}
