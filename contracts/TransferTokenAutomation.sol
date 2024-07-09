// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract TransferTokenAutomation is AutomationCompatibleInterface {
    error TransferToken__UpKeepNotNeeded();
    error TransferToken__TransferFailed();

    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
    }

    Transaction[] public transactions;

    constructor(uint256 updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    function depositEther(address receiver) public payable {
        Transaction memory transaction = Transaction({
            sender: msg.sender,
            receiver: receiver,
            amount: msg.value
        });
        transactions.push(transaction);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = (block.timestamp - lastTimeStamp) > interval;
        bool hasBalance = address(this).balance > 0;
        bool hasUserTransfer = false;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (hasUserTransfer = transactions[i].amount > 0) {
                hasUserTransfer = true;
                break;
            }
        }
        upkeepNeeded = (timeHasPassed && hasBalance && hasUserTransfer);
        return (upkeepNeeded, "0x00");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert TransferToken__UpKeepNotNeeded();
        }
        lastTimeStamp = block.timestamp;
        for (uint256 i = 0; i < transactions.length; i++) {
            address receiver = transactions[i].receiver;
            uint256 amount = transactions[i].amount;

            (bool success, ) = receiver.call{value: amount}("");
            if (!success) {
                revert TransferToken__TransferFailed();
            }

            if (i < transactions.length) {
                transactions[i] = transactions[transactions.length - 1];
            }
            transactions.pop();
            if (transactions.length != 0) {
                break;
            }
        }
    }
}
// 0xdcA85BB75c894648c405d24DAF61Ae46ead8EDF0
