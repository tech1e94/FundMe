//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct Networkconfig {
        address priceFeedAddress;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000

    Networkconfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (Networkconfig memory) {
        // Sepolia Testnet Chainlink ETH/USD Price Feed
        return Networkconfig({priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getMainnetEthConfig() public pure returns (Networkconfig memory) {
        // Mainnet Chainlink ETH/USD Price Feed
        return Networkconfig({priceFeedAddress: 0x5147eA642CAEF7BD9c1265AadcA78f997AbB9649});
    }

    function getOrCreateAnvilEthConfig() public returns (Networkconfig memory) {
        if (activeNetworkConfig.priceFeedAddress != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        // Anvil Testnet Chainlink ETH/USD Price Feed
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        Networkconfig memory anvilConfig = Networkconfig({priceFeedAddress: address(mockV3Aggregator)});
        return anvilConfig;
    }
}
