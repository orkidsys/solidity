// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PerpetualMarket.sol";

/// @title FundingKeeper
/// @notice Optional cooldown-gated wrapper so bots can advance funding without hitting other market paths.
contract FundingKeeper {
    PerpetualMarket public immutable market;
    uint256 public minInterval;
    uint256 public lastPoke;

    event Poked(address indexed caller, uint256 timestamp);
    event MinIntervalUpdated(uint256 previous, uint256 next);

    address public owner;

    constructor(PerpetualMarket _market, uint256 _minInterval) {
        market = _market;
        minInterval = _minInterval;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setMinInterval(uint256 next) external onlyOwner {
        emit MinIntervalUpdated(minInterval, next);
        minInterval = next;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function poke() external {
        if (minInterval != 0) {
            require(block.timestamp >= lastPoke + minInterval, "cooldown");
        }
        lastPoke = block.timestamp;
        market.accrueFunding();
        emit Poked(msg.sender, block.timestamp);
    }
}
