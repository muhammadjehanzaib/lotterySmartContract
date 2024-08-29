# Foundry Smart Contract Lottery

### Description 

This Solidity smart contract implements a lottery system using Chainlink VRF (Verifiable Random Function) for random number generation and Chainlink Keepers for automated contract upkeep. Here’s a summary of its key features and components:

Contract Name: Raffle > src/Raffle.sol
Author: Muhammad Jehanzaib
License: MIT

VRFConsumerBaseV2Plus: For VRF functionality.
VRFV2PlusClient: For VRF client utilities.
AutomationCompatibleInterface: For Chainlink Keepers integration.
State Variables:

i_ENTRANCE_FEE: Minimum fee to enter the raffle.
i_INTERVAL: Time duration between raffle draws.
i_keyHash, i_subscriptionId, i_callbackGasLimit: Parameters for Chainlink VRF.
s_player: Array of addresses participating in the raffle.
s_lastTimeStamp, s_recentWinner, raffleState: Track raffle state and timing.
Functions:

enterRaffle(): Allows users to enter the raffle by paying the entrance fee.
checkUpKeep(): Determines if the contract is ready for a raffle draw based on criteria like time passed, contract balance, and player count.
raffleWinner(): Initiates the raffle drawing process, requesting a random number from Chainlink VRF.
fulfillRandomWords(): Handles the callback from Chainlink VRF to determine the raffle winner and transfer winnings.
Events:

RaffleEntered(address indexed player): Emitted when a player enters the raffle.
WinnerPicked(address indexed recentWinner): Emitted when a winner is selected.
RequestedRaffleWinner(uint256 requestID): Emitted when a random number request is made.
Getter Functions:

getEnteranceFee(): Returns the entrance fee.
getRaffleCurrentState(): Returns the current state of the raffle.
getRaffleNoOfPlayers(): Returns the number of players.
getRecentWinner(): Returns the address of the most recent winner.
getLastTimeStamp(): Returns the timestamp of the last raffle.
Usage: The contract enables participants to enter a lottery by paying a fee. Chainlink Keepers automate the raffle draw process, and Chainlink VRF ensures the randomness of the winner selection.

# Get Started
### Requirement
* git
  * You'll know you did it right if you can run git --version and you see a response like git version x.x.x
* foundry 
  * You'll know you did it right if you can run forge --version and you see a response like forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)
 
 # Qickstart
> git clone https://github.com/muhammadjehanzaib/lotterySmartContract.git
> cd lotterySmartContract
> forge build

# Library
If you're having a hard time installing the chainlink library, you can optionally run this command.
> forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit

# Deploy
 For local network(anvil) we have to run local network by using anvil command. Just go and open new treminal window and typr anvil( our local anvil setup is ready). Then deploy by using this command.
> forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

# Testing
> forge test








