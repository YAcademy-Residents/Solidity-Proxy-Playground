// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Lib} from "./Lib.sol";
import {HackMe} from "./HackMe.sol";
import {Attack} from "./Attack.sol";

import {HackMeFixed} from "./HackMeFixed.sol";

contract ContractTest is Test {
    // These contracts are from https://solidity-by-example.org/hacks/delegatecall/
    Lib public libContract;
    HackMe public hackMeContract;
    Attack public attackContract;
    HackMeFixed public hackMeFixedContract;

    function setUp() public {
        // Vulnerable versions of contracts
        libContract = new Lib();
        hackMeContract = new HackMe(address(libContract));
        attackContract = new Attack(hackMeContract);

        // Fixed version of contracts
        hackMeFixedContract = new HackMeFixed(address(libContract));
    }

    function testLibDoSomething() public {
        libContract.doSomething(42);
        assertTrue(libContract.someNumber() == 42);
    }

    function testHackMeDoSomething() public {
        assertTrue(hackMeContract.lib() == address(libContract));
        libContract.doSomething(42);
        // The next line was intended to modify `someNumber` in libContract, but actually modifies hackMeContract.lib()
        hackMeContract.doSomething(77);
        assertTrue(libContract.someNumber() == 42);
        assertTrue(hackMeContract.lib() == address(77)); // Intended result was libContract.someNumber() == 77
    }

    function testAttack() public {
        attackContract.attack(); // Sets the state variable `lib` in hackMeContract is attackContract
        assertTrue(hackMeContract.owner() == address(attackContract)); // attackContract is now the owner of hackMeContract
    }

    function testFixed() public {
        libContract.doSomething(1337);
        assertTrue(libContract.someNumber() == 1337);
    
        hackMeFixedContract.doSomething(77);
        assertTrue(hackMeFixedContract.someNumber() == 77);
        assertTrue(libContract.someNumber() == 1337);
    }
}
