// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionByConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_Coordinator = helperConfig.getChain()._vrfCoordinator;
        (uint256 subId,) = createSubscription(vrf_Coordinator);
        return (subId, vrf_Coordinator);
    }

    function createSubscription(address vrf_Coordinator) public returns (uint256, address) {
        console.log("here is the subscription Id", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrf_Coordinator).createSubscription();
        vm.stopBroadcast();

        console.log("here is the subId", subId);

        return (subId, vrf_Coordinator);
    }

    function run() public {
        createSubscriptionByConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function createFundSubscriptionByConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrf_Coordinator = helperConfig.getChain()._vrfCoordinator;
        uint256 subId = helperConfig.getChain().subscriptionId;
        address linkToken = helperConfig.getChain().link;
        fundSubscription(vrf_Coordinator, subId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        if (block.chainid == ANVIL_LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        createFundSubscriptionByConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerByUsingConfig(address recentDeployment) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getChain().subscriptionId;
        address vrf_Coordinator = helperConfig.getChain()._vrfCoordinator;
        addConsumer(recentDeployment, vrf_Coordinator, subId);
    }

    function addConsumer(address contractToAddToVRF, address vrfCoordinator, uint256 subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVRF);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecetDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerByUsingConfig(mostRecetDeployed);
    }
}
