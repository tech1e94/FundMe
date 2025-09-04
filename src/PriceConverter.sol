// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // every function in library must be "internal"
        (, int256 price, , , ) = priceFeed.latestRoundData(); // price of ETH in terms of USD
        return uint256(price * 1e10); // msg.value has 18 0s so we need to make price of same
    }

    function ETHConverter(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 usdAmount = (ethPrice * ethAmount) / 1e18; // diveide by 1e18 cuz both have 18 decimal zeros
        // so when multiply 18 + 18 = 36 zeros then divided by 18 results in 18 zeros in answer
        return usdAmount;
    }
}
