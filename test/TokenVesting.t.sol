// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TokenVesting} from "../src/TokenVesting.sol";

contract MockToken is ERC20 {
    constructor() ERC20("TestToken", "TST") {
        _mint(msg.sender, 1000000 ether);
    }
}

contract TestTokenVesting is Test {
    address payer = address(0x1);
    address receiver = address(0x2);
    MockToken public token;
    TokenVesting public vesting;

    function setUp() external {
        token = new MockToken();
        vesting = new TokenVesting();
        token.transfer(payer, 100 ether);
    }

    function testDepositAndWithdraw() external {
        vm.startPrank(payer);
        token.approve(address(vesting), 10 ether);
        vesting.deposit(address(token), receiver, 10 ether, 10 days);
        vm.stopPrank();

        vm.startPrank(receiver);
        vm.expectRevert("Nothing to withdraw");
        vesting.withdraw();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.startPrank(receiver);
        console.log("before", token.balanceOf(receiver));
        vesting.withdraw();
        console.log("after", (token.balanceOf(receiver) / 1 ether));
        vm.stopPrank();
    }

    // function testWithdraw() external {}
}
