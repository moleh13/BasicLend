// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract Core {

    /* ======================== VARIABLES ======================== */

    address owner;
    address public WETH;
    address public DAI;
    uint public lastUpdatedExchangeRate;
    uint public lastUpdatedBorrowMultiplier;
    address[] public markets;

    /* ======================== MAPPING ======================== */

    mapping (address => uint) public lendedAmount;
    mapping (address => uint) public lendedhAmount;
    mapping (address => uint) public borrowedAmount;
    mapping (address => uint) public borrowedhAmount;
    mapping (address => uint) public exchangeRates;
    mapping (address => uint) public utilizations;
    mapping (address => uint) public borrowMultiplier;
    mapping (address => uint) public collateralRatioOfMarket;
    mapping (address => uint) public collateralAmountOfUser;
    mapping (address => uint) public priceOf; // for test. pricefeed will be used
    mapping (address => mapping (address => uint)) public borrowedhAmountByUsers;
    mapping (address => mapping (address => uint)) public hAmountsByUsers;

    /* ======================== EVENTS ======================== */

    event Log(address addr, uint amount);

    /* ======================== CONSTRUCTOR ======================== */

    constructor(address _WETH, address _DAI) {
        WETH = _WETH;
        DAI = _DAI;
        exchangeRates[WETH] = 1e18;
        exchangeRates[DAI] = 1e18;
        lendedAmount[WETH] = 1;
        lendedhAmount[WETH] = 1;
        borrowedAmount[WETH] = 1;
        lendedAmount[DAI] = 1;
        lendedhAmount[DAI] = 1;
        borrowedAmount[DAI] = 1;
        lastUpdatedExchangeRate = block.timestamp;
        lastUpdatedBorrowMultiplier = block.timestamp;
        collateralRatioOfMarket[WETH] = 60 * 1e18;
        collateralRatioOfMarket[DAI] = 60 * 1e18;
        owner = msg.sender;
        markets = [WETH, DAI];
        priceOf[WETH] = 1000 * 1e18;
        priceOf[DAI] = 1 * 1e18;
    }
    
    /* ======================== LENDING ======================== */

    function lend(address _market, uint _amount) external {
        updateExchangeRate(_market);

        hAmountsByUsers[msg.sender][_market] += (_amount * 1e36) / (exchangeRates[_market]);
        lendedAmount[_market] += _amount * 1e18;
        lendedhAmount[_market] += (_amount * 1e36) / exchangeRates[_market];
        collateralAmountOfUser[msg.sender] += _amount * collateralRatioOfMarket[_market] * priceOf[_market]; 

        IERC20(_market).transferFrom(msg.sender, address(this), _amount * 1e18);

        updateUtilization(_market);

        emit Log(msg.sender, hAmountsByUsers[msg.sender][_market] * exchangeRates[_market] / 1e18);
    }

    /* ======================== REDEEMING ======================== */

    function redeem(address _market, uint _amount) external {
        updateExchangeRate(_market);
        
        require(calculateLendedAmountByUser(msg.sender, _market) >= _amount * 1e18);

        hAmountsByUsers[msg.sender][_market] -= (_amount * 1e36) / exchangeRates[_market];
        lendedAmount[_market] -= _amount * 1e18;
        lendedhAmount[_market] -= (_amount * 1e36) / exchangeRates[_market];

        IERC20(_market).transfer(msg.sender, _amount * 1e18);

        updateUtilization(_market);
    }

    /* ======================== BORROWING ======================== */

    function borrow(address _market, uint _amount) public {
        updateExchangeRate(_market);

        require(_amount * 1e18 <= (lendedhAmount[_market] * exchangeRates[_market]) / 1e18);

        borrowedhAmountByUsers[msg.sender][_market] += (_amount * 1e36) / exchangeRates[_market];
        borrowedAmount[_market] += _amount * 1e18;
        borrowedhAmount[_market] += (_amount * 1e36) / exchangeRates[_market];

        IERC20(_market).transfer(msg.sender, _amount * 1e18);

        updateUtilization(_market);
    }

    /* ======================== VIEW ======================== */
    
    function calculateLendedAmountByUser(address _user, address _market) public view returns (uint) {
        return hAmountsByUsers[_user][_market] * exchangeRates[_market] / 1e18;
    }

    function _collateralAmountOfUser() public view returns (uint) {
        return collateralAmountOfUser[msg.sender];
    }

    /* ======================== UPDATE PARTS ======================== */

    function updateExchangeRate(address _market) public {
        exchangeRates[_market] += (block.timestamp - lastUpdatedExchangeRate) * 
        (utilizations[_market]) / (365 * 24 * 60 * 60) * exchangeRates[_market] / 1e18;
        
        updateUtilization(_market);

        lendedAmount[_market] = (lendedhAmount[_market] * exchangeRates[_market]) / 1e18;
        borrowedAmount[_market] = (borrowedhAmount[_market] * exchangeRates[_market]) / 1e18;
        lastUpdatedExchangeRate = block.timestamp;

        emit Log(_market, exchangeRates[_market]);
    }

    function updateUtilization(address _market) public {
        utilizations[_market] = (borrowedAmount[_market] * 1e18) / lendedAmount[_market];

        emit Log(_market, utilizations[_market]);
    }

    function updateCollateralAmountOfUser(address _user) public {
        collateralAmountOfUser[_user] = 0;

        for (uint i = 0; i < markets.length; i++) {
            updateExchangeRate(markets[i]);
            collateralAmountOfUser[_user] += 
            (hAmountsByUsers[msg.sender][markets[i]] * exchangeRates[markets[i]] * priceOf[markets[i]]
            * collateralRatioOfMarket[markets[i]]) / 1e56;
        }
    }

    /* ======================== OWNER ======================== */

    function setCollateralRatio(address _market, uint _ratio) external {
        require(msg.sender == owner);

        collateralRatioOfMarket[_market] = _ratio * 1e18;
    }

    function addMarket(address _market) external {
        require(msg.sender == owner);

        markets.push(_market);
    }

}

// 0xf8e81D47203A594245E36C48e151709F0C19fBe8, 0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B