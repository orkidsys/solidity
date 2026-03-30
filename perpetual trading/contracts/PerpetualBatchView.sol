// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PerpetualMarket.sol";

/// @title PerpetualBatchView
/// @notice Aggregates `getPosition` reads for many accounts in one `eth_call`.
contract PerpetualBatchView {
    struct PositionView {
        bool open;
        bool isLong;
        uint256 sizeUsdWad;
        uint256 entryPrice1e8;
        uint256 margin;
        int256 unrealizedPnl;
        int256 fundingPending;
        int256 equity;
    }

    function getPositions(PerpetualMarket market, address[] calldata users)
        external
        view
        returns (PositionView[] memory out)
    {
        uint256 n = users.length;
        out = new PositionView[](n);
        for (uint256 i; i < n; ++i) {
            (
                bool o,
                bool il,
                uint256 s,
                uint256 e,
                uint256 m,
                int256 u,
                int256 f,
                int256 eq
            ) = market.getPosition(users[i]);
            out[i] = PositionView(o, il, s, e, m, u, f, eq);
        }
    }
}
