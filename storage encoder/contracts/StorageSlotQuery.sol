// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageSlot.sol";

/// @title StorageSlotQuery
/// @notice Expose `StorageSlot` helpers as `view` calls for clients / `eth_call` storage proofs.
contract StorageSlotQuery {
    function mappingSlot(uint256 baseSlot, bytes32 key) external pure returns (bytes32) {
        return StorageSlot.mappingSlot(baseSlot, key);
    }

    function mappingSlotAddress(uint256 baseSlot, address key) external pure returns (bytes32) {
        return StorageSlot.mappingSlotAddress(baseSlot, key);
    }

    function nestedMappingSlot(uint256 baseSlot, bytes32 outerKey, bytes32 innerKey)
        external
        pure
        returns (bytes32)
    {
        return StorageSlot.nestedMappingSlot(baseSlot, outerKey, innerKey);
    }

    function dynamicArrayElementSlot(uint256 baseSlot, uint256 index) external pure returns (bytes32) {
        return StorageSlot.dynamicArrayElementSlot(baseSlot, index);
    }
}
