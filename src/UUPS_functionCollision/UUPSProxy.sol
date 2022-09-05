// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// A simple implementation of the UUPS proxy.
// Similar to TransparentProxy but `setImplementation` logic is found in the implementation contract
// If a new implementation contract is set that does not contain setImplementation logic, then this becomes
// a non-upgradeable proxy.

contract UUPSProxy {
    address public immutable owner;
    address public implementation;

    constructor(address implementation_, address owner_) {
        implementation = implementation_;
        owner = owner_;
    }

    fallback() external payable {
        require(msg.sender == owner);

        address implementation_ = implementation;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch space at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // delegatecall the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let success := delegatecall(
                gas(),
                implementation_,
                0,
                calldatasize(),
                0,
                0
            )

            // copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch success
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
