// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StorageEncoderLib
/// @notice Pack and unpack values into a single `bytes32` storage word for tight layout and off-chain encoding.
library StorageEncoderLib {
    function packTwoUint128(uint128 high, uint128 low) internal pure returns (bytes32 word) {
        return bytes32((uint256(high) << 128) | uint256(low));
    }

    function unpackTwoUint128(bytes32 word) internal pure returns (uint128 high, uint128 low) {
        uint256 w = uint256(word);
        high = uint128(w >> 128);
        low = uint128(w);
    }

    /// @notice `address` in upper 160 bits, `low` in lower 96 bits (e.g. expiry + allowance patterns).
    function packAddressUint96(address a, uint96 low) internal pure returns (bytes32 word) {
        return bytes32((uint256(uint160(a)) << 96) | uint256(low));
    }

    function unpackAddressUint96(bytes32 word) internal pure returns (address a, uint96 low) {
        uint256 w = uint256(word);
        low = uint96(w);
        a = address(uint160(w >> 96));
    }

    function packUint64Quad(uint64 a, uint64 b, uint64 c, uint64 d) internal pure returns (bytes32 word) {
        return bytes32(
            (uint256(a) << 192) | (uint256(b) << 128) | (uint256(c) << 64) | uint256(d)
        );
    }

    function unpackUint64Quad(bytes32 word) internal pure returns (uint64 a, uint64 b, uint64 c, uint64 d) {
        uint256 w = uint256(word);
        a = uint64(w >> 192);
        b = uint64(w >> 128);
        c = uint64(w >> 64);
        d = uint64(w);
    }

    function wordToUint256(bytes32 w) internal pure returns (uint256) {
        return uint256(w);
    }

    function uint256ToWord(uint256 v) internal pure returns (bytes32) {
        return bytes32(v);
    }
}
