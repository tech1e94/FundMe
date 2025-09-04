// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // create a fake address for testing
    uint256 constant SEND_VALUE = 6e18; // 6 ETH in wei
    uint256 constant STARTING_USER_BALANCE = 10e18; // 10 ETH in wei
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306));
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE); // give USER 10 ETH
    }

    function testUserCanFund() public {
        uint256 preUserBalance = address(USER).balance;
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}
