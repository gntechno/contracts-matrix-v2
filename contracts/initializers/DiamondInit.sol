// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibDiamond.sol";

contract DiamondInit {
    function init(address _owner) external {
        LibDiamond.setContractOwner(_owner);
    }
}
