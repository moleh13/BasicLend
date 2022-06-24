// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract Core {
    uint public lastUpdated;
    
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    mapping(address => uint) lendedAmounts;
    mapping(address => uint) borrowedAmounts;
    mapping(address => uint) lAmounts;
    mapping(address => mapping(address => uint)) userLAmounts; 
    mapping(address => mapping(address => uint)) userLendedAmount;
    mapping(address => mapping(address => uint)) userBorrowedAmount;
    mapping(address => uint) exchangeRate;
    mapping(address => uint) secondlyInterestRate;
    mapping(address => uint) utilization;

    constructor() {
        lendedAmounts[WETH] = 0;
        lendedAmounts[DAI] = 0;
        borrowedAmounts[WETH] = 0;
        borrowedAmounts[DAI] = 0;
        exchangeRate[WETH] = 1;
        exchangeRate[DAI] = 1;
        lastUpdated = block.timestamp;
    }

    function lend(address _market, uint _amount) external updateUtilization(_market) {
        lendedAmounts[_market] += _amount;
        userLendedAmount[msg.sender][_market] += _amount;
        lAmounts[_market] += _amount / exchangeRate[_market];
        userLAmounts[msg.sender][_market] += _amount / exchangeRate[_market];
        IERC20(_market).approve(address(this), _amount);
        IERC20(_market).transferFrom(msg.sender, address(this), _amount);
    }

    function borrow(address _market, uint _amount) external updateUtilization(_market) {
        borrowedAmounts[_market] += _amount;
        userBorrowedAmount[msg.sender][_market] += _amount;
        IERC20(_market).transfer(msg.sender, _amount);
    }

    function redeem(address _market, uint _amount) external {
        require(userLendedAmount[msg.sender][_market] >= _amount);
        userLendedAmount[msg.sender][_market] -= _amount;
        lendedAmounts[_market] -= _amount;
        IERC20(_market).transfer(msg.sender, _amount * exchangeRate[_market]);
    }

    modifier updateUtilization(address _market) {
        utilization[_market] = borrowedAmounts[_market] / lendedAmounts[_market];
        _;
    }

    modifier updateExchangeRate(address _market) {
        exchangeRate[_market] + (block.timestamp - lastUpdated) * calculateSecondlyInterest(_market) / lendedAmounts[_market];
        lastUpdated = block.timestamp;
        _;
    }

    function calculateSecondlyInterest(address _market) public updateUtilization(_market) returns (uint) {
        secondlyInterestRate[_market] = utilization[_market] / (365 * 24 * 60 * 60);
        return secondlyInterestRate[_market];
    }

}