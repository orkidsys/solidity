// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StealthAddressGenerator
 * @notice Utility contract for deterministic stealth address derivation.
 * @dev This contract does not perform elliptic-curve Diffie-Hellman on-chain.
 * Instead, wallets/apps compute a shared secret off-chain, then pass it here.
 */
contract StealthAddressGenerator {
    event StealthAddressGenerated(
        address indexed caller,
        bytes32 indexed sharedSecretHash,
        bytes32 indexed salt,
        address stealthAddress
    );

    /**
     * @notice Derive a stealth address from off-chain shared secret material.
     * @param spendingPublicKey Public spending key bytes for the receiver.
     * @param sharedSecretHash Hash of off-chain ECDH shared secret.
     * @param salt Extra entropy/domain separator.
     * @return stealthAddress Deterministically derived stealth address.
     */
    function deriveStealthAddress(
        bytes calldata spendingPublicKey,
        bytes32 sharedSecretHash,
        bytes32 salt
    ) public pure returns (address stealthAddress) {
        require(spendingPublicKey.length > 0, "StealthGen: empty spending key");
        require(sharedSecretHash != bytes32(0), "StealthGen: empty secret hash");

        bytes32 digest = keccak256(
            abi.encodePacked("STEALTH_ADDRESS_V1", spendingPublicKey, sharedSecretHash, salt)
        );
        return address(uint160(uint256(digest)));
    }

    /**
     * @notice Derive and emit an event for easy indexer tracking.
     */
    function deriveAndEmit(
        bytes calldata spendingPublicKey,
        bytes32 sharedSecretHash,
        bytes32 salt
    ) external returns (address stealthAddress) {
        stealthAddress = deriveStealthAddress(spendingPublicKey, sharedSecretHash, salt);
        emit StealthAddressGenerated(msg.sender, sharedSecretHash, salt, stealthAddress);
    }

    /**
     * @notice Batch derive stealth addresses for many recipients.
     */
    function batchDerive(
        bytes[] calldata spendingPublicKeys,
        bytes32[] calldata sharedSecretHashes,
        bytes32[] calldata salts
    ) external pure returns (address[] memory stealthAddresses) {
        uint256 len = spendingPublicKeys.length;
        require(len == sharedSecretHashes.length, "StealthGen: length mismatch 1");
        require(len == salts.length, "StealthGen: length mismatch 2");

        stealthAddresses = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            stealthAddresses[i] = deriveStealthAddress(
                spendingPublicKeys[i],
                sharedSecretHashes[i],
                salts[i]
            );
        }
    }
}
