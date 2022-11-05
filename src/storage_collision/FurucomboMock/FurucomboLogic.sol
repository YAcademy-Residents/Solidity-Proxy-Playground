// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

	function getmsgSender() external view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

	event whoSender(address sender);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
		emit whoSender(_msgSender());
		emit whoSender(_owner);
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @notice The handler registry database for Furucombo
contract Registry is Ownable {
    mapping(address => bytes32) public infos;

    bytes32 public constant DEPRECATED = bytes10(0x64657072656361746564);

    /**
     * @notice Register a handler with a bytes32 information.
     * @param registration Handler address.
     * @param info Info string.
     * @dev Dapps that triggers callback function should also be registered.
     * In this case, registration is the Dapp address and the leading 20 bytes
     * of info is the handler address.
     */
    function register(address registration, bytes32 info) external onlyOwner {
        require(registration != address(0), "zero address");
        require(infos[registration] != DEPRECATED, "unregistered");
        infos[registration] = info;
    }

    /**
     * @notice Unregister a handler. The handler will be deprecated.
     * @param registration The handler to be unregistered.
     */
    function unregister(address registration) external onlyOwner {
        require(registration != address(0), "zero address");
        require(infos[registration] != bytes32(0), "no registration");
        require(infos[registration] != DEPRECATED, "unregistered");
        infos[registration] = DEPRECATED;
    }

    /**
     * @notice Check if the handler is valid.
     * @param handler The handler to be verified.
     */
    function isValid(address handler) external view returns (bool result) {
        if (infos[handler] == 0 || infos[handler] == DEPRECATED) return false;
        else return true;
    }
}