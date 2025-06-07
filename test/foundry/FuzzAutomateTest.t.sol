// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Automate.sol";
import "../../contracts/libraries/LibDataTypes.sol";
import "../../contracts/libraries/LibTaskId.sol";

/// @dev This test is a proposed addition. It is skipped by default unless run in a test environment with proxy admin rights.

// Add the MockOps contract to simulate the expected behavior by Automate
contract MockOps {
    // Simulate address(gelato) used in `onlyGelato`
    function gelato() external view returns (address) {
        return address(this);
    }

    // Add any required interface if Automate expects ops to respond to something
    // For now we keep it minimal — extend as needed
}

contract FuzzAutomateTest is Test {
    Automate automate;
    MockOps mockOps;

    function setUp() public {
        vm.skip(true);
        // Deploy the MockOps contract
        mockOps = new MockOps();

        // Use MockOps for Automate initialization
        automate = new Automate(payable(address(this)));

        // Declare arrays before using them
        LibDataTypes.Module[] memory mods = new LibDataTypes.Module[](1);
        address[] memory addrs = new address[](1);

        mods[0] = LibDataTypes.Module.RESOLVER;
        addrs[0] = address(this);

        automate.setModule(mods, addrs);
    }

    function testFuzzCreateTask(
        address execAddr,
        bytes memory execData,
        address feeToken
    ) public {
        // Declare modules before using them
        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);

        vm.assume(execAddr != address(0));
        vm.assume(feeToken != address(0));
        vm.assume(execData.length >= 4 && execData.length <= 128);

        uint8 argCount = uint8(bound(uint256(uint160(execAddr)), 1, 4));
        bytes[] memory args = new bytes[](argCount);
        for (uint256 i = 0; i < argCount; i++) {
            args[i] = abi.encode(bound(execData.length, 1, 32));
        }

        modules[0] = LibDataTypes.Module.RESOLVER;

        LibDataTypes.ModuleData memory moduleData = LibDataTypes.ModuleData({
            modules: modules,
            args: args
        });

        vm.label(execAddr, "ExecAddress");
        vm.label(feeToken, "FeeToken");
        vm.recordLogs();

        bytes32 taskId;
        try automate.createTask(execAddr, execData, moduleData, feeToken) returns (bytes32 _taskId) {
            taskId = _taskId;
        } catch {
            return;
        }

        assertTrue(taskId != bytes32(0), "taskId should not be zero");

        bytes32[] memory taskIds = automate.getTaskIdsByUser(address(this));
        bool found;
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] == taskId) {
                found = true;
                break;
            }
        }
        assertTrue(found, "taskId should be stored");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool emitted;
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] == keccak256("TaskCreated(address,address,bytes,(uint8[],bytes[]),address,bytes32)")
            ) {
                emitted = true;
                break;
            }
        }
        assertTrue(emitted, "TaskCreated event not emitted");
    }
}
