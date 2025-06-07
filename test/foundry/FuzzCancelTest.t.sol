// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Automate.sol";

contract FuzzCancelTest is Test {
    Automate automate;

    function setUp() public {
        // Initialize the Automate contract
        automate = new Automate(payable(address(this)));
    }

    /// @dev AUDIT: Test cancelTask with invalid and spoofed taskId values
    function testFuzzCancelTask(bytes32 taskId) public {
        vm.assume(taskId != bytes32(0));

        // Record logs to verify event emissions
        vm.recordLogs();

        // Simulate replay cancellation attempts
        automate.cancelTask(taskId);

        // Attempt to cancel again to test double-cancel revert
        vm.expectRevert();
        automate.cancelTask(taskId);

        // Check for TaskCancelled event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool emitted;
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] == keccak256("TaskCancelled(bytes32)")
            ) {
                emitted = true;
                break;
            }
        }
        assertTrue(emitted, "TaskCancelled event not emitted");
    }
} 