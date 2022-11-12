// SPDX-License-Identifier: MIT
// NOTE: These contracts have a critical bug.
// DO NOT USE THIS IN PRODUCTION
pragma solidity ^0.8.13;


contract ShadyContract {
    address public constant ATTACKER_CONTRACT_ADDRESS = address(0xB0FFEDC0DE);


    function superSafeFunction96508587(address) external {
        // this fn is totally safu
    }

    function verySafeNotARug() public {
        (, bytes memory ret) = address(this).delegatecall(
            abi.encodeWithSelector(
                ShadyContract.superSafeFunction96508587.selector,
                ATTACKER_CONTRACT_ADDRESS
            )
        );
    }
}
