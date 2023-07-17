//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe,WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    uint256 number = 1;
    FundMe fundMe;
    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 startingBalance = 10 ether;
    uint256 public GAS_PRICE = 1;
    //DeployFundMe deployFundMe = new DeployFundMe();
    function setUp() external{
        DeployFundMe  deploy= new DeployFundMe();
        fundMe=deploy.run();
        vm.deal(USER, startingBalance);
    }
    function testUserCanFundAndOwnerWithdraw() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}