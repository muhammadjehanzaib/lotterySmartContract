//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Raffle lottery Smart contract
 * @author Muhammad Jehanzaib
 * @notice This contract is for Testing Raffle Script
 * @dev
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle_SendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpKeepNoted(uint256 contractBalance, uint256 noOfPlayers, RaffleState raffleState);

    // Type Declaration
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //State variables
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMBER_WORDS = 1;
    uint256 private immutable i_ENTRANCE_FEE;
    //@dev The duration of the lottery in seconds
    uint256 private immutable i_INTERVAL;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_player;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private raffleState;
    // Events

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed recentWinner);
    event RequestedRaffleWinner(uint256 indexed requestID);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 gasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_ENTRANCE_FEE = entranceFee;
        i_INTERVAL = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = gasLimit;
        raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_ENTRANCE_FEE) {
            revert Raffle_SendMoreToEnterRaffle();
        }
        if (raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        s_player.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpKeep(bytes memory /*calldata*/ )
        public
        view
        returns (bool upKeepNoted, bytes memory /*Perform data*/ )
    {
        bool isOpen = raffleState == RaffleState.OPEN;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_INTERVAL);
        bool hasEthBalance = address(this).balance > 0;
        bool hasPlayer = s_player.length > 0;

        upKeepNoted = isOpen && timePassed && hasEthBalance && hasPlayer;
        return (upKeepNoted, hex"");
    }

    function raffleWinner() external payable {
        (bool upKeepNoted,) = checkUpKeep("");

        if (!upKeepNoted) {
            revert Raffle_UpKeepNoted(address(this).balance, s_player.length, raffleState);
        }

        raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory requestId = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATION,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUMBER_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 req = s_vrfCoordinator.requestRandomWords(requestId);
        emit RequestedRaffleWinner(req);
    }

    // Checks, Effects and Interactions

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_player.length;
        address recentPlayerWinner = s_player[indexOfWinner];
        s_recentWinner = recentPlayerWinner;
        raffleState = RaffleState.OPEN;
        s_player = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentPlayerWinner);

        (bool success,) = recentPlayerWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEnteranceFee() public view returns (uint256) {
        return i_ENTRANCE_FEE;
    }

    function getRaffleCurrentState() public view returns (RaffleState) {
        return raffleState;
    }

    function getRaffleNoOfPlayers() public view returns (uint256) {
        return s_player.length;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
}
