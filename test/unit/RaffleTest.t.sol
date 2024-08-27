// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entraneceFee;
    uint256 interval;
    address _vrfCoordinator;
    bytes32 gasLane;
    uint32 callBackGasLimit;
    uint256 subscriptionId;

    address public player = makeAddr("players");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deploySmartContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getChain();

        entraneceFee = config.entraneceFee;
        interval = config.interval;
        _vrfCoordinator = config._vrfCoordinator;
        gasLane = config.gasLane;
        callBackGasLimit = config.callBackGasLimit;
        subscriptionId = config.subscriptionId;
        vm.deal(player, STARTING_PLAYER_BALANCE);
    }

    function testIsInitialStateIOpen() public view {
        assert(raffle.getRaffleCurrentState() == Raffle.RaffleState.OPEN);
    }

    function testEnterancRaffle() public {
        // assertEq(raffle.enterRaffle(),Raffle.Raffle_SendMoreToEnterRaffle());
        vm.prank(player);

        vm.expectRevert(Raffle.Raffle_SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleGetsUpdataWhenPlayersEnter() public {
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();

        assertEq(raffle.getRaffleNoOfPlayers(), 1);
    }

    function testEvents() public {
        vm.prank(player);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(player);

        raffle.enterRaffle{value: 0.1 ether}();
    }

    function testDoNotAllowToEnterRaffleWhileRaffleCalculating() public {
        // Arrange
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.raffleWinner();
        // Act
        // Assert
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();
    }
}
