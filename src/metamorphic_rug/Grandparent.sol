// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Parent} from "./Parent.sol";

contract Grandparent {
    Parent public parent;

    function deployParent(uint256 _salt) external returns (address) {
        parent = new Parent{salt: bytes32(_salt)}(); // this uses CREATE2
		return address(parent);
    }
}
