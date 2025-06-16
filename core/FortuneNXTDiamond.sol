// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title FortuneNXTDiamond
 * @dev Modular contract system using the Diamond Standard (EIP-2535)
 */
contract FortuneNXTDiamond {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Events
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Structs
    struct Facet {
        address facetAddress;
        EnumerableSet.Bytes32Set functionSelectors;
    }

    struct FacetCut {
        address facetAddress;
        bytes4[] functionSelectors;
        FacetCutAction action;
    }

    struct FacetInfo {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    // Enum for facet cut actions
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    // Storage
    address public owner;
    mapping(bytes4 => address) internal selectorToFacetAddress;
    mapping(address => Facet) internal _facets;
    address[] internal _facetAddresses;

    /**
     * @dev Initializes the diamond with facets
     */
    constructor(FacetCut[] memory _diamondCut) {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _diamondCutInternal(_diamondCut, address(0), "");
    }

    receive() external payable {}

    fallback() external payable {
        address facet = selectorToFacetAddress[msg.sig];
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function diamondCut(
        FacetCut[] memory diamondCutParam,
        address _init,
        bytes memory _calldata
    ) external {
        require(msg.sender == owner, "Diamond: Not authorized");
        _diamondCutInternal(diamondCutParam, _init, _calldata);
    }

    function _diamondCutInternal(
        FacetCut[] memory diamondCutData,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 i = 0; i < diamondCutData.length; ++i) {
            FacetCut memory cut = diamondCutData[i];

            if (cut.action == FacetCutAction.Add) {
                _addFunctions(cut.facetAddress, cut.functionSelectors);
            } else if (cut.action == FacetCutAction.Replace) {
                _replaceFunctions(cut.facetAddress, cut.functionSelectors);
            } else if (cut.action == FacetCutAction.Remove) {
                _removeFunctions(cut.functionSelectors);
            } else {
                revert("Diamond: Invalid action");
            }
        }

        emit DiamondCut(diamondCutData, _init, _calldata);

        if (_init != address(0)) {
            if (_calldata.length > 0) {
                Address.functionDelegateCall(_init, _calldata);
            } else {
                Address.functionDelegateCall(
                    _init,
                    abi.encodeWithSignature("init()")
                );
            }
        }
    }

    function _addFunctions(
        address _facetAddress,
        bytes4[] memory _selectors
    ) internal {
        require(_facetAddress != address(0), "Diamond: Invalid facet address");
        require(_selectors.length > 0, "Diamond: No selectors provided");

        Facet storage facet = _facets[_facetAddress];

        if (facet.facetAddress == address(0)) {
            _facetAddresses.push(_facetAddress);
            facet.facetAddress = _facetAddress;
        }

        for (uint256 i = 0; i < _selectors.length; ++i) {
            bytes4 selector = _selectors[i];
            require(
                selectorToFacetAddress[selector] == address(0),
                "Diamond: Function exists"
            );
            facet.functionSelectors.add(bytes32(selector));
            selectorToFacetAddress[selector] = _facetAddress;
        }
    }

    function _replaceFunctions(
        address _facetAddress,
        bytes4[] memory _selectors
    ) internal {
        require(_facetAddress != address(0), "Diamond: Invalid facet address");
        require(_selectors.length > 0, "Diamond: No selectors provided");

        for (uint256 i = 0; i < _selectors.length; ++i) {
            bytes4 selector = _selectors[i];
            address oldFacet = selectorToFacetAddress[selector];
            require(oldFacet != address(0), "Diamond: Function does not exist");
            require(oldFacet != _facetAddress, "Diamond: Same facet");

            _facets[oldFacet].functionSelectors.remove(bytes32(selector));
            Facet storage facet = _facets[_facetAddress];
            if (facet.facetAddress == address(0)) {
                _facetAddresses.push(_facetAddress);
                facet.facetAddress = _facetAddress;
            }

            facet.functionSelectors.add(bytes32(selector));
            selectorToFacetAddress[selector] = _facetAddress;
        }
    }

    function _removeFunctions(bytes4[] memory _selectors) internal {
        require(_selectors.length > 0, "Diamond: No selectors");

        for (uint256 i = 0; i < _selectors.length; ++i) {
            bytes4 selector = _selectors[i];
            address currentFacet = selectorToFacetAddress[selector];
            require(currentFacet != address(0), "Diamond: Function not found");

            _facets[currentFacet].functionSelectors.remove(bytes32(selector));
            delete selectorToFacetAddress[selector];

            if (_facets[currentFacet].functionSelectors.length() == 0) {
                for (uint256 j = 0; j < _facetAddresses.length; ++j) {
                    if (_facetAddresses[j] == currentFacet) {
                        _facetAddresses[j] = _facetAddresses[
                            _facetAddresses.length - 1
                        ];
                        _facetAddresses.pop();
                        break;
                    }
                }

                delete _facets[currentFacet];
            }
        }
    }

    // ========================= View Methods =========================

    function getOwner() external view returns (address) {
        return owner;
    }

    function facetAddresses() external view returns (address[] memory) {
        return _facetAddresses;
    }

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory) {
        Facet storage facet = _facets[_facet];
        uint256 len = facet.functionSelectors.length();
        bytes4[] memory selectors = new bytes4[](len);
        for (uint256 i = 0; i < len; ++i) {
            selectors[i] = bytes4(facet.functionSelectors.at(i));
        }
        return selectors;
    }

    function facetAddress(bytes4 _selector) external view returns (address) {
        return selectorToFacetAddress[_selector];
    }

    function functionExists(bytes4 _selector) external view returns (bool) {
        return selectorToFacetAddress[_selector] != address(0);
    }

    function facets() external view returns (FacetInfo[] memory facets_) {
        uint256 count = _facetAddresses.length;
        facets_ = new FacetInfo[](count);

        for (uint256 i = 0; i < count; ++i) {
            address facetAddr = _facetAddresses[i];
            Facet storage facet = _facets[facetAddr];

            uint256 selectorCount = facet.functionSelectors.length();
            bytes4[] memory selectors = new bytes4[](selectorCount);
            for (uint256 j = 0; j < selectorCount; ++j) {
                selectors[j] = bytes4(facet.functionSelectors.at(j));
            }

            facets_[i] = FacetInfo({
                facetAddress: facetAddr,
                functionSelectors: selectors
            });
        }
    }

    // ========================= Ownership =========================

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Diamond: Not authorized");
        require(_newOwner != address(0), "Diamond: Invalid new owner");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // ========================= Optional ERC-165 Support =========================

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == 0x48e2b093 || // IDiamondCut
            interfaceId == 0x7a0ed627 || // IDiamondLoupe
            interfaceId == 0x01ffc9a7; // ERC165
    }
}
// Note: The above contract is a simplified version of a diamond contract that allows for modular upgrades and management of facets.
// It includes basic functionality for adding, replacing, and removing facets, as well as ownership management.
// The contract uses OpenZeppelin's libraries for address and enumerable sets, ensuring safe and efficient operations.
// The fallback function delegates calls to the appropriate facet based on the function selector.
