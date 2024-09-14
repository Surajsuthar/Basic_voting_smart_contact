// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Vote {
    address electionComision;

    address public winner;

    struct Voter {
        string name;
        uint256 age;
        uint256 voterId;
        string gender;
        uint256 voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint256 age;
        string gender;
        uint256 candidateId;
        address candidateAddress;
        uint256 votes;
    }

    uint256 nextVoterId = 1; 
    uint256 nextCandidateId = 1; 

    uint256 startTime; 
    uint256 endTime; 

    mapping(uint256 => Voter) voterDetails; 
    mapping(uint256 => Candidate) candidateDetails; 

    bool stopVoting; //this for emergency situtation to stop voting

    constructor() {
        electionComision = msg.sender; 
    }

    modifier isVotingOver() {
        require(
            block.timestamp > endTime || stopVoting == true,
            "Voting is not over"
        );

        _;
    }

    modifier onlyCommisioner() {
        require(electionComision == msg.sender, "Not from election commision");

        _;
    }

    //Assume we are not going to register more than 2 candidates

    function candidateRegister(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        string calldata _gender
    ) external {
        require(
            msg.sender != electionComision,
            "You are from election commision"
        );

        require(
            candidateVerification(msg.sender) == true,
            "Candidate Already Registered"
        );

        require(_age >= 18, "You are not eligible");

        require(nextCandidateId < 3, "Candidate Registration Full");

        candidateDetails[nextCandidateId] = Candidate(
            _name,
            _party,
            _age,
            _gender,
            nextCandidateId,
            msg.sender,
            0
        );

        nextCandidateId++;
    }

    function candidateVerification(address _person)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _person) {
                return false; 
            }
        }
        return true; 
    }

    function candidateList() public view returns (Candidate[] memory) {
 
        Candidate[] memory array = new Candidate[](nextCandidateId - 1); 

        for (uint256 i = 1; i < nextCandidateId; i++) {
            array[i - 1] = candidateDetails[i];
        }

        return array;
    }

    function voterRegister(
        string calldata _name,
        uint256 _age,
        string calldata _gender
    ) external {
        require(
            voterVerification(msg.sender) == true,
            "Voter Already Registered"
        );

        require(_age >= 18, "You are not eligible");

        voterDetails[nextVoterId] = Voter(
            _name,
            _age,
            nextVoterId,
            _gender,
            0,
            msg.sender
        );

        nextVoterId++;
    }

    function voterVerification(address _person) internal view returns (bool) {
        for (uint256 i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voterAddress == _person) {
                return false; 
            }
        }
        return true; 
    }

    function voterList() public view returns (Voter[] memory) {
        Voter[] memory array = new Voter[](nextVoterId - 1);

        for (uint256 i = 1; i < nextVoterId; i++) {
            array[i - 1] = voterDetails[i];
        }

        return array;
    }

    function vote(uint256 _voterId, uint256 _id) external {
        require(voterDetails[_voterId].voteCandidateId == 0, "Already voted");

        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "You are not a voter"
        );

        require(startTime != 0, "Voting not started");

        require(nextCandidateId == 3, "Canidate registration not done yet");

        require(_id > 0 && _id < 3, "Invalid Canidate Id");

        voterDetails[_voterId].voteCandidateId = _id;

        candidateDetails[_id].votes++;
    }

    function voteTime(uint256 _startTime, uint256 _endTime)
        external
        onlyCommisioner
    {
        startTime = block.timestamp + _startTime; 

        endTime = startTime + _endTime; 
    }

    function votingStatus() public view returns (string memory) {
        if (startTime == 0) {
            return "Voting has not started";
        } else if (
            (startTime != 0 && endTime > block.timestamp) && stopVoting == false
        ) {
            return "In progress";
        } else {
            return "Ended";
        }
    }

    function result() external onlyCommisioner {
        require(nextCandidateId > 1, "No candidates registered");

        // require(checkStatus(),"Voting has either not started or in progress");

        uint256 maximumVotes = 0;

        address currentWinner;

        for (uint256 i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maximumVotes) {
                maximumVotes = candidateDetails[i].votes;

                currentWinner = candidateDetails[i].candidateAddress;
            }
        }

        winner = currentWinner;
    }

    function emergency() public onlyCommisioner {
        stopVoting = true;
    }
}
