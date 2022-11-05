// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lib {
    uint public someNumber;

    function doSomething(uint _num) public {
        someNumber = _num;
    }
}
