// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  mapping(address => uint256) public balances;
  mapping(address => uint256) public depositTimestamps;

  uint256 public constant rewardRatePerSecond =  2;
  uint256 public withdrawlDeadline = block.timestamp + 120 seconds;
  uint256 public claimDeadline = block.timestamp + 240 seconds;
  uint256 public currentBlock = 0;

  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amount);

  ExampleExternalContract public exampleExternalContract;

  modifier withdrawlDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = withdrawlTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawl deadline has not been reached");
    } else {
      require(timeRemaining > 0, "Withdrawl deadline has been reached");
    }
    _;
  }

  modifier claimDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = claimPeriodLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Claim deadline has not been reached");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }


  function withdrawlTimeLeft() public view returns (uint256 withdrawlTimeLeft) {
      if(block.timestamp >= withdrawlDeadline) {
        return 0;
      } else {
        return (withdrawlDeadline - block.timestamp);
      }
  }

  function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
      if(block.timestamp >= claimDeadline) {
        return 0;
      } else {
        return (claimDeadline - block.timestamp);
      }
  }

  function stake() public payable withdrawlDeadlineReached(false) claimDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public withdrawlDeadlineReached(true) claimDeadlineReached(false) notCompleted {
    require(balances[msg.sender] > 0, "You have no balance to withdraw");
    uint256 withdrawAmount = balances[msg.sender];
    uint256 periods = block.timestamp - depositTimestamps[msg.sender];
    for (uint256 i = 0; i < periods; i++) {
      withdrawAmount += withdrawAmount * rewardRatePerSecond/100;
    }
    balances[msg.sender] = 0;

    (bool sent, bytes memory data) = msg.sender.call{value: withdrawAmount}("");
    require(sent, "RIP; withdraw failed :( ");
  }

  function execute() public claimDeadlineReached(true) notCompleted {
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
  }

  function reset() public {
    exampleExternalContract.setStaker();
    exampleExternalContract.reset();

    withdrawlDeadline = block.timestamp + 120 seconds;
    claimDeadline = block.timestamp + 240 seconds;
  }

  function killTime() public {
    currentBlock = block.timestamp;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

}
