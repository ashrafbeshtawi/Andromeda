pragma solidity ^0.8.14;

contract Simple{
    // define a variable with numeric type
    uint public x;
    // define a getter and setter for the variable  
    function getX() public view returns(uint) {
        return x;
    }
    function setX(uint _x) public {
        x = _x;
    }  
}