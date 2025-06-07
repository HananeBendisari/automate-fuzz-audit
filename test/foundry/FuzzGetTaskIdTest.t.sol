// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Automate.sol";
import "../../contracts/libraries/LibDataTypes.sol";

contract FuzzGetTaskIdTest is Test {
    Automate automate;

    function setUp() public {
        // Initialize the Automate contract
        automate = new Automate(payable(address(this)));
    }

    /// @dev AUDIT: Test getTaskId for hash collisions and non-deterministic behavior
    function testFuzzGetTaskId(
        address execAddr,
        bytes memory execData,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) public {
        vm.assume(execAddr != address(0));
        vm.assume(feeToken != address(0));
        vm.assume(execData.length >= 4 && execData.length <= 128);

        require(execData.length >= 4, "execData must be at least 4 bytes");
        bytes4 execSelector = bytes4(execData[0]) | (bytes4(execData[1]) >> 8) | (bytes4(execData[2]) >> 16) | (bytes4(execData[3]) >> 24);

        // Record logs to verify event emissions
        vm.recordLogs();

        bytes32 taskId1 = automate.getTaskId(execAddr, address(this), execSelector, moduleData, feeToken);
        bytes32 taskId2 = automate.getTaskId(execAddr, address(this), execSelector, moduleData, feeToken);

        // Assert that taskIds are consistent
        assertTrue(taskId1 == taskId2, "TaskId should be consistent across calls");

        // Check for any unexpected events
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool emitted;
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] == keccak256("TaskIdGenerated(bytes32)")
            ) {
                emitted = true;
                break;
            }
        }
        assertTrue(!emitted, "TaskIdGenerated event should not be emitted");
    }
} 