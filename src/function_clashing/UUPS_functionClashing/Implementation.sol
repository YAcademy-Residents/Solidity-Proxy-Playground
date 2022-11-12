// SPDX-License-Identifier: MIT
// NOTE: These contracts have a critical bug.
// DO NOT USE THIS IN PRODUCTION
pragma solidity ^0.8.13;

contract Implementation {
    address public immutable owner;

    constructor(address owner_) {
        owner = owner_;
    }

    function setImplementation(address implementation_) external {
        require(msg.sender == owner, "only owner");
        assembly {
            sstore(0, implementation_)
        }
    }

    function delegatecallContract(address target, bytes calldata _calldata) external payable {
        (, bytes memory ret) = target.delegatecall(_calldata);
    }

    function doImplementationStuff() external returns (bool) {
        return true;
    }
}
