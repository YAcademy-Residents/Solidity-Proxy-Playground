// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LibFixed {
    uint public someNumber;
    // Technically the storage layout should match the contract that performs the delegatecall()
    // but because this contract can only modify one state variable,
    // matching only the first variable is fine

    function doSomething(uint _num) public {
        someNumber = _num;
    }
}
