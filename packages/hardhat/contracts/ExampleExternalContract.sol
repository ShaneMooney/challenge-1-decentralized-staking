// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;
  address staker;

  function complete() public payable {
    completed = true;
  }

  function setStaker() public {
    staker = msg.sender;
  }

  function reset() public {
    require(msg.sender == staker, "Only staker can reset");

    (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
    require(sent, "RIP; reset failed :( ");

    completed = false;
  }

}
