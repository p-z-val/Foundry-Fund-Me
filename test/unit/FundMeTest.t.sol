//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint256 number = 1;
    FundMe fundMe;
    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 startingBalance = 10 ether;
    uint256 public GAS_PRICE = 1;
    modifier funded() {
        vm.prank(USER); //Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, startingBalance);
    }

    function testMinimumUSD() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public {
        console.log(fundMe.getOwner());
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPricefeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 fundedAmount = fundMe.s_addressToAmountFunded(USER);
        assertEq(fundedAmount, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); //Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.s_funders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER); //Next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //ACT
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawalWithMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        vm.txGasPrice(GAS_PRICE);
        for (
            uint160 funderIndex = startingFunderIndex;
            funderIndex < numberOfFunders;
            funderIndex++
        ) {
            //Arrange
            //vm.prank(USER);
            //vm.deal
            hoax(address(funderIndex), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //vm.deal();
            //ACT
            // vm.txGasPrice(GAS_PRICE);
            // uint256 gasStart = gasleft();
            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            vm.startPrank(fundMe.getOwner());
            fundMe.cheaperWithdraw();
            /*uint256 gasEnd = gasleft();
            uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice;
            console.log(gasUsed);*/ // Thos is done to calc gas used
            vm.stopPrank();
            //Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingOwnerBalance + startingFundMeBalance ==
                    fundMe.getOwner().balance
            );
        }
    }

    function testWithdrawalWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        vm.txGasPrice(GAS_PRICE);
        for (
            uint160 funderIndex = startingFunderIndex;
            funderIndex < numberOfFunders;
            funderIndex++
        ) {
            //Arrange
            //vm.prank(USER);
            //vm.deal
            hoax(address(funderIndex), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //vm.deal();
            //ACT
            // vm.txGasPrice(GAS_PRICE);
            // uint256 gasStart = gasleft();
            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            /*uint256 gasEnd = gasleft();
            uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice;
            console.log(gasUsed);*/ // Thos is done to calc gas used
            vm.stopPrank();
            //Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingOwnerBalance + startingFundMeBalance ==
                    fundMe.getOwner().balance
            );
        }
    }
}
