// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract Core {

    /* ---------------------------- VARIABLES ---------------------------- */

    address public WETH;
    address public DAI;
    uint public lastUpdatedExchangeRate;
    uint public lastUpdatedBorrowMultiplier;
    uint public year = 365 * 24 * 60 * 60;
    uint public passedTime = block.timestamp - lastUpdatedExchangeRate;

    /* ---------------------------- MAPPING ---------------------------- */

    mapping (address => uint) public lendedAmount;
    mapping (address => uint) public borrowedAmount;
    mapping (address => uint) public exchangeRates;
    mapping (address => uint) public utilizations;
    mapping (address => uint) public borrowMultiplier;
    mapping (address => mapping (address => uint)) public borrowedhAmountByUsers;
    mapping (address => mapping (address => uint)) public hAmountsByUsers;

    /* ---------------------------- EVENTS ---------------------------- */

    event Log(address addr, uint amount);

    /* ---------------------------- CONSTRUCTOR ---------------------------- */

    constructor(address _WETH, address _DAI) {
        WETH = _WETH;
        DAI = _DAI;
        exchangeRates[WETH] = 1e18;
        exchangeRates[DAI] = 1e18;
        lendedAmount[WETH] = 1;
        borrowedAmount[WETH] = 1e18;
        lastUpdatedExchangeRate = block.timestamp;
        lastUpdatedBorrowMultiplier = block.timestamp;
    }
    
    /* ---------------------------- LENDING ---------------------------- */

    function lend(address _market, uint _amount) external {
        updateExchangeRate(_market);

        lendedAmount[_market] += _amount * 1e18;

        IERC20(_market).transferFrom(msg.sender, address(this), _amount * 1e18);

        hAmountsByUsers[msg.sender][_market] += (_amount * 1e36) / (exchangeRates[_market]);

        updateUtilization(_market);

        emit Log(msg.sender, hAmountsByUsers[msg.sender][_market] * exchangeRates[_market] / 1e18);
    }

    /* ---------------------------- UPDATE PARTS ---------------------------- */

    function updateExchangeRate(address _market) public {
        exchangeRates[_market] += (passedTime) * (utilizations[_market]) / (year) * exchangeRates[_market] / 1e18;
        
        updateUtilization(_market);

        lastUpdatedExchangeRate = block.timestamp;

        emit Log(_market, exchangeRates[_market]);
    }

    function updateUtilization(address _market) public {
        utilizations[_market] = (borrowedAmount[_market] * 1e18) / lendedAmount[_market];

        emit Log(_market, utilizations[_market]);
    }

}

// 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8, 0xd9145CCE52D386f254917e481eB44e9943F39138