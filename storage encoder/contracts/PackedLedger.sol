// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StorageEncoderLib.sol";

/// @title PackedLedger
/// @notice Example ledger: one storage slot per user with two uint128 balances (credit & debit caps).
contract PackedLedger {
    mapping(address => bytes32) private packedBalances;

    event BalancesUpdated(address indexed user, uint128 credit, uint128 debit);

    function setBalances(address user, uint128 credit, uint128 debit) external {
        packedBalances[user] = StorageEncoderLib.packTwoUint128(credit, debit);
        emit BalancesUpdated(user, credit, debit);
    }

    function getBalances(address user) external view returns (uint128 credit, uint128 debit) {
        return StorageEncoderLib.unpackTwoUint128(packedBalances[user]);
    }

    /// @notice On-chain read of the raw word (matches `eth_getStorageAt` for this mapping slot derivation).
    function rawWord(address user) external view returns (bytes32) {
        return packedBalances[user];
    }
}
