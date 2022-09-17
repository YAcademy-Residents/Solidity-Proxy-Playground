## UUPS selfdestruct vulnerability

This folder, src/UUPS_selfdestruct/, contains code to demonstrate a specific case of the uninitialized UUPS proxy vulnerability [using  GHSA-q4h9-46xg-m3x9](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/security/advisories/GHSA-q4h9-46xg-m3x9), which relies on OpenZeppelin libraries before version 4.3.2. The older library code is found in this project under lib/openzeppelin-contracts-upgradeable-4.3.1. The tests that demonstrate the hack are found in test/UUPS_selfdestruct.t.sol.

The fixed code that is not vulnerable to this issue is found in src/SolidityByExampleFixed/ and the tests demonstrating the fix are in the same test/UUPS_selfdestruct_Fixed.t.sol file.

The original PoC is found at: https://github.com/yehjxraymond/exploding-kitten