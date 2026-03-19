// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StealthAddressRegistry
 * @notice Stores stealth meta-address keys and emits stealth payment announcements.
 * @dev Designed for off-chain stealth address schemes (similar in spirit to EIP-5564).
 */
contract StealthAddressRegistry {
    struct StealthMetaAddress {
        bytes spendingPubKey; // compressed/uncompressed pubkey bytes
        bytes viewingPubKey;  // compressed/uncompressed pubkey bytes
        bool exists;
    }

    // recipient => stealth metadata
    mapping(address => StealthMetaAddress) private _metaAddresses;

    event StealthMetaAddressSet(
        address indexed registrant,
        bytes spendingPubKey,
        bytes viewingPubKey
    );

    event StealthAnnouncement(
        uint256 indexed schemeId,
        address indexed stealthAddress,
        address indexed announcer,
        bytes ephemeralPubKey,
        bytes metadata
    );

    /**
     * @notice Set or update sender's stealth meta-address keys.
     */
    function setStealthMetaAddress(
        bytes calldata spendingPubKey,
        bytes calldata viewingPubKey
    ) external {
        require(spendingPubKey.length > 0, "StealthRegistry: empty spending key");
        require(viewingPubKey.length > 0, "StealthRegistry: empty viewing key");

        _metaAddresses[msg.sender] = StealthMetaAddress({
            spendingPubKey: spendingPubKey,
            viewingPubKey: viewingPubKey,
            exists: true
        });

        emit StealthMetaAddressSet(msg.sender, spendingPubKey, viewingPubKey);
    }

    /**
     * @notice Clear sender's stealth meta-address data.
     */
    function clearStealthMetaAddress() external {
        delete _metaAddresses[msg.sender];
    }

    /**
     * @notice Read stealth meta-address info for a registrant.
     */
    function getStealthMetaAddress(address registrant)
        external
        view
        returns (bytes memory spendingPubKey, bytes memory viewingPubKey, bool exists)
    {
        StealthMetaAddress storage m = _metaAddresses[registrant];
        return (m.spendingPubKey, m.viewingPubKey, m.exists);
    }

    /**
     * @notice Emit stealth transfer announcement.
     * @dev Call this after computing a stealth address off-chain.
     * @param schemeId Stealth scheme identifier (application-defined).
     * @param stealthAddress Receiver stealth address.
     * @param ephemeralPubKey Sender's ephemeral pubkey bytes.
     * @param metadata Additional encrypted or plain metadata.
     */
    function announce(
        uint256 schemeId,
        address stealthAddress,
        bytes calldata ephemeralPubKey,
        bytes calldata metadata
    ) external {
        require(stealthAddress != address(0), "StealthRegistry: invalid stealth address");
        require(ephemeralPubKey.length > 0, "StealthRegistry: empty ephemeral pubkey");

        emit StealthAnnouncement(
            schemeId,
            stealthAddress,
            msg.sender,
            ephemeralPubKey,
            metadata
        );
    }
}
