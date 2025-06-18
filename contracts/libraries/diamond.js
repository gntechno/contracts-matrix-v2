// scripts/libraries/diamond.js

const { ethers } = require("hardhat");

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
};

function getSelectors(contract) {
  const signatures = Object.keys(contract.interface.functions);
  const selectors = signatures
    .filter(val => val !== "init(address)") // Exclude init
    .map(val => contract.interface.getSighash(val));
  return selectors;
}


module.exports = {
  getSelectors,
  FacetCutAction
};
// This module provides utility functions for working with diamond patterns in Solidity.
// It includes a function to get function selectors from a contract and an enumeration for facet cut actions.