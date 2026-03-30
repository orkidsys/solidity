// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPriceOracle.sol";

/// @title OperatorPriceOracle
/// @notice Push-model oracle compatible with `IPriceOracle` (e.g. internal keeper or testnet).
contract OperatorPriceOracle is IPriceOracle {
    address public operator;
    int256 private _answer;

    event OperatorTransferred(address indexed previous, address indexed next);
    event AnswerUpdated(int256 answer);

    constructor(address _operator) {
        require(_operator != address(0), "zero op");
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "only operator");
        _;
    }

    function transferOperator(address next) external onlyOperator {
        require(next != address(0), "zero");
        emit OperatorTransferred(operator, next);
        operator = next;
    }

    function setAnswer(int256 newAnswer) external onlyOperator {
        require(newAnswer > 0, "bad answer");
        _answer = newAnswer;
        emit AnswerUpdated(newAnswer);
    }

    function latestAnswer() external view override returns (int256) {
        require(_answer > 0, "unset");
        return _answer;
    }
}
