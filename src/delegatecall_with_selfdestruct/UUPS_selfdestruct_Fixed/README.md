## UUPS selfdestruct vulnerability (Fixed)

This folder, src/UUPS_selfdestruct_Fixed/, contains code to demonstrate a fixed case of the uninitialized UUPS proxy vulnerability [using  GHSA-q4h9-46xg-m3x9](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/security/advisories/GHSA-q4h9-46xg-m3x9), which relies on OpenZeppelin libraries before version 4.3.2. The older library code is found in this project under lib/openzeppelin-contracts-upgradeable-4.3.1. The tests that demonstrate the hack are found in test/UUPS_selfdestruct_Fixed.t.sol.

The original vulnerable code is found in src/SolidityByExampleFixed/ and the tests demonstrating the hack are in test/UUPS_selfdestruct.t.sol file.

The original PoC is found at: https://github.com/yehjxraymond/exploding-kitten