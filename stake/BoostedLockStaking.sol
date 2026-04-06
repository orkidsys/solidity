//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Lock staking where APY increases with lock length (capped). Reward = amount * effectiveApyBps * lockPeriod / (BPS_DENOM * YEAR).
contract BoostedLockStaking is ReentrancyGuard {
    IERC20 public immutable token;

    uint256 public constant BASE_APY_BPS = 1000;
    uint256 public constant EXTRA_APY_BPS_PER_YEAR = 500;
    uint256 public constant MAX_APY_BPS = 3000;
    uint256 public constant BPS_DENOM = 10_000;
    uint256 public constant YEAR = 365 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        bool claimed;
    }

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 indexed index, uint256 amount, uint256 lockPeriod, uint256 effectiveApyBps);

    error InvalidAmount();
    error InvalidLock();
    error AlreadyClaimed();
    error StillLocked();

    constructor(address _token) {
        token = IERC20(_token);
    }

    function effectiveApyBps(uint256 lockPeriod) public pure returns (uint256) {
        uint256 bonus = (lockPeriod * EXTRA_APY_BPS_PER_YEAR) / YEAR;
        uint256 apy = BASE_APY_BPS + bonus;
        return apy > MAX_APY_BPS ? MAX_APY_BPS : apy;
    }

    function rewardFor(uint256 amount, uint256 lockPeriod) public pure returns (uint256) {
        return (amount * effectiveApyBps(lockPeriod) * lockPeriod) / (BPS_DENOM * YEAR);
    }

    function stake(uint256 amount, uint256 lockPeriod) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (lockPeriod == 0) revert InvalidLock();

        uint256 apy = effectiveApyBps(lockPeriod);
        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].push(
            Stake({amount: amount, startTime: block.timestamp, lockPeriod: lockPeriod, claimed: false})
        );
        emit Staked(msg.sender, stakes[msg.sender].length - 1, amount, lockPeriod, apy);
    }

    function claim(uint256 index) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        if (s.claimed) revert AlreadyClaimed();
        if (block.timestamp < s.startTime + s.lockPeriod) revert StillLocked();

        uint256 r = rewardFor(s.amount, s.lockPeriod);
        s.claimed = true;
        token.transfer(msg.sender, s.amount + r);
    }
}
