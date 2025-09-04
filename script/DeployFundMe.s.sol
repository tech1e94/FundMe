// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    HelperConfig helperConfig = new HelperConfig();
    address priceFeedAddress = helperConfig.activeNetworkConfig();

    function run() external returns (FundMe) {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeedAddress);
        vm.stopBroadcast();
        return fundMe;
    }
}
