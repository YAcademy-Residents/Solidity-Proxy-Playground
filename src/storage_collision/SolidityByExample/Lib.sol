// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lib {
    uint public someNumber;
    // Technically the storage layout should match the contract that performs the delegatecall()
    // but because this implementation contract can only modify or use one state variable,
    // and because there is no upgrade logic, matching only the first variable is fine

    function doSomething(uint _num) public {
        someNumber = _num;
    }
}
