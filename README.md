# Proxy Playground

This repository is a collection of proxy implementations. Each type of proxy has a vulnerable implementation and a fixed implementation. Do NOT use the vulnerable versions for production contracts!

## Installing Dependencies

There are two version of `OpenZeppelin/openzeppelin-contracts-upgradeable` because some tests rely on [a vulnerability in v4.3.1](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/security/advisories/GHSA-q4h9-46xg-m3x9).

```
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
forge install YAcademy-Residents/openzeppelin-contracts-upgradeable-4.3.1@v4.3.1
forge install OpenZeppelin/openzeppelin-contracts
```

If you run `forge build` for the first time without installing the dependencies and get error messages, try running it a second time or run `forge test`. Forge has a bug where it may not recognize the installed packages the first the forge is run.