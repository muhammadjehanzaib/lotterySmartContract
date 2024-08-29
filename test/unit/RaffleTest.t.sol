// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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

    function testcheckRaffleWinnerOnlyRunsIfCheckUpKeepIsTrue() public {
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();
        // vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act / Assert
        vm.expectRevert();
        raffle.raffleWinner();
    }

    function testRaffleWinnerRevertsIfCheckUpKeepsIsFalse() public {
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepNoted.selector,
                0.1 ether,
                1,
                raffle.getRaffleCurrentState()
            )
        );
        raffle.raffleWinner();
    }

    function testFullfillrandomOnlyBeCalledAfterPerformUpKeep(
        uint256 _requestId
    ) public RaffleEnteredAndTimePassed {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(
            _requestId,
            address(raffle)
        );
    }

    modifier RaffleEnteredAndTimePassed() {
        vm.prank(player);
        raffle.enterRaffle{value: 0.1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testRaffleStateEmitTest() public RaffleEnteredAndTimePassed {
        vm.recordLogs();
        raffle.raffleWinner();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // console2.logBytes32(entries[1].topics[1]);
        bytes32 requestId = entries[0].topics[0];

        Raffle.RaffleState raffleState = raffle.getRaffleCurrentState();
        assert(requestId > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFulfillRandomWordsPicksAWinnerRestesAndSendsMoney()
        public
        RaffleEnteredAndTimePassed
    {
        // Arrange

        uint256 additionalEntrants = 4;
        uint256 startingIndex = 1;

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address playerAddress = address(uint160(i));
            hoax(playerAddress, 1 ether);
            raffle.enterRaffle{value: 0.1 ether}();
        }

        uint256 prize = 0.1 ether * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.raffleWinner(); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Log the requestId
        // console2.log(requestId);

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        // pretend to be Chainlink VRF
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        assert(uint256(raffle.getRaffleCurrentState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getRaffleNoOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
        assert(raffle.getRecentWinner().balance == 0.1 ether + prize);
    }
}
