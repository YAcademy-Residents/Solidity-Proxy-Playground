// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Child} from "./Child.sol";

contract Parent {
    Child public _contract;
	uint256 public balance;

    function deployChild() external returns (address) {
        _contract = new Child();
		return (address(_contract));
    }

    function delegateFunction() public {
        // This delegatecall will destroy this Parent.sol contract
		// After Parent.sol is destroyed, destroy() in Child.sol can be called directly
		// Then a new Parent.sol or a different Parent2.sol can be deployed
		bool status;
		(status, ) = address(_contract).delegatecall(abi.encodeWithSignature("destroy()"));
		if (!status) revert();
	}

	function addBalance(uint256 _add) external returns (uint256) {
		balance += _add;
	}
}
