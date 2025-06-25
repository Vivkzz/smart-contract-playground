// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8;

import {Test} from "forge-std/Test.sol";
import {Bingo} from "../src/ERC1155Bingo.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestBingo is Test {
    Bingo bingo;
    VRFCoordinatorV2_5Mock vrf;
    address player1 = address(1);
    address player2 = address(2);
    address player3 = address(3);
    address owner = address(4);
    uint256 subId;
    bytes32 MOCK_KEYHASH = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;

    function setUp() public {
        vm.startPrank(owner);
        vrf = new VRFCoordinatorV2_5Mock(0.002 ether, 40 gwei, 0.004 ether);
        subId = vrf.createSubscription();
        vrf.fundSubscription(subId, 100 ether);
        bingo = new Bingo(address(vrf), subId, MOCK_KEYHASH);
        vrf.addConsumer(subId, address(bingo));
        bingo.startRegistration();
        vm.stopPrank();
    }

    function teststartRegistration() public {
        vm.startPrank(player1);
        bingo.register();
        vm.stopPrank();

        assertEq(bingo.getUsersLength(), 1);
        assertEq(bingo.users(0), player1);
    }

    function cantRegisterIfClosed() public {
        vm.prank(owner);
        bingo.stopRegistration();

        vm.expectRevert("Registration is not opened yet !!!");
        vm.prank(player2);
        bingo.register();
    }

    function testStartGameAndBoard() public {
        vm.prank(player3);
        bingo.register();

        vm.prank(owner);
        bingo.startGame();

        vrf.fulfillRandomWords(1, address(bingo));

        uint8[5][5] memory board;
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = 0; j < 5; j++) {
                board[i][j] = bingo.userToBoard(player3, i, j);
            }
        }
        assertGt(board[0][0], 0);
        assertLe(board[0][0], 25);
    }
}
