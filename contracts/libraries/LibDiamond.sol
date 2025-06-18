// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndSelectorPosition) selectorToFacetAndPosition;
        mapping(address => bytes4[]) facetFunctionSelectors;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    function setContractOwner(address _newOwner) internal {
        diamondStorage().contractOwner = _newOwner;
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            IDiamondCut.FacetCutAction action = _diamondCut[i].action;
            address facetAddress = _diamondCut[i].facetAddress;
            bytes4[] memory selectors = _diamondCut[i].functionSelectors;

            require(selectors.length > 0, "No selectors in facet");

            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(facetAddress, selectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, selectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(facetAddress, selectors);
            } else {
                revert("Invalid FacetCutAction");
            }
        }

        emit IDiamondCut.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _selectors
    ) internal {
        require(_facetAddress != address(0), "Facet address can't be 0");
        DiamondStorage storage ds = diamondStorage();

        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            require(
                ds.selectorToFacetAndPosition[selector].facetAddress ==
                    address(0),
                "Selector exists"
            );
            ds.selectorToFacetAndPosition[
                selector
            ] = FacetAddressAndSelectorPosition(
                _facetAddress,
                uint16(ds.facetFunctionSelectors[_facetAddress].length)
            );
            ds.facetFunctionSelectors[_facetAddress].push(selector);
        }

        if (ds.facetFunctionSelectors[_facetAddress].length == 0) {
    ds.facetAddresses.push(_facetAddress);
}

    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _selectors
    ) internal {
        require(_facetAddress != address(0), "Facet address can't be 0");
        DiamondStorage storage ds = diamondStorage();

        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            address oldFacet = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(oldFacet != _facetAddress, "Replacing with same facet");
            removeSelector(selector);
            ds.selectorToFacetAndPosition[
                selector
            ] = FacetAddressAndSelectorPosition(
                _facetAddress,
                uint16(ds.facetFunctionSelectors[_facetAddress].length)
            );
            ds.facetFunctionSelectors[_facetAddress].push(selector);
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _selectors
    ) internal {
        require(
            _facetAddress == address(0),
            "Remove action facet must be address(0)"
        );
        for (uint256 i = 0; i < _selectors.length; i++) {
            removeSelector(_selectors[i]);
        }
    }

    function removeSelector(bytes4 selector) internal {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        require(facet != address(0), "Selector does not exist");

        uint256 last = ds.facetFunctionSelectors[facet].length - 1;
        uint256 pos = ds.selectorToFacetAndPosition[selector].selectorPosition;

        if (pos != last) {
            bytes4 lastSelector = ds.facetFunctionSelectors[facet][last];
            ds.facetFunctionSelectors[facet][pos] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .selectorPosition = uint16(pos);
        }

        ds.facetFunctionSelectors[facet].pop();
        delete ds.selectorToFacetAndPosition[selector];
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "init is 0 but calldata is not empty"
            );
        } else {
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            require(success, string(error));
        }
    }
}
