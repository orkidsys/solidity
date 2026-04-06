//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Same mechanics as LockedStaking, but on claim the reward is sent to `rewardTo` (set per stake); principal returns to the staker.
contract DelegatedRewardStaking is ReentrancyGuard {
    IERC20 public immutable token;

    uint256 public constant APY_BPS = 1500;
    uint256 public constant BPS_DENOM = 10_000;
    uint256 public constant YEAR = 365 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        address rewardTo;
        bool claimed;
    }

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 indexed index, uint256 amount, uint256 lockPeriod, address rewardTo);
    event Claimed(address indexed user, uint256 indexed index, address indexed rewardTo, uint256 reward, uint256 principal);

    error InvalidAmount();
    error InvalidLock();
    error ZeroRewardRecipient();
    error AlreadyClaimed();
    error StillLocked();

    constructor(address _token) {
        token = IERC20(_token);
    }

    function stake(uint256 amount, uint256 lockPeriod, address rewardTo) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (lockPeriod == 0) revert InvalidLock();
        if (rewardTo == address(0)) revert ZeroRewardRecipient();

        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: block.timestamp,
                lockPeriod: lockPeriod,
                rewardTo: rewardTo,
                claimed: false
            })
        );
        emit Staked(msg.sender, stakes[msg.sender].length - 1, amount, lockPeriod, rewardTo);
    }

    function claim(uint256 index) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        if (s.claimed) revert AlreadyClaimed();
        if (block.timestamp < s.startTime + s.lockPeriod) revert StillLocked();

        uint256 reward = (s.amount * APY_BPS * s.lockPeriod) / (BPS_DENOM * YEAR);
        s.claimed = true;

        token.transfer(msg.sender, s.amount);
        if (reward > 0) {
            token.transfer(s.rewardTo, reward);
        }
        emit Claimed(msg.sender, index, s.rewardTo, reward, s.amount);
    }
}
