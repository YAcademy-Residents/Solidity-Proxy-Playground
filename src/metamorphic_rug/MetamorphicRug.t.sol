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
		parentAddr =  grandparentContract.deployParent(1);
        childAddr = Parent(parentAddr).deployChild();
		
		assertTrue(parentAddr == address(grandparentContract.parent()));
		// The selfdestruct call must be done in setUp() due to a foundry limitation: https://github.com/foundry-rs/foundry/issues/1543
		Parent(parentAddr).delegateFunction();
		Child(childAddr).destroy();
	}

	function testMetamorphic() public {
		assertTrue(parentAddr == address(grandparentContract.parent()));
	}

}
