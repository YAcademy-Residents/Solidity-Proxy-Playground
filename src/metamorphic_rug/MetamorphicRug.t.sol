// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Grandparent} from "./Grandparent.sol";
import {Parent} from "./Parent.sol";
import {Child} from "./Child.sol";

contract MetamorphicRug is Test {
    Grandparent public grandparentContract;
	address public parentAddr;
    address public childAddr;

    function setUp() public {
        grandparentContract = new Grandparent();
        bytes memory bytecode = abi.encodePacked(vm.getCode("Parent.sol"));
		parentAddr =  grandparentContract.deploy(1, bytecode);
        childAddr = Parent(parentAddr).deployChild();

		// Never make assertions in the setUp function. Failed assertions won't result with failed test.
		// But if the test fails, failed assert will be visible
		// https://book.getfoundry.sh/tutorials/best-practices?highlight=setup#general-test-guidance
		assertEq(parentAddr, grandparentContract.parent());

		// The selfdestruct call must be done in setUp() due to a foundry limitation: https://github.com/foundry-rs/foundry/issues/1543
		Parent(parentAddr).delegateFunction();
		Child(childAddr).destroy();
	}

	// deploying the same contract Parent with the same salt will produce the same address
	function testTheSameContract() public {
		assertEq(parentAddr, grandparentContract.parent());
        bytes memory bytecode = abi.encodePacked(vm.getCode("Parent.sol"));
		address newParrentAddr =  grandparentContract.deploy(1, bytecode);
		assertEq(newParrentAddr, parentAddr);
		assertEq(newParrentAddr, grandparentContract.parent());

		uint256 add = 5;
		assertEq(Parent(parentAddr).balance(), 0);
		Parent(parentAddr).addBalance(add);
		assertEq(Parent(parentAddr).balance(), add);
	}

	// deploying the same contract Parent but with a different salt will produce a different address
	function testDifferentSalt() public {
		assertEq(parentAddr, grandparentContract.parent());
        bytes memory bytecode = abi.encodePacked(vm.getCode("Parent.sol"));
		address newParrentAddr = grandparentContract.deploy(2, bytecode);

		// different salt will produce different parent address
		assertTrue(parentAddr != newParrentAddr);
		assertTrue(parentAddr != grandparentContract.parent());
	}

	// deploying a different contract Parent2 with the same salt will produce the same address
	// new contract will be on the same address but with a different implementation potentially malicious
	function testDifferentContract() public {
        bytes memory bytecode = abi.encodePacked(vm.getCode("Parent2.sol"));
		address newParrentAddr =  grandparentContract.deploy(1, bytecode);
		assertEq(newParrentAddr, parentAddr);
		assertEq(parentAddr, grandparentContract.parent());

		uint256 add = 5;
		assertEq(Parent(parentAddr).balance(), 0);
		Parent(parentAddr).addBalance(add);
		// Parent2 will double add balance
		assertEq(Parent(parentAddr).balance(), add * 2);
	}
}
