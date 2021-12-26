pragma solidity ^0.8.0;




mapping (uint256 => string) proposalId;
mapping (uint256 => string) proposalType;  // map proposal id to proposal type
mapping (uint256 => uint256) proposalValue;  //Mapping of proposalId to proposalValue
mapping (address => uint256) numProposals; //
mapping (uint256 => string) proposalStage; //
mapping (uint256 => uint256) proposalInit;
mapping (uint256 => uint256)  proposalVoteBlock;
mapping (uint256 => uint256) proposalYes;
mapping (uint256 => uint256) proposalNo;
mapping (uint256 => mapping(address => bool)) Votecast;
address CDPaddress;


constructor(address CDP) public {
  proposalIdcounter = 0;
  CDPaddress = CDP
}

function propose(uint256 interest, string Type) public {
  Govtoken = GovTokenLike(Govtoken);
  require(Govtoken.balanceOf(msg.sender>=100));  //total supply 1 Mil tokens, minimum requirement = 0.01% of total supply
  proposalIdcounter+=1;
  numProposals[msg.sender] +=1;
  require(numProposals[msg.sender]<=100, 'too many proposals from this address'); // to discourage spam
  ProposalId = proposalIdcounter;
  proposalStage[ProposalId] = "DD"; // initalise with due diligence state
  proposalInit[proposalId] = block.number();
  proposalType[ProposalId] = Type;
}


function initiateVote(uint256 proposal) public returns (bool) {
  require(proposalStage[proposal] == "DD", 'proposal in incorrect stage');
  require(block.number() - proposalInitp[proposal] >= 2800, 'minimum DD time not elapsed'); // minimum 1 day in between proposal and initVote
  proposalStage[ProposalId] = "Voting";
  proposalVoteBlock[proposal] = block.number()
}



function vote(uint256 proposal, bool ballot) public returns (bool) {
  require(proposalStage[proposal] == "Voting", 'proposal not in voting stage');
  require(Votecast[proposal][msg.sender]!=True, 'vote already cast')
  Govtoken = GovTokenLike(Govtoken);
  voteBlock = proposalVoteBlock[proposal];
  require(block.number()-voteBlock <= 5600, 'voting concluded')
  num_votes = Govtoken.getPastVotes(msg.sender, voteBlock);
  if(ballot==True){
    proposalYes[proposal]+=num_votes
  }
  else{
    proposalNo[proposal]+=num_votes
  }
  Votecast[proposal][msg.sender]=True;
}


function executevote(uint256 proposal) public returns (bool){
  voteBlock = proposalVoteBlock[proposal];
  require(block.number()-voteBlock > 5600, 'voting not concluded')
  CDP=CDPlike(CDPaddress);
  if(proposalType[proposal]=="Interest"){
    CDP.
  }
  if(proposalType[proposal]=="ColRatio"){

  }
  proposalStage[ProposalId] = "Executed";



}
