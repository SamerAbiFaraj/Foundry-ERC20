//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract TestOurToken is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalanece() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        //Bob approves Alice to send tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 500);

        assertEq(ourToken.balanceOf(alice), 500);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - 500);
    }

    function testInitialSupply() public view {
        uint256 totalSupply = ourToken.totalSupply();
        assertGt(totalSupply, 0, "Total supply should be greater than zero");
    }

    function testTransfer() public {
        vm.prank(bob);
        ourToken.transfer(alice, 500);
        assertEq(ourToken.balanceOf(alice), 500);
    }

    function testTransferRevertsOnInsufficientBalance() public {
        uint256 bobBalance = ourToken.balanceOf(bob);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "ERC20InsufficientBalance(address,uint256,uint256)"
                    )
                ),
                bob,
                bobBalance,
                bobBalance + 1
            )
        );
        ourToken.transfer(alice, bobBalance + 1);
    }

    function testAllowanceIncreaseDecrease() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice for initial allowance
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        // Check initial allowance
        assertEq(
            ourToken.allowance(bob, alice),
            initialAllowance,
            "Initial allowance should match"
        );
    }

    function testTransferFromWithInsufficientAllowance() public {
        uint256 initialAllowance = 500;

        // Bob approves Alice for initial allowance
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        // Attempt to transfer more than allowed
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "ERC20InsufficientAllowance(address,uint256,uint256)"
                    )
                ),
                alice,
                initialAllowance,
                initialAllowance + 1
            )
        );
        ourToken.transferFrom(bob, alice, initialAllowance + 1);
    }

    function testZeroAddressTransferReverts() public {
        // Test transfer to zero address
        vm.prank(msg.sender);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InvalidReceiver(address)")),
                address(0)
            )
        );
        ourToken.transfer(address(0), 100);
    }

    function testApproveZeroAddress() public {
        // Test approve to zero address
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InvalidSpender(address)")),
                address(0)
            )
        );
        ourToken.approve(address(0), 100);
    }
}
