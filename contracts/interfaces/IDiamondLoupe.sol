// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDiamondLoupe {
    /// @notice Gets all facet addresses used by the diamond
    /// @return facetAddresses_ An array of facet addresses
    function facetAddresses() external view returns (address[] memory);

    /// @notice Gets all the function selectors provided by a facet
    /// @param _facet The facet address
    /// @return facetFunctionSelectors_ Array of selectors from the facet
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory);

    /// @notice Gets all facets and their selectors
    /// @return facets_ An array of Facet structs
    function facets() external view returns (Facet[] memory);

    /// @notice Gets the facet that supports the given selector
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address);

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
}
