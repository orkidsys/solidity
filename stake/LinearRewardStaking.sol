//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Same total reward as LockedStaking, but rewards vest linearly over the lock; principal unlocks at maturity.
contract LinearRewardStaking is ReentrancyGuard {
    IERC20 public immutable token;

    uint256 public constant APY_BPS = 1500;
    uint256 public constant BPS_DENOM = 10_000;
    uint256 public constant YEAR = 365 days;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        uint256 rewardClaimed;
        bool principalTaken;
    }

    mapping(address => Stake[]) public stakes;

    event Staked(address indexed user, uint256 indexed index, uint256 amount, uint256 lockPeriod);
    event RewardClaimed(address indexed user, uint256 indexed index, uint256 amount);
    event PrincipalWithdrawn(address indexed user, uint256 indexed index, uint256 amount);

    error InvalidAmount();
    error InvalidLock();
    error NothingToClaim();
    error PrincipalLocked();
    error AlreadyWithdrawn();

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _totalReward(uint256 amount, uint256 lockPeriod) internal pure returns (uint256) {
        return (amount * APY_BPS * lockPeriod) / (BPS_DENOM * YEAR);
    }

    function _vestedReward(Stake storage s) internal view returns (uint256) {
        uint256 total = _totalReward(s.amount, s.lockPeriod);
        if (total == 0) return 0;
        uint256 endTime = s.startTime + s.lockPeriod;
        uint256 t = block.timestamp >= endTime ? endTime : block.timestamp;
        if (t <= s.startTime) return 0;
        return (total * (t - s.startTime)) / s.lockPeriod;
    }

    function stake(uint256 amount, uint256 lockPeriod) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (lockPeriod == 0) revert InvalidLock();

        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: block.timestamp,
                lockPeriod: lockPeriod,
                rewardClaimed: 0,
                principalTaken: false
            })
        );
        emit Staked(msg.sender, stakes[msg.sender].length - 1, amount, lockPeriod);
    }

    function claimRewards(uint256 index) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        uint256 vested = _vestedReward(s);
        uint256 due = vested - s.rewardClaimed;
        if (due == 0) revert NothingToClaim();
        s.rewardClaimed += due;
        token.transfer(msg.sender, due);
        emit RewardClaimed(msg.sender, index, due);
    }

    function withdrawPrincipal(uint256 index) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        if (s.principalTaken) revert AlreadyWithdrawn();
        if (block.timestamp < s.startTime + s.lockPeriod) revert PrincipalLocked();

        s.principalTaken = true;
        token.transfer(msg.sender, s.amount);
        emit PrincipalWithdrawn(msg.sender, index, s.amount);
    }

    /// @notice After maturity: pull any unpaid reward and principal in one transfer.
    function complete(uint256 index) external nonReentrant {
        Stake storage s = stakes[msg.sender][index];
        if (block.timestamp < s.startTime + s.lockPeriod) revert PrincipalLocked();

        uint256 vested = _vestedReward(s);
        uint256 rewardDue = vested - s.rewardClaimed;

        uint256 send;
        if (rewardDue > 0) {
            s.rewardClaimed += rewardDue;
            send += rewardDue;
            emit RewardClaimed(msg.sender, index, rewardDue);
        }
        if (!s.principalTaken) {
            s.principalTaken = true;
            send += s.amount;
            emit PrincipalWithdrawn(msg.sender, index, s.amount);
        }
        if (send == 0) revert NothingToClaim();

        token.transfer(msg.sender, send);
    }
}
