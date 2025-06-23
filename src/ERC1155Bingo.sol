pragma solidity 0.8;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Bingo is VRFConsumerBaseV2Plus , ERC1155("https://scarlet-surprised-chickadee-681.mypinata.cloud/ipfs/bafybeieccctaw3thh24eqpueryh33nen6ta72qy66pk666a76cdhd34ypa/{id}.json"){
    bool registrationOn;
    bool public gameOn;
    uint256 lastDrawnBlock;

    // mapping(address , card[][])
    address[] public users;
    uint256[] public drawnNumbers;
    address private _owner;

    mapping(uint256 => address) requestIdToUser;
    mapping(address =>  uint8[][]) userToBoard;
    mapping(uint256 => bool) isDrawRequest;



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
        gameOn = true;
        for(uint i = 0 ; i < users.length ; i++){
            uint256 requestId = getRandomNumber();
            requestIdToUser[requestId] = users[i];
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {

        if (isDrawRequest[requestId]) {
            // Here we handle cards 
            uint randomBase = randomWords[0];
            uint salt ; 
            uint256 randomNumber;

            while (true) {
                randomNumber = (uint256(keccak256(abi.encode(randomBase, salt))) % 25) + 1 ;
                
                if(isNumberRepeated(randomNumber)){
                    salt++;
                }
                break;
            }

            _mint(msg.sender,randomNumber,1,"");
            drawnNumbers.push(randomNumber);

        }
        else {
        // here we handle boards logic
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
}

function drawCard() public{
    require(gameOn, "Game not started yet");
    if (drawnNumbers.length == 0) {
        uint256 requestCardId = getRandomNumber();
        isDrawRequest[requestCardId] = true;   
        lastDrawnBlock = block.number;  
        return; 
    }
    require(lastDrawnBlock < block.number,"only draw 1 card per block");
    uint256 requestCardId = getRandomNumber();
    isDrawRequest[requestCardId] = true;   
    lastDrawnBlock = block.number; 
}

function checkWinner() public returns(bool, address winner){
    require(gameOn, "Game not started yet");
    require(isUserAvailable(msg.sender), "User is not in game");
    uint8[][] memory board = userToBoard[msg.sender];

    //check rows
    for (uint i = 0; i < 5; i++) {
    bool win = true;
        for (uint j = 0; j < 5; j++) {
            if (!isNumberAvailable(board[i][j])) {
                win = false;
                break;
            }
        }
        if (win) {
        winner = msg.sender;
        gameOn = false; // Stop game
        return (true , winner);
    }
    }
    //check columns
    for (uint i = 0; i < 5; i++) {
    bool win = true;
        for (uint j = 0; j < 5; j++) {
            if (!isNumberAvailable(board[j][i])) {
                win = false;
                break;
            }
        }
        if (win) {
        winner = msg.sender;
        gameOn = false; // Stop game
        return (true , winner);
    }
    }

    //check diagonal 1
        bool winDiag1 = true;
        for (uint i = 0; i < 5; i++) {
            if (!isNumberAvailable(board[i][i])) {
                winDiag1 = false;
                break;
            }
        }
        if(winDiag1){
        winner = msg.sender;
        gameOn = false; // Stop game
        return (true , winner);
    }

        bool winDiag2 = true;
        for (uint i = 0; i < 5; i++) {
            if (!isNumberAvailable(board[i][4 - i])) {
                winDiag2 = false;
                break;
            }
        }
        if(winDiag2){
        winner = msg.sender;
        gameOn = false; // Stop game
        return (true , winner);
    }

 
        return (false , address(0));
}

    function isNumberRepeated(uint256 num) view private returns(bool){
        for (uint i = 0; i < drawnNumbers.length; i++) {
            if (num == drawnNumbers[i]) {
                return true;
            }
        }
        return false;
    }
function  isNumberAvailable(uint256 num) view private returns(bool){
    for (uint i = 0; i < drawnNumbers.length; i++) {
        if(num == drawnNumbers[i]){
            return true;
        }
    }
    return false;
}

function isUserAvailable(address user) view private returns(bool){
    for (uint i = 0; i < users.length; i++) {
        if(user == users[i]){
            return true;
        }
    }
    return false;
}

function getRandomNumber() private returns(uint256){
   uint256 id =  s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subId: , //add ur subid 
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
        return id;
}

}
