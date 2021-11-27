//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Crowdfunding{
    
    mapping(address => uint) public  contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minContribution;
    uint public deadline;//Timestamp
    uint public goal;
    uint public raisedAmount;
    
    mapping(uint =>Request) public requests;
    uint public numRequests; //This is required for index as they cant have array like indices
    
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

        
    constructor(uint _goal, uint _deadline){
        
        goal =_goal;
        deadline = block.timestamp + _deadline;
        minContribution = 100;
        admin = msg.sender;
    }
    
    modifier onlyAdmin(){
        require(admin==msg.sender,"YOU ARENT THE ADMIN");
        _;
    }
    
    receive() payable external{
        contribute();
    }
    
    event ContributeEvent(address sender, uint value);
    event  CreateRequestEvent(string _description,address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    function contribute() public payable{
        require(block.timestamp<deadline,"DEADLINE HAS PASSED");
        require(msg.value>=minContribution,"MIN CONTRIBUTION NOT MET");
        if(contributors[msg.sender]==0){
           numberOfContributors++; 
        }
            contributors[msg.sender] += msg.value;  
            raisedAmount+=msg.value;
            
           emit ContributeEvent(msg.sender,msg.value);
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getRefund() public{
        require(block.timestamp > deadline && raisedAmount < goal );
        require(contributors[msg.sender]>0);
    
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        recipient.transfer(value);
        
        contributors[msg.sender]=0;
    } 
    
    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        
        newRequest.description =_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.numberOfVoters = 0;
        
        emit CreateRequestEvent(_description,_recipient,_value);
        
    }
    
    function VoteRequest(uint _requestNo) public{
          //only a contributor can vote for a requests
         require(contributors[msg.sender] > 0, "YOU ARE NOT A CONTRIBUTOR"); 
         Request storage thisRequest = requests[_requestNo]; 
    
        require(thisRequest.voters[msg.sender]==false,"YOU ALREADY VOTED");
        
        thisRequest.voters[msg.sender]= true;
        thisRequest.numberOfVoters++;
    }
    
    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount>=goal,"GOAL NOT REACHED");
        
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "ALREADY COMPLETED");
        
        require(thisRequest.numberOfVoters > numberOfContributors/2);//50% VOTED FOR THE REQUEST
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed == true;
        
        emit MakePaymentEvent(thisRequest.recipient,thisRequest.value);
    }
    
    
    
    
    
}
    
    
    