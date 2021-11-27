//SPDX-License-Identifier:GPL-3.0


pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    
    address payable[]  public   players;
    address public manager;
    
    constructor(){
        manager = msg.sender;
        // players.push(manager); -> Challenge - 2
    }
    
    receive() external payable{
        
        //uint i=1; ->this consumes gas, be careful
        //i++;
        //require(msg.sender!= manager); -> Challenge - 1
        
        require(msg.value==0.1 ether,"SEND ONLY 0.1 ETH");
        players.push(payable(msg.sender));
        //NOTE THAT players IS A PAYABLE ADDRESSESS, SO CONVERT msg.sender TO PAYABLE
    }
    
    function balanceInWei() public view returns(uint){ 
     
        require(msg.sender == manager," YOU ARE NOT THE MANAGER");
        return address(this).balance;
    }
    
    function random() public view returns(uint){
         return  uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length))); 
    }
    
    function pickWinner() public{
        require(msg.sender==manager, "ACCESS DENIED, YOU ARE NOT THE MANAGER");
        require(players.length>=3,"NoT ENOUGH PLAYERS");
        //require(players.length>=3,"NoT ENOUGH PLAYERS"); -> Challenge -3
        
        uint r = random();
        address payable winner;
        
        uint index = r%players.length;
        winner =  players[index];
        
        winner.transfer(address(this).balance);
        
        players = new address payable[](0);//resetting the lottery
    }
    
    
}