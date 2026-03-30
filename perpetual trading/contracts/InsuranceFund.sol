// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IERC20.sol";

/// @title InsuranceFund
/// @notice Holds collateral from perpetual liquidations; governance withdraws to cover bad debt or reallocate.
contract InsuranceFund {
    IERC20 public immutable asset;
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address _asset) {
        require(_asset != address(0), "zero asset");
        asset = IERC20(_asset);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }

    /// @notice Move tokens out (e.g. to cover underwater positions on another venue).
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(asset.transfer(to, amount), "transfer");
        emit Withdrawn(to, amount);
    }

    function balance() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }
}
