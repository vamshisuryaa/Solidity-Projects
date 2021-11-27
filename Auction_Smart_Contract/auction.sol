//SPDX-License-Identifier:GPL-3.0


pragma solidity >=0.5.0 <0.9.0;


contract AuctionCreator{
    address public owner;
    Auction[] public auctions;
    constructor(){
        owner = msg.sender;
    }
    
    function CreateAuction() public{
        
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}




contract Auction{
    
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
      
    enum State{Started,Running,Ended,Cancelled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address=> uint) public bids;
    
    uint bidIncrement;
    
    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;//No. of seconds in a week / 15
        ipfsHash = "";
        bidIncrement = 100;
    }
    
    modifier notOwner(){
        require(msg.sender !=owner, "OWNER SHOULD'NT PARTICIPATE");
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock );
        _;
    }
    
    modifier beforeEnd(){
        require(block.number < endBlock);
        _;
    }
    
     modifier onlyOwner(){
        require(msg.sender == owner, "YOU ARE NOT THE OWNER");
        _;
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if(a<=b){
            return a;
        }
        else{ 
            return b;
        }
    }
    
    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd{
     
     require(auctionState == State.Running,"AUCTION IS ENDED OR WAS CANCELLED");
     require(msg.value >=100, "MIN 100 WEI");
     
     uint currentBid = bids[msg.sender] + msg.value;
     require(currentBid > highestBindingBid,"BID MORE");
     
     bids[msg.sender] = currentBid;
     
     if(currentBid <= bids[highestBidder]){
         highestBindingBid = min(currentBid+bidIncrement,bids[highestBidder]);
     }
     else{
         highestBindingBid=min(currentBid,bids[highestBidder]+bidIncrement);
         highestBidder = payable(msg.sender);
     }
    }
    
    function finalizeAuction() public{
        require(auctionState==State.Cancelled || block.number > endBlock );
        require(msg.sender == owner || bids[msg.sender]>0); //Either owner or bidder can finalize auction
        
        
        address payable recipient;
        uint value;
        
        if(auctionState == State.Cancelled){//Auction was cancelled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{ //Auction Ended not cancelled
          if(msg.sender==owner){//This is the owner
              recipient = owner;
              value = highestBindingBid;
          }else{// This is a bidder
              if(msg.sender == highestBidder)
              {
                  recipient = highestBidder;
                  value = bids[highestBidder]- highestBindingBid; 
              }
              else{ //Neither owner nor a highest bidder
                  recipient = payable(msg.sender);
                    value = bids[msg.sender];
              }
          }
           
        }
        //resetting bids of recipient to 100
        bids[recipient ]=0;
        
        recipient.transfer(value);
    
    }
    
    
     
}