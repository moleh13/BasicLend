// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract Core {

    address public WETH;
    address public DAI;

    mapping (address => uint) lendedAmount;
    mapping (address => uint) borrowedAmount;
    mapping (address => mapping (address => uint)) borrowedhAmountByUsers;
    mapping (address => mapping (address => uint)) hAmountsByUsers;
    mapping (address => uint) exchangeRates;
    mapping (address => uint) utilizations;
    mapping (address => uint) borrowMultiplier;

    uint public lastUpdatedExchangeRate;
    uint public lastUpdatedBorrowMultiplier;

    event Log(address addr, uint amount);

    address public owner;

    constructor(address _WETH, address _DAI) {
        WETH = _WETH;
        DAI = _DAI;
        owner = msg.sender;
        borrowMultiplier[WETH] = 1;
        borrowMultiplier[DAI] = 1;
        exchangeRates[WETH] = 1e18;
        exchangeRates[DAI] = 1e18;
        lastUpdatedExchangeRate = block.timestamp;
        lastUpdatedBorrowMultiplier = block.timestamp;
        lendedAmount[WETH] = 3;
        borrowedAmount[WETH] = 1;
    }

    function lend(address _market, uint _amount) external {
        updateExchangeRate(_market);
        lendedAmount[_market] += _amount;
        IERC20(_market).approve(address(this), _amount);
        IERC20(_market).transferFrom(msg.sender, address(this), _amount);
        hAmountsByUsers[msg.sender][_market] += (_amount * 1e36) / exchangeRates[_market] ;
        updateUtilization(_market);
    }

    function redeem(address _market, uint _amount) external {
        updateExchangeRate(_market);
        require(hAmountsByUsers[msg.sender][_market] * exchangeRates[_market] >= _amount);
        hAmountsByUsers[msg.sender][_market] -= _amount / exchangeRates[_market];
        IERC20(_market).transfer(msg.sender, _amount);
        lendedAmount[_market] -= _amount;
        updateUtilization(_market);
    }

    function borrow(address _market, uint _amount) external {
        updateBorrowMultiplier(_market);
        borrowedhAmountByUsers[msg.sender][_market] += _amount / borrowMultiplier[_market];
        IERC20(_market).transfer(msg.sender, _amount);
        updateUtilization(_market);
    }

    function updateExchangeRate(address _market) internal {
        exchangeRates[_market] = exchangeRates[_market] + (block.timestamp - lastUpdatedExchangeRate) * (utilizations[_market]) /
        (365 * 24 * 60 * 60) * exchangeRates[_market] / 1e18;
        updateUtilization(_market);
        lastUpdatedExchangeRate = block.timestamp;
    }

    function updateUtilization(address _market) public {
        utilizations[_market] = (borrowedAmount[_market] * 1e18) / lendedAmount[_market];
    }

    function updateBorrowMultiplier(address _market) public {
        borrowMultiplier[_market] = borrowMultiplier[_market] + (block.timestamp - lastUpdatedBorrowMultiplier) * (utilizations[_market]) /
        (365 * 24 * 60 * 60) * borrowMultiplier[_market] / 1e18;
        updateUtilization(_market);
        lastUpdatedBorrowMultiplier = block.timestamp;
    }

    function getLendedAmount(address _market) public returns (uint) {
        updateExchangeRate(_market);

        emit Log(msg.sender, hAmountsByUsers[msg.sender][_market] * exchangeRates[_market]);

        return hAmountsByUsers[msg.sender][_market] * exchangeRates[_market];
    }

    function getBorrowedAmount(address _market) public returns (uint) {
        updateBorrowMultiplier(_market);
        
        emit Log(msg.sender, borrowedhAmountByUsers[msg.sender][_market] * borrowMultiplier[_market]);

        return borrowedhAmountByUsers[msg.sender][_market] * borrowMultiplier[_market];
    }

    function getUtilization(address _market) public returns (uint) {
        updateUtilization(_market);

        emit Log(_market, utilizations[_market]);

        return utilizations[_market];
    }

    function getExchangeRate(address _market) public returns (uint) {
        updateExchangeRate(_market);

        emit Log(_market, exchangeRates[_market]);

        return exchangeRates[_market];
    }
}

// 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8, 0xd9145CCE52D386f254917e481eB44e9943F39138