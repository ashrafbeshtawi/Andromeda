// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.14;

contract Admin{
    struct Vote {
        uint id;
        address targetAddress;
        uint votingPeriod;
        uint target;
        mapping(address => uint) voters;
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
    uint public minStableBalancePeriod;

    // Events
    event VoteCreated(uint index);
    event Voted(address voter, uint vote);

    constructor(uint _minVotingPeriod, uint _minStableBalancePeriod) {
        admin[0] = msg.sender;
        minVotePeriod = votePeriod = _minVotingPeriod;
        minStableBalancePeriod = _minStableBalancePeriod;
    }

    // add/change the vote of specific holder on specific vote
    // vote : 0 -> no vote
    //        1 -> support the vote
    //        2 -> reject the vote
    //        * -> ignore
    // to be able to vote you must:
    //  1- be holder.
    //  2- have not moved any of your Balance since 
    function vote(uint _voteIndex, uint _vote) public {
        // no real connection for now
        (uint balance, uint holdingTime) = getBalance();

        require(balance > 0, "Balance too low");
        require(holdingTime >= minStableBalancePeriod, "Holding period too short");
        require(isVoteInitialised(_voteIndex), "Vote is not initialized");

        uint currentVote = votes[_voteIndex].voters[msg.sender];
        // new vote equals old vote then do nothing
        if (currentVote == _vote) {
            return;
        }
        // old vote need be changed -> first undo old vote
        // if support then remove 1 from Approvals
        if (currentVote == 1) {
            votes[_voteIndex].NumberOfApprovals = votes[_voteIndex].NumberOfApprovals - 1;
        // if against the proposal then remove 1 from Disapprovals
        } else if (currentVote == 2) {
            votes[_voteIndex].NumberOfDisapprovals = votes[_voteIndex].NumberOfDisapprovals - 1;
        }
        // now it is safe to add the new vote
        if (_vote == 1) {
            votes[_voteIndex].NumberOfApprovals = votes[_voteIndex].NumberOfApprovals + 1;
        } else if (_vote == 2) {
            votes[_voteIndex].NumberOfDisapprovals = votes[_voteIndex].NumberOfDisapprovals + 1;
        }
        // update state of this voter
        votes[_voteIndex].voters[msg.sender] = _vote;
        emit Voted(msg.sender, _vote);
    }

    function getAdmin() public view returns(address[10] memory _admin) {
        return admin;
    }

    // resolve vote if ended
    // vote ends when endDate is smaller than current block timestamp
    function resolveVote(uint _voteIndex) public {
        require(votes[_voteIndex].endDate <= block.timestamp, "Vote has not ended");
        require(isVoteInitialised(_voteIndex), "Vote is not initialized");
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
    function addVote(address _targetAddress, uint _target, uint _votingPeriod) public returns(int) {
        require(isAdmin(), "Only admin can add vote");
        require(_votingPeriod >= votePeriod, "Voting period is too short");
        int freeVoteIndex = getFreeVoteIndex();
        uint castedIndex = (uint) (freeVoteIndex) ;
        require(freeVoteIndex != -1, "No free vote index");
        uint voteId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _targetAddress, _target, _votingPeriod)));
        votes[castedIndex].id = voteId;
        votes[castedIndex].targetAddress = _targetAddress;
        votes[castedIndex].target = _target;
        votes[castedIndex].votingPeriod = _votingPeriod;
        votes[castedIndex].startDate = block.timestamp;
        votes[castedIndex].endDate = block.timestamp + _votingPeriod * DAY;
        emit VoteCreated(castedIndex);
        return freeVoteIndex;
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

    // checks if vote is initialisied
    function isVoteInitialised(uint voteIndex) private view returns(bool) {
        return votes[voteIndex].endDate != 0;
    }

    // establishes connection with library & gets the balance of caller
    // and the number of days the user have been hodling :)
    function getBalance() private returns(uint, uint) {
        return (1, 7);
    }
}

