// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// objective :
// get funds from the user to this contract
// withdraw funds from this contract to users wallet
// set minimum funding value

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Custom error
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    AggregatorV3Interface private s_priceFeed;

    // owner
    address public immutable i_owner; // immutable - value get fixed when deployed - by using immutable keyword gas consumption is less

    constructor(address priceFeed) {
        // SPECIAL FUNCTION - immediatly called when we deploy
        s_priceFeed = AggregatorV3Interface(priceFeed); // set the price feed address
        i_owner = msg.sender;
    }

    uint256 public constant MINIMUM_USD = 5e18; //  constant - value get fixed when compiled - by using constant keyword gas consumption is less

    address[] private s_funders;
    mapping(address funder => uint256 moneyFunded) private s_addressToMoney;

    function fund() public payable {
        // minimum amout that must to be send
        // firstArgument.libraryFunction(restOfArguments); - this how to use functions frmo lib
        require(msg.value.ETHConverter(s_priceFeed) >= MINIMUM_USD, "shown when transaction reverts"); // 1 ETH = 10**18 wei   // require - if this condition doest satisfy then function will revert and return remaining gas
        s_funders.push(msg.sender); // also if some values are changed or some operation is performed then tahat also will be reverted
        s_addressToMoney[msg.sender] += msg.value; // mappping from address to money value
    }

    // function getPrice() public view returns(uint256){
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    //     (,int256 price,,,) = priceFeed.latestRoundData();   // price of ETH in terms of USD
    //     return uint256(price * 1e10);   // msg.value has 18 0s so we need to make price of same
    // }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // function ETHConverter(uint256 ethAmount) public view returns(uint256){
    //     uint256 ethPrice = getPrice();
    //     uint256 usdAmount = (ethPrice * ethAmount) / 1e18;  // diveide by 1e18 cuz both have 18 decimal zeros
    //                                                         // so when multiply 18 + 18 = 36 zeros then divided by 18 results in 18 zeros in answer
    //     return usdAmount;
    // }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be owner");
        // for (uint256 index = 0; index < s_funders.length; index++) {     // since s_funders.length is reading from storage in each iterations - more gas cost
        //     address funder = s_funders[index];
        //     s_addressToMoney[funder] = 0;
        // }

        // Rather we can do - store s_funders.length - in a local variable stored in memory - retrieving which doest cost much gas
        uint256 s_fundersLength = s_funders.length;
        for (uint256 index = 0; index < s_fundersLength; index++) {
            address funder = s_funders[index];
            s_addressToMoney[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // Fund withdrawing
        // // transfer - reverts if gas limit exceeds - gas limit of 2300
        // // msg.sender = address
        // // payable(msg.sender) = payble address
        // payable(msg.sender).transfer(address(this).balance);    // transfer(AMOUNT)
        // //      | "TO" where we have to transfer

        // // send - (doesnt reverts) returns bool, true - transaction success, false - failure(gas limit exceeds) - gas limit of 2300
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success, "Send failed");

        // call - (doesnt reverts) returns bool(like send) - doesnt have gas limit
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // receive function
    receive() external payable {
        fund(); // if anyone sends ETH without calling fund() it will automatically call fund ()
    }

    // fallback function
    fallback() external payable {
        fund(); // if anyone sends ETH without calling fund() it will automatically call fund ()
    }

    // Modifier - keywords that can be added at the function declaration to provide some functionalities
    modifier onlyOwner() {
        // this will get executed first when function is called
        // require(msg.sender == i_owner, "Must be owner");  // firstly, then ...
        if (msg.sender != i_owner) {
            revert NotOwner();
        } // Custom error saves gas as compare to giving strings in "require"
        _; // this means - execute whatever in the function
    }

    // view / pure functions - (getters)
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getAmountFundedByAddress(address funder) external view returns (uint256) {
        return s_addressToMoney[funder];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
