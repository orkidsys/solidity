// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";

/// @title ChainlinkOracleAdapter
/// @notice Adapts Chainlink Aggregator V3 `latestRoundData` to `IPriceOracle.latestAnswer` for PerpetualMarket.
contract ChainlinkOracleAdapter is IPriceOracle {
    AggregatorV3Interface public immutable aggregator;

    constructor(address _aggregator) {
        require(_aggregator != address(0), "zero feed");
        aggregator = AggregatorV3Interface(_aggregator);
    }

    function latestAnswer() external view override returns (int256) {
        (, int256 answer,, uint256 updatedAt,) = aggregator.latestRoundData();
        require(answer > 0, "bad answer");
        require(updatedAt > 0, "stale");
        return answer;
    }
}
