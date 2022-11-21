// SPDX-License-Identifier: MIT
// NOTE: These contracts have a critical bug.
// DO NOT USE THIS IN PRODUCTION
pragma solidity ^0.8.13;

contract Implementation {

    address public benignAddress;

    function setBenignAddress(address benignAddress_) external {
        benignAddress = benignAddress_;
    }
}