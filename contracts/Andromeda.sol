pragma solidity ^0.8.14;

contract Andromeda{
    enum Role{ admin, board_member}
    // Maintainer must be a REAL Person his public info available
    // not just a wallet-address :D
    struct Maintainer{
        string name;
        string email;
        string website; // optional
        uint mobile; // optional
        string facebook; // optional
        string twitter; // optional
        address m_address;
    }
    // Arrays for maintaining the token's state
    mapping (address => Maintainer) public admins;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
    // Token Details
    uint public totalSupply;
    string public name = "Andromeda";
    string public symbol = "AND";
    uint public decimals;

    // Events to be emitted on actions
    event Transfer (address indexed from, address indexed to, uint value);
    event Approve (address indexed owner, address indexed spender, uint value);

    // All tokens goes to the contract itself instead
    // of trusting the admins with the tokens :p
    constructor(uint _totalSupply, uint _decimals) {
        totalSupply = _totalSupply * 10 ** _decimals;
        balances[address(this)] = totalSupply;
        admins[msg.sender] = Maintainer("Ashraf", "xxx", "", 0, "", "", msg.sender);
    }

    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }


    // Transfers from sender to another address
    // 0 amount is accepted
    function transfer(address _to, uint _value) public returns(bool) {
        require(balanceOf(msg.sender) >= _value,"Balance too low");
        require(balanceOf(msg.sender) >= _value,"Balance too lowwww");
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Allow someone to transfer on behlaf of someone else
    // 0 amount is accepted
    function transferFROM(address _from, address _to, uint _value) public returns(bool) {
    require(balanceOf(_from) >= _value,"Balance too low");
    require(allowance[_from][msg.sender] >= _value,"Allowance too low");
    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(_from, _to, _value);
    return true;
    }

    // Let someone transfer on my behalf
    function approve(address spender, uint amount) public returns(bool) {
        allowance[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
        return true; 
    }
}