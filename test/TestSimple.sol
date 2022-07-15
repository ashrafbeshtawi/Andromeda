pragma solidity ^0.8.14;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Simple.sol";

contract TestSimple {
  // The address of the Simple contract to be tested
  Simple simple = Simple(DeployedAddresses.Simple());

  // The id of the pet that will be used for testing
  uint expectedPetId = 8;

  // The expected owner of adopted pet is this contract
  address expectedAdopter = address(this);
}