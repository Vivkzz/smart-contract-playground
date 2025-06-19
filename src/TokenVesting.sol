// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenVesting {
    // deposite token all in once
    // withdraw function take n day or 1/n per day
    // we are taking some test token

    struct Vesting {
        address payer;
        address receiver;
        address tokenAddress;
        uint256 totalAmount;
        uint256 withdrawnAmount;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => Vesting) public vestings;

    function deposit(address _tokenAddress, address _receiver, uint256 _amount, uint256 _duration) public {
        require(vestings[_receiver].totalAmount == 0, "Already vested");

        vestings[_receiver] = Vesting({
            payer: msg.sender,
            receiver: _receiver,
            tokenAddress: _tokenAddress,
            totalAmount: _amount,
            withdrawnAmount: 0,
            startTime: block.timestamp,
            duration: _duration
        });
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Failed To Transfer");
    }

    function withdraw() external {
        Vesting storage schedule = vestings[msg.sender];
        require(msg.sender == schedule.receiver, "only receiver can withdrw");
        require(schedule.totalAmount > 0, "Not Available to withdraw");

        uint256 elapsedTime = block.timestamp - schedule.startTime;
        uint256 withdrawAmount;
        if (elapsedTime > schedule.duration) {
            withdrawAmount = schedule.totalAmount - schedule.withdrawnAmount;
        } else {
            withdrawAmount = (schedule.totalAmount * elapsedTime) / schedule.duration;
            withdrawAmount -= schedule.withdrawnAmount;
        }

        require(withdrawAmount > 0, "Nothing to withdraw");
        schedule.withdrawnAmount += withdrawAmount;
        require(IERC20(schedule.tokenAddress).transfer(schedule.receiver, withdrawAmount), "Failed To Transfer");

    }
}
