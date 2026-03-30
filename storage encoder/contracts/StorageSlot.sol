// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StorageSlot
/// @notice Compute EVM storage slot indices for mappings and dynamic arrays (Solidity layout rules).
library StorageSlot {
    /// @dev Solidity: `mapping(K => V) m` at slot `p` → key `k` lies at `keccak256(abi.encode(k, p))`.
    function mappingSlot(uint256 baseSlot, bytes32 key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, uint256(baseSlot)));
    }

    function mappingSlotAddress(uint256 baseSlot, address key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, uint256(baseSlot)));
    }

    function mappingSlotUint(uint256 baseSlot, uint256 key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, uint256(baseSlot)));
    }

    /// @dev Nested: `mapping(K1 => mapping(K2 => V))` at `p` → `slot(innerKey, slot(outerKey, p))` using inner base = outer slot.
    function nestedMappingSlot(uint256 baseSlot, bytes32 outerKey, bytes32 innerKey) internal pure returns (bytes32) {
        bytes32 mid = mappingSlot(baseSlot, outerKey);
        return keccak256(abi.encode(innerKey, uint256(mid)));
    }

    /// @dev Dynamic array at slot `p`: element `i` starts at `keccak256(p) + i` (word offset, not byte).
    function dynamicArrayElementSlot(uint256 baseSlot, uint256 index) internal pure returns (bytes32) {
        bytes32 root = keccak256(abi.encode(uint256(baseSlot)));
        return bytes32(uint256(root) + index);
    }

    /// @dev `bytes` / `string` at slot `p`: short values in slot; long values at `keccak256(p)` with length in low bits of `p`.
    function bytesHashSlot(uint256 baseSlot) internal pure returns (bytes32) {
        return keccak256(abi.encode(uint256(baseSlot)));
    }
}
