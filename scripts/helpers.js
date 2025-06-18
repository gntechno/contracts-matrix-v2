function getSelectors(contract) {
  if (!contract || !contract.interface || typeof contract.interface.getFunction !== 'function') {
    throw new Error("Invalid contract object passed to getSelectors()");
  }

  const selectors = [];
  const functions = Object.values(contract.interface.fragments).filter(
    (f) => f.type === 'function'
  );

  for (const func of functions) {
    const signature = contract.interface.getFunction(func.name).selector;
    selectors.push(signature);
  }

  return selectors;
}

module.exports = {
  getSelectors,
};
// This utility function extracts the function selectors from a contract's interface.
// It can be used to prepare the diamond cut for adding facets to a diamond proxy contract.