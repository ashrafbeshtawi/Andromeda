pragma solidity ^0.8.14;

contract Admin{
    struct Vote {
        uint id;
        address targetAddress;
        uint votingPeriod;
        uint target;
        mapping(address => bool) voters;
        uint NumberOfApprovals;
        uint NumberOfDisapprovals;
        uint startDate;
        uint endDate;
    }
    // Seconds in one day   
    uint public DAY = 86400;
    // Main properties of the contract
    address[10] admin;
    address public libraryAddress;
    address public treasuryAddress;
    Vote[10] public votes;
    mapping(uint => Vote) public votesArchive;
    // in Days
    uint public votePeriod;
    uint public minVotePeriod;

    constructor(uint minVotingPeriod) {
        admin[0] = msg.sender;
        minVotePeriod = votePeriod = minVotingPeriod;
    }

    function getAdmin() public view returns(address[10] memory _admin) {
        return admin;
    }

    // resolve vote if ended
    // vote ends when endDate is smaller than current block timestamp
    function resolveVote(uint _voteIndex) public {
        require(votes[_voteIndex].endDate <= block.timestamp, "Vote is not ended");
        require(votes[_voteIndex].endDate != 0, "Vote is not initialized");
        if (votes[_voteIndex].NumberOfApprovals > votes[_voteIndex].NumberOfDisapprovals) {
            // approve vote
            // add admin
            if (votes[_voteIndex].target == 0 && (uint) (getFreeAdminIndex()) != 1) {
                admin[(uint) (getFreeAdminIndex())] = votes[_voteIndex].targetAddress;
            // remove admin
            } else if (votes[_voteIndex].target == 1) {
                for (uint index = 0; index < admin.length; index++) {
                    if (admin[index] == votes[_voteIndex].targetAddress) {
                        admin[index] = address(0);
                    }
                }
            // change library address
            } else if (votes[_voteIndex].target == 2) {
                libraryAddress = votes[_voteIndex].targetAddress;
            // change treasury address
            } else if (votes[_voteIndex].target == 3) {
                treasuryAddress = votes[_voteIndex].targetAddress;
            // change vote period
            } else if (votes[_voteIndex].target == 4 && votes[_voteIndex].votingPeriod >= minVotePeriod) {
                votePeriod = votes[_voteIndex].votingPeriod;
            }
            
        }
        // move vote to archive (actually making a copy, without the voters to not make this call too expensive)
        uint voteId = votes[_voteIndex].id;
        votesArchive[voteId].id = voteId;
        votesArchive[voteId].targetAddress = votes[_voteIndex].targetAddress;
        votesArchive[voteId].target = votes[_voteIndex].target;
        votesArchive[voteId].NumberOfApprovals = votes[_voteIndex].NumberOfApprovals;
        votesArchive[voteId].NumberOfDisapprovals = votes[_voteIndex].NumberOfDisapprovals;
        votesArchive[voteId].startDate = votes[_voteIndex].startDate;
        votesArchive[voteId].endDate = votes[_voteIndex].endDate;  
        votesArchive[voteId].votingPeriod = votes[_voteIndex].votingPeriod;    
  
        // mark the vote in the array as ended so that it will be replaced in the future
        votes[_voteIndex].endDate = 0;   
    }


    // add new vote (only admin can do this)
    // returns vote id
    function addVote(address _targetAddress, uint _target, uint _votingPeriod) public returns(uint) {
        require(isAdmin(), "Only admin can add vote");
        require(_votingPeriod >= votePeriod, "Voting period is too short");
        int freeVoteIndex = getFreeVoteIndex();
        require(freeVoteIndex != -1, "No free vote index");
        uint voteId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _targetAddress, _target, _votingPeriod)));
        votes[(uint) (freeVoteIndex)].id = voteId;
        votes[(uint) (freeVoteIndex)].targetAddress = _targetAddress;
        votes[(uint) (freeVoteIndex)].target = _target;
        votes[(uint) (freeVoteIndex)].votingPeriod = _votingPeriod;
        votes[(uint) (freeVoteIndex)].startDate = block.timestamp;
        votes[(uint) (freeVoteIndex)].endDate = block.timestamp + _votingPeriod * DAY;
        return voteId;
    }

    // checks if caller is admin
    function isAdmin() private view returns(bool) {
        for (uint index = 0; index < admin.length; index++) {
            if (admin[index] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    // check if there is avaliable place for new admin
    // returns index for the new admin in the array
    // else returns -1
    function getFreeAdminIndex() private view returns(int) {
        for (uint index = 0; index < admin.length; index++) {
            if (admin[index] == address(0)) {
                return int(index);
            }
        }
        return -1;
    }

    // check if there is available place for new vote
    // returns index for the new vote it the array
    // else returns -1
    function getFreeVoteIndex() private returns(int) {
        for (uint index = 0; index < votes.length; index++) {
            // check for expired votes
            if (votes[index].endDate <= block.timestamp) {
                // check if vote is not resolved then resolve it
                if (votes[index].endDate != 0) {
                    resolveVote(votes[index].id);
                }
                return int(index);
            }
        }
        return -1;
    }
}

