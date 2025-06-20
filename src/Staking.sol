// There are various places in this contract that can be more efficient

pragma solidity 0.8;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {
    struct Stake {
        // address staker;
        uint256 amount;
        uint256 joinTime;
    }

    struct Pool {
        uint256 beginDate;
        uint256 endDate;
    }

    mapping(address => Stake) public stakers;
    mapping(address => bool) public hasWithdrawn;
    Pool public pool;
    address[] public stakerArr;
    IERC20 public cloudCoin;
    uint256 constant REWARD_POOL = 1000000 * 1e18;

    constructor(address cloudCoinAddress) Ownable(msg.sender) {
        cloudCoin = IERC20(cloudCoinAddress);
    }

    //assuming pool is already there and no need to create pool so single pool only
    //assuming pool is already funded with 1,000,000 cloud tokens

    function startPool(uint256 duration) external onlyOwner {
        pool = Pool({beginDate: block.timestamp, endDate: block.timestamp + duration});
    }

    function stake(uint256 amountToStake) external {
        require(block.timestamp < pool.endDate, "pool is ended");
        require(amountToStake > 0, "Cant Stake 0 coins");
        require(!checkUser(msg.sender), "Can only stake once");
        stakers[msg.sender] = Stake({amount: amountToStake, joinTime: block.timestamp});
        stakerArr.push(msg.sender);

        cloudCoin.transferFrom(msg.sender, address(this), amountToStake);
    }

    function checkUser(address user) private view returns (bool) {
        for (uint256 index = 0; index < stakerArr.length; index++) {
            if (user == stakerArr[index]) {
                return true;
            }
        }
        return false;
    }

    function totalUserWeight() private view returns (uint256) {
        uint256 totalWeight;
        for (uint256 index = 0; index < stakerArr.length; index++) {
            address userAddr = stakerArr[index];
            uint256 userAmount = stakers[userAddr].amount;

            // if you want to give reward based on seconds remove / 1days
            uint256 userTimeInDays = (pool.endDate - stakers[userAddr].joinTime) / 1 days;
            totalWeight += userAmount * userTimeInDays;
        }

        return totalWeight;
    }

    function withdraw() external {
        require(pool.endDate < block.timestamp, "Pool not ended");
        require(checkUser(msg.sender), "User Not Staked! ");
        require(!hasWithdrawn[msg.sender], "Already Withdrawn");
        uint256 userWeight = stakers[msg.sender].amount * (pool.endDate - stakers[msg.sender].joinTime) / 1 days;
        uint256 totalWeight = totalUserWeight();
        uint256 userReward = (userWeight * REWARD_POOL) / totalWeight;

        hasWithdrawn[msg.sender] = true;
        // we predefined pool size already 1,000,000
        cloudCoin.transfer(msg.sender, userReward);
    }
}
