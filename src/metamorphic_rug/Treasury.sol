// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Treasury {
	address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	function initialize() external {
        require(owner == address(0), "Initialized");
        owner = msg.sender;
	}

    function transfer() external onlyOwner {
        bool sent;
        (sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
