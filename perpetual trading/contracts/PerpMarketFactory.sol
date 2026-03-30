// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CollateralVault.sol";
import "./PerpetualMarket.sol";

/// @title PerpMarketFactory
/// @notice Deploys a vault + market pair and wires `vault.setMarket` atomically in one transaction.
contract PerpMarketFactory {
    event MarketDeployed(
        address indexed vault,
        address indexed market,
        address collateral,
        address oracle,
        address insuranceFund
    );

    function deployMarket(
        address collateral,
        address oracle,
        uint256 fundingScaler,
        uint256 maintenanceBps,
        uint256 liqFeeBps,
        address insuranceFund
    ) external returns (CollateralVault vault, PerpetualMarket market) {
        vault = new CollateralVault(collateral);
        market = new PerpetualMarket(
            address(vault),
            oracle,
            fundingScaler,
            maintenanceBps,
            liqFeeBps,
            insuranceFund
        );
        vault.setMarket(address(market));
        emit MarketDeployed(address(vault), address(market), collateral, oracle, insuranceFund);
    }
}
