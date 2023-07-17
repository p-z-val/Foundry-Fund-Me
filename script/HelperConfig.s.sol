//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol"; // to have access to vm.startBroadcast()
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //on local anvil we deploy mock contracts
    struct NetworkConfig {
        address priceFeed;
    }
    NetworkConfig public activeNetworkConfig;
uint8 public constant DECIMALS = 8;           // Magic Number
int256 public constant INITIAL_PRICE = 2000e8; // Magic Number
    constructor() {
        if (block.chainid == 11155111) {
            //if we are on the Sepolia Chain use the Sepolia Config
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //1. Deploy the mocks on Anvil
        //2. Return the mock addresses
        if(activeNetworkConfig.priceFeed != address(0)) { //If we call the function then without this we will create a new pricefeed so without this we would be creating a priceFeed everytime we call this function
            return activeNetworkConfig;// if we already have deployed a price then we don't need to Deploy it again
        }
        vm.startBroadcast(); //this way we can deploy the mocks on Anvil chain
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // do this to prevent going and looking in other contracts about what these values in the argument mean
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
//deploying on Anvil is faster because we didnt have to wait for APi calls to Alchemy
