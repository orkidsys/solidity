//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"

contract LockedStaking{
    IERC20 public token;
    uint256 public constant APY = 15;
    uint256 public constant YEAR = 365 days;

    struct Stake{
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        bool claimed;
    }
    
    mapping(address=> Stake[]) public stakes;

    constructor(address _token){
        token = IERC20(_token);
    }

    function stake(uint256 amount, uint256 lockPeriod) external {
        require(amount > 0, "Invalid");

        token.transferFrom(msg.sender, address(this), amount);

        stakes[msg.sender].push(Stake({
            amount: amount,
            startTime: block.timestamp,
            lockPeriod: lockPeriod,
            claimed: false
        }));
    }

    function claim(uint256 index) external {
        Stake storage s = stakes[msg.sender][index];

        require(!s.claimed, "Already claimed");
        require(block.timestamp >= s.startTime + s.lockPeriod, "Locked");

        uint256 reward = (s.amount * APY * s.lockPeriod) / (100 * YEAR);

        s.claimed = true;

        token.transfer(msg.sender, s.amount +reward);
    }
}