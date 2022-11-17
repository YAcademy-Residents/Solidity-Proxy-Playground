// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Child} from "./Child.sol";

contract Parent {
    Child public _contract;

    function deployChild() external returns (address) {
        _contract = new Child();
		return (address(_contract));
    }

    function delegateFunction() public {
        // This delegatecall will destroy this Parent.sol contract
		// After Parent.sol is destroyed, destroy() in Child.sol can be called directly
		// Then a new Parent.sol and a new Child.sol can be deployed
		bool status;
		(status, ) = address(_contract).delegatecall(abi.encodeWithSignature("destroy()"));
		if (!status) revert();
	}
}
