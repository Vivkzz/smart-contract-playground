pragma solidity 0.8;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Bingo is VRFConsumerBaseV2Plus{
    bool registrationOn;
    bool gameOn;

    // mapping(address , card[][])
    address[] public users;
    address private _owner;
    mapping(uint256 => address) requestIdToUser;
    mapping(address =>  uint8[][]) userToBoard;


    constructor() VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
       _owner= msg.sender;
    }

    modifier onlyGameOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function startRegistration() public onlyGameOwner {
        registrationOn = true;
    }

    function stopRegistration() public onlyGameOwner {
        registrationOn = false;
    }

    function Register() public {
        require(registrationOn, "Registration is not opened yet !!!");
        users.push(msg.sender);
    }

    function startGame() public onlyGameOwner {
        for(uint i = 0 ; i < users.length ; i++){
        
            uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subId: 123444,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: true
                    })
                )
            })
        );

        requestIdToUser[requestId] = users[i];
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address user = requestIdToUser[requestId];
        uint8[5][5] memory board;
        uint8[25] memory nums;

        uint256 randomBase = randomWords[0];

        //WE can generate 25 numbers directly but it will be gas expensive approach

        //Using Fisher-Yates shuffle
        for (uint8 i = 0; i < 25; i++) {
            nums[i] = i + 1;
        }

        for (uint i = 0; i < 25; i++) {
            uint256  j =  uint256(keccak256(abi.encode(randomBase , i))) % 25 ; 
            (nums[i],nums[j]) = (nums[j], nums[i]);
        }
        uint8 index = 0;
        for (uint i = 0; i < 5; i++) {
            for (uint j = 0; j < 5; j++) {
                board[i][j] = nums[index];
                index++;
            }
        }

        userToBoard[user] = board;
}

// Still remaining 
}
