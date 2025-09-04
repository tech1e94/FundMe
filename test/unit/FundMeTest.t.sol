// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMeTest is Test {
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

    function testMINIMUM_USDisFiveDollar() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // us -> FundMeTest -> fundMe    -- we are not deploying fundMe, we are calling FundMeTest which then deploys fundMe
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testVersion() public view {
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306 - Kovan Testnet Chainlink ETH/USD Price Feed
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundedNotEnoughETH() public {
        vm.expectRevert(); // function will fails if next line executes

        fundMe.fund(); // send 0 ETH
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        // give USER 10 ETH

        fundMe.fund{value: SEND_VALUE}(); // send 6 ETH

        uint256 amount = fundMe.getAmountFundedByAddress(USER); // get the amount funded by USER
        assertEq(amount, SEND_VALUE); // check if amount is equal to 6 ETH
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER); // check if the first funder is USER
    }

    modifier funded() {
        vm.deal(address(fundMe), SEND_VALUE); // give fundMe contract 6 ETH
        fundMe.fund{value: SEND_VALUE}(); // call fund function
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // USER tries to call withdraw function
        vm.expectRevert(); // expect revert with NotOwner error
        fundMe.withdraw(); // USER tries to withdraw
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // get the balance of fundMe contract
        uint256 startFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // call withdraw function

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10; // number of funders

        for (uint160 i = 0; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoax = vm.prank() + vm.deal() - creates a fake address with SEND_VALUE
            fundMe.fund{value: SEND_VALUE}(); // fund the contract with SEND_VALUE
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // get the balance of fundMe contract
        uint256 startFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();

        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // call withdraw function

        uint256 gasUsed = gasleft();
        console.log("Gas used : ");
        console.log((gasStart - gasUsed) * tx.gasprice);

        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingOwnerBalance + startFundMeBalance,
            fundMe.getOwner().balance
        );
    }
}
