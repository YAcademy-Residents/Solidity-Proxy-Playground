// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

// code partially borrowed from https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786

contract TestToken is Initializable, ERC20, UUPSUpgradeable, Ownable {

	constructor() ERC20("TestToken", "TTK") {
		initialize();
    }

    function initialize() initializer public {
		_transferOwnership(_msgSender()); // copied from Ownable constructor
		_mint(_msgSender(), 10 ether);
    }

    // @note this function should have the onlyOwner modifier
    function _authorizeUpgrade(address) internal override onlyOwner {

    }
}