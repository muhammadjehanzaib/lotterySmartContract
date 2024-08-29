// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deploySmartContract();
    }

    function deploySmartContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfigurations = helperConfig.getChain();

        if (networkConfigurations.subscriptionId == 0) {
            // Create Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (networkConfigurations.subscriptionId, networkConfigurations._vrfCoordinator) =
                createSubscription.createSubscription(networkConfigurations._vrfCoordinator);

            //fund it
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfigurations._vrfCoordinator, networkConfigurations.subscriptionId, networkConfigurations.link
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfigurations.entraneceFee,
            networkConfigurations.interval,
            networkConfigurations._vrfCoordinator,
            networkConfigurations.gasLane,
            networkConfigurations.subscriptionId,
            networkConfigurations.callBackGasLimit
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle), networkConfigurations._vrfCoordinator, networkConfigurations.subscriptionId
        );
        return (raffle, helperConfig);
    }
}
