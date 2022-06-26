// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./ERC20.sol";

contract DAI is ERC20("DAI", "DAI") {

    constructor() {
        _mint(msg.sender, 10000 * 1e18);
    }    
}