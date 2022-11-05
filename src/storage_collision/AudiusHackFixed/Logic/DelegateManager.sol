// File: contracts/DelegateManager.sol

pragma solidity ^0.8.13;

import "./InitializableV2.sol";
// import "./SafeMath.sol";
// import "./ERC20Mintable.sol";
// import "./ServiceProviderFactory.sol";

/// @notice SafeMath imported via ServiceProviderFactory.sol
/// @notice Governance imported via Staking.sol

/**
 * Designed to manage delegation to staking contract
 */
contract DelegateManager is InitializableV2 {

    string private constant ERROR_ONLY_GOVERNANCE = (
        "DelegateManager: Only callable by Governance contract"
    );
    string private constant ERROR_MINIMUM_DELEGATION = (
        "DelegateManager: Minimum delegation amount required"
    );
    string private constant ERROR_ONLY_SP_GOVERNANCE = (
        "DelegateManager: Only callable by target SP or governance"
    );
    string private constant ERROR_DELEGATOR_STAKE = (
        "DelegateManager: Delegator must be staked for SP"
    );

    address private governanceAddress;
    address private stakingAddress;
    address private serviceProviderFactoryAddress;
    address private claimsManagerAddress;

    /**
     * Period in  blocks an undelegate operation is delayed.
     * The undelegate operation speed bump is to prevent a delegator from
     *      attempting to remove their delegation in anticipation of a slash.
     * @notice Must be greater than governance votingPeriod + executionDelay
     */
    uint256 private undelegateLockupDuration;

    /// @notice Maximum number of delegators a single account can handle
    uint256 private maxDelegators;

    /// @notice Minimum amount of delegation allowed
    uint256 private minDelegationAmount;

    /**
     * Lockup duration for a remove delegator request.
     * The remove delegator speed bump is to prevent a service provider from maliciously
     *     removing a delegator prior to the evaluation of a proposal.
     * @notice Must be greater than governance votingPeriod + executionDelay
     */
    uint256 private removeDelegatorLockupDuration;

    /**
     * Evaluation period for a remove delegator request
     * @notice added to expiry block calculated for removeDelegatorLockupDuration
     */
    uint256 private removeDelegatorEvalDuration;

}