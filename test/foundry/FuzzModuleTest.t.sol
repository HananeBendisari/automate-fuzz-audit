// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Automate.sol";
import "../../contracts/libraries/LibDataTypes.sol";

contract FuzzModuleTest is Test {
    Automate automate;

    function setUp() public {
        // Initialize the Automate contract
        automate = new Automate(payable(address(this)));
    }

    /// @dev AUDIT: Test setModule with mismatched modules and args
    function testFuzzSetModule(
        LibDataTypes.Module[] memory modules,
        address[] memory moduleAddresses
    ) public {
        // Ensure valid test data
        vm.assume(modules.length > 0 && moduleAddresses.length > 0);
        vm.assume(modules.length != moduleAddresses.length);

        // Record logs to verify event emissions
        vm.recordLogs();

        // Expect revert due to mismatched lengths
        vm.expectRevert();
        automate.setModule(modules, moduleAddresses);

        // Check for any unexpected events
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool emitted;
        for (uint256 i = 0; i < entries.length; i++) {
            if (
                entries[i].topics.length > 0 &&
                entries[i].topics[0] == keccak256("ModuleSet(address[],address[])")
            ) {
                emitted = true;
                break;
            }
        }
        assertTrue(!emitted, "ModuleSet event should not be emitted on failure");
    }
} 