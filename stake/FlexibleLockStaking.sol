//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Like LockedStaking but allows early exit: principal minus penalty goes to user, penalty to fee recipient. Maturity pays principal + linear APY reward.
contract FlexibleLockStaking is ReentrancyGuard {
    IERC20 public immutable token;
    address public feeRecipient;
    address public immutable owner;

    uint256 public constant APY_BPS = 1500;
    uint256 public constant BPS_DENOM = 10_000;
    uint256 public constant YEAR = 365 days;

    uint256 public earlyPenaltyBps;

    struct Position {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        bool exited;
    }

    mapping(address => Position[]) public positions;

    event Staked(address indexed user, uint256 indexed index, uint256 amount, uint256 lockPeriod);
    event ClaimedMature(address indexed user, uint256 indexed index, uint256 payout);
    event EarlyExit(address indexed user, uint256 indexed index, uint256 toUser, uint256 penalty);

    error OnlyOwner();
    error InvalidAmount();
    error InvalidLock();
    error InvalidPenalty();
    error AlreadyExited();
    error NotMature();
    error LockExpired();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(address _token, address _feeRecipient, uint256 _earlyPenaltyBps) {
        token = IERC20(_token);
        feeRecipient = _feeRecipient;
        earlyPenaltyBps = _earlyPenaltyBps;
        owner = msg.sender;
        if (_earlyPenaltyBps > BPS_DENOM) revert InvalidPenalty();
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        feeRecipient = recipient;
    }

    function setEarlyPenaltyBps(uint256 bps) external onlyOwner {
        if (bps > BPS_DENOM) revert InvalidPenalty();
        earlyPenaltyBps = bps;
    }

    function stake(uint256 amount, uint256 lockPeriod) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (lockPeriod == 0) revert InvalidLock();

        token.transferFrom(msg.sender, address(this), amount);

        positions[msg.sender].push(
            Position({amount: amount, startTime: block.timestamp, lockPeriod: lockPeriod, exited: false})
        );

        emit Staked(msg.sender, positions[msg.sender].length - 1, amount, lockPeriod);
    }

    function _reward(uint256 amount, uint256 lockPeriod) internal pure returns (uint256) {
        return (amount * APY_BPS * lockPeriod) / (BPS_DENOM * YEAR);
    }

    function claimMature(uint256 index) external nonReentrant {
        Position storage p = positions[msg.sender][index];
        if (p.exited) revert AlreadyExited();
        if (block.timestamp < p.startTime + p.lockPeriod) revert NotMature();

        uint256 payout = p.amount + _reward(p.amount, p.lockPeriod);
        p.exited = true;
        token.transfer(msg.sender, payout);

        emit ClaimedMature(msg.sender, index, payout);
    }

    function exitEarly(uint256 index) external nonReentrant {
        Position storage p = positions[msg.sender][index];
        if (p.exited) revert AlreadyExited();
        if (block.timestamp >= p.startTime + p.lockPeriod) revert LockExpired();

        uint256 penalty = (p.amount * earlyPenaltyBps) / BPS_DENOM;
        uint256 toUser = p.amount - penalty;
        p.exited = true;

        if (penalty > 0) {
            token.transfer(feeRecipient, penalty);
        }
        token.transfer(msg.sender, toUser);

        emit EarlyExit(msg.sender, index, toUser, penalty);
    }
}
