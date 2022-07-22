pragma solidity ^0.8.14;

contract Admin{
    struct Vote {
        uint id;
        address targerAddress;
        uint target;
        mapping(address => bool) voters;
        uint NumberOfApprovals;
        uint NumberOfDisapprovals;
        uint startDate;
        uint endDate;
    }
    // Main properties of the contract
    address[10] admin;
    address libraryAddress;
    address treasuryAddress;
    Vote[10] votes;
    Vote[] votesArchive;
    uint votePeriod;
    uint minVotePeriod;

    constructor() {
        admin[0] = msg.sender;
        libraryAddress = 0x0000000000000000000000000000000000000000;
        treasuryAddress = 0x0000000000000000000000000000000000000000;
        votePeriod = 0;
        minVotePeriod = 0;
    }

    function addAdmin(address _admin) public {
        admin[admin.length] = _admin;
    }

    function getAdmin() public view returns(address[10] memory _admin) {
        return admin;
    }

}