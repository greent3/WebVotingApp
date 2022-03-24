// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    struct Voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote; //index of the voted proposal
    }

    struct Proposal{
        bytes32 name;
        uint voteCount; //number of accumulated votes
    }

    address public proposer;
    mapping (address => Voter) public voters;
    Proposal[] public proposals;
    uint256 deadline;

    constructor(bytes32[] memory proposalNames, uint256 numberOfDays) {
        proposer = msg.sender;
        voters[proposer].weight = 1;
        deadline = now + (numberOfDays * 1 days);

        for (uint i = 0; i < proposalNames.length; ++i){
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public {
        require(msg.sender == proposer, "Only proposer can assign right to vote");
        require(!voters[voter].voted, "This voter already voted");
        require((voters[voter].weight == 0), "This voter already has the right to vote");
        require(now <= deadline); //ensure deadline hasn't passed
        voters[voter].weight = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "This voter already used their vote");
        require(to != msg.sender, "You can't delegate to yourself");
        require(now <= deadline); //ensure deadline hasn't passed

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;

        Voter storage personDelegatedTo = voters[to];

        if(personDelegatedTo.voted) {
            proposals[personDelegatedTo.vote].voteCount += personDelegatedTo.weight;
        }
        else {
            personDelegatedTo.weight += sender.weight;
        }
    }

    function vote(uint proposal) public {
        Voter storage currVoter = voters[msg.sender];
        require(!currVoter.voted, "Already voted");
        require(currVoter.weight != 0, "Has no right to vote");
        require(now <= deadline); //ensure deadline hasn't passed
        currVoter.voted = true;
        currVoter.vote = proposal;
        proposals[proposal].voteCount += currVoter.weight;
    }

    function winningProposal() public view returns (uint winningProposalNumber){
        uint currentMax = 0;
        for(uint i = 0; i < proposals.length; ++i){
            if(proposals[i].voteCount > currentMax) {
                currentMax = proposals[i].voteCount;
                winningProposalNumber = i;
            }
        }
    }


    function winnerName() public view returns (bytes32 _winnerName){
        _winnerName = proposals[winningProposal()].name;
    }

}