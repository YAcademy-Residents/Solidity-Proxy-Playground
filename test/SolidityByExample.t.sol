// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Lib} from "../src/SolidityByExample/Lib.sol";
import {HackMe} from "../src/SolidityByExample/HackMe.sol";
import {Attack} from "../src/SolidityByExample/Attack.sol";

import {LibFixed} from "../src/SolidityByExampleFixed/Lib.sol";
import {HackMeFixed} from "../src/SolidityByExampleFixed/HackMe.sol";

contract ContractTest is Test {
    // These contracts are from https://solidity-by-example.org/hacks/delegatecall/
    Lib public libContract;
    HackMe public hackMeContract;
    Attack public attackContract;

    LibFixed public libFixedContract;
    HackMeFixed public hackMeFixedContract;

    function setUp() public {
        // Vulnerable versions of contracts
        libContract = new Lib();
        hackMeContract = new HackMe(address(libContract));
        attackContract = new Attack(hackMeContract);

        // Fixed version of contracts
        libFixedContract = new LibFixed();
        hackMeFixedContract = new HackMeFixed(address(libFixedContract));
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
        libFixedContract.doSomething(1337);
        assertTrue(libFixedContract.someNumber() == 1337);
    
        hackMeFixedContract.doSomething(77);
        assertTrue(hackMeFixedContract.someNumber() == 77);
        assertTrue(libFixedContract.someNumber() == 1337);
    }
}
