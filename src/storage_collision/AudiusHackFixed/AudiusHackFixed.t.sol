// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {AudiusAdminUpgradeabilityProxy} from "./Proxy/AudiusAdminUpgradeabilityProxy.sol";
import {Proxy} from "./Proxy/Proxy.sol";
import {DelegateManager} from "./Logic/DelegateManager.sol";
import {Governance} from "./Governance.sol";

// writeup: https://blog.audius.co/article/audius-governance-takeover-post-mortem-7-23-22

contract AudiusHackFixed is Test {
    AudiusAdminUpgradeabilityProxy public adminAddress;
    DelegateManager public delegateAddress;
    Governance public govAddress;
    address public alice;
    address public targetAddr;

    function setUp() public {
        alice = address(0xABCD);
        delegateAddress = new DelegateManager();
        govAddress = new Governance();
        targetAddr = 0x4DEcA517D6817B6510798b7328F2314d3003AbAC; // @note in prod, 0x4deca517d6817b6510798b7328f2314d3003abac is governance address

        vm.etch(targetAddr, address(govAddress).code);

        adminAddress = new AudiusAdminUpgradeabilityProxy(
            address(delegateAddress),
            address(targetAddr),
            ""
        );
    }

    // In the fixed version of the initializer modifier, only the admin can call initialize()
    function testFailDirectInitialize() public {
        bytes32 beforeaction = vm.load(
            address(delegateAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(beforeaction)); // log the first storage slot value
        assertEq(uint256(beforeaction), 0);

        // Cannot call initialize() without the proxy because the proxyAdmin variable is never set in DelegateManager.sol. The proxy must be used for proxyAdmin in DelegateManager.sol to have a value.
        vm.prank(address(adminAddress.getAudiusProxyAdminAddress())); // @note switch to random address to show there are no special privileges needed to call initialize()
        delegateAddress.initialize();
    }

    // When initialize() is called directly, it can only be called once. Calling initialize() a second time causes an error
    function testFailDirectIntialize() public {
        bytes32 beforeaction = vm.load(
            address(delegateAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(beforeaction)); // log the first storage slot value
        assertEq(uint256(beforeaction), 0);

        vm.prank(address(alice)); // @note switch to random address to show there are no special privileges needed to call initialize()
        delegateAddress.initialize();

        bytes32 afteraction = vm.load(
            address(delegateAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(afteraction)); // log the first storage slot value
        assertEq(uint256(afteraction), 1);

        // @note calling initialize() a 2nd time does not work, because the proper boolean values in DelegateManager.sol are set (initialized = true, initializing = false)
        delegateAddress.initialize();
    }

    // When using the AudiusAdminUpgradeabilityProxy.sol proxy's delegatecall(), we see the issue.
    // The issue is that the specific address of the governance contract makes the initializer modifier useless
    // because the last 2 bytes of the governance address sets
    function testDelegatecall() public {
        bytes32 beforeaction = vm.load(
            address(adminAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(beforeaction)); // log the first storage slot value

        // Check first bool value (no offset)
        assertEq(uint256(beforeaction) & 0x01, 0); // demonstrates that `bool initialized = false;` in initializer modifier
        // Check second bool value (8 bit offset, use bitshift >> 8)
        assertEq((uint256(beforeaction) & 0x0100) >> 8, 1); // demonstrates that `bool initializing = true;` in initializer modifier
        // @note `require(initializing || isConstructor() || !initialized)` logic in Initialiable.sol initializer modifier accepts the above bool values

        // Prank to send call as proxy admin
        emit log_address(adminAddress.getAudiusProxyAdminAddress()); // log the first storage slot value
        vm.prank(address(adminAddress.getAudiusProxyAdminAddress())); // @note switch to random address to show there are no special privileges needed to call initialize()

        // Call initialize for the first time using the proxy
        (bool init_bool, bytes memory init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(init_bool);
    }

    // When the governance address is changed
    function testDelegatecallTwice() public {
        bytes32 beforeaction = vm.load(
            address(adminAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(beforeaction)); // log the first storage slot value

        // Check first bool value (no offset)
        assertEq(uint256(beforeaction) & 0x01, 0); // demonstrates that `bool initialized = false;` in initializer modifier
        // Check second bool value (8 bit offset, use bitshift >> 8)
        assertEq((uint256(beforeaction) & 0x0100) >> 8, 1); // demonstrates that `bool initializing = true;` in initializer modifier
        // @note `require(initializing || isConstructor() || !initialized)` logic in Initialiable.sol initializer modifier accepts the above bool values

        // Prank to send call as proxy admin
        emit log_address(adminAddress.getAudiusProxyAdminAddress()); // log the first storage slot value
        vm.prank(address(adminAddress.getAudiusProxyAdminAddress())); // @note switch to random address to show there are no special privileges needed to call initialize()

        // Call initialize for the first time using the proxy
        (bool init_bool, bytes memory init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(init_bool);

        // Call initialize for the 2nd time fails because the storage slots are properly aligned now
        (init_bool, init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertFalse(init_bool);
    }
}
