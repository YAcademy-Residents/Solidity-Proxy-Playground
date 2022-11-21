// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Child} from "./Child.sol";

contract Parent2 {
    uint256 public balance;

	function addBalance(uint256 _add) external returns (uint256) {
		balance += _add * 2;
	}
}
