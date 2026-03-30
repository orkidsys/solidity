// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";
import "./CollateralVault.sol";
import "./PerpetualMarket.sol";

/// @title VaultDepositRouter
/// @notice Pull collateral from `msg.sender` and credit a beneficiary vault balance in one transaction.
contract VaultDepositRouter {
    /// @dev Requires prior `IERC20.approve(router, amount)` on the collateral token for this router.
    function depositFor(CollateralVault vault, address beneficiary, uint256 amount) external {
        IERC20 t = vault.collateralToken();
        require(t.transferFrom(msg.sender, address(this), amount), "transferFrom");
        require(t.approve(address(vault), amount), "approve");
        vault.depositFor(beneficiary, amount);
    }

    /// @notice Payer funds `trader` in the vault then opens a position as `trader`.
    /// @dev Set `PerpetualMarket.setRouter` to this contract first.
    function depositAndOpen(
        CollateralVault vault,
        PerpetualMarket market,
        address trader,
        uint256 depositAmount,
        bool isLong,
        uint128 sizeUsdWad,
        uint128 marginAmount
    ) external {
        require(address(market.vault()) == address(vault), "vault mismatch");
        require(market.router() == address(this), "market router");
        IERC20 t = vault.collateralToken();
        require(t.transferFrom(msg.sender, address(this), depositAmount), "transferFrom");
        require(t.approve(address(vault), depositAmount), "approve");
        vault.depositFor(trader, depositAmount);
        market.openPositionFor(trader, isLong, sizeUsdWad, marginAmount);
    }
}
