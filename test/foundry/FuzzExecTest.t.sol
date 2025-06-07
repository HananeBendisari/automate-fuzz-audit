// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Automate.sol";
import "../../contracts/libraries/LibDataTypes.sol";

contract MockExecutor {
    function execute() external pure {
        // Simulate malicious behavior
        revert("Malicious execution");
    }
}

contract MockFeeToken {
    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false; // Simulate failing transfer
    }
}

contract FuzzExecTest is Test {
    Automate automate;
    MockExecutor mockExecutor;
    MockFeeToken mockFeeToken;

    function setUp() public {
        // Initialize the Automate contract
        automate = new Automate(payable(address(this)));
        mockExecutor = new MockExecutor();
        mockFeeToken = new MockFeeToken();
    }

    /// @dev AUDIT: Test exec with malformed execData and invalid feeToken
    function testFuzzExec(
        address taskCreator,
        bytes memory execData,
        LibDataTypes.ModuleData memory moduleData
    ) public {
        vm.assume(taskCreator != address(0));
        vm.assume(execData.length >= 4 && execData.length <= 128);

        // Simulate invalid execData
        execData[0] = 0xFF; // Invalid function selector

        vm.recordLogs();
        vm.expectRevert();

        uint256 txFee = 0; // Example fee
        bool revertOnFailure = false; // Example revert flag

        try automate.exec(taskCreator, address(mockExecutor), execData, moduleData, txFee, address(mockFeeToken), revertOnFailure) {
            // Assert task is not removed on failed exec
            assertTrue(false, "Task should not be removed on failed exec");
        } catch {
            // Check for ExecFailed event
            Vm.Log[] memory entries = vm.getRecordedLogs();
            bool emitted;
            for (uint256 i = 0; i < entries.length; i++) {
                if (
                    entries[i].topics.length > 0 &&
                    entries[i].topics[0] == keccak256("ExecFailed(address,address,bytes,(uint8[],bytes[]),address,bytes32)")
                ) {
                    emitted = true;
                    break;
                }
            }
            assertTrue(emitted, "ExecFailed event not emitted");
        }
    }
} 