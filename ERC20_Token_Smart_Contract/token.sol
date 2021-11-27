//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
// -----------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    //For a functional token that can be transfereed between accounts only 3 functions are sufficient
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface{
            
         string public name = "Cryptos";   //Name of the token
         string public symbol = "CRPT";    // Symbol like stock ticker
         uint  public decimals = 0;       //18 is the most used for decimal state variable
         uint public override totalSupply;
         
         address public founder;
         mapping(address => uint) public balances;
         //balance[0x1111....]=100; -> This is how the contract stores the tokens of each address 

        mapping(address => mapping(address=> uint))  allowed;
        
        //0x1111....(owner)  allows 0x2222.... (the spender) ------ 100 tokens
        //allowed[0x111][0x222] = 100;
  
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
       return balances[tokenOwner]; 
    }
    
     function transfer(address to, uint tokens) public virtual override returns (bool success){
        require(balances[msg.sender]>tokens,"NOT ENOUGH TOKENS");
        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        emit Transfer(msg.sender,to,tokens);
        
        return true;
     }
     
     function allowance(address tokenOwner, address tokenSpender) view public override returns(uint){
          return allowed[tokenOwner][tokenSpender];
     }
     
      function approve(address spender, uint tokens) public  override returns(bool success){
          require(balances[msg.sender] >= tokens);
          require(tokens>0);
          
          allowed[msg.sender][spender]=tokens;
          
          emit Approval(msg.sender,spender,tokens);
          
          return true;
      }
      
       function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
           require(tokens<= allowed[from][to]);
           require(balances[from]>=tokens);
           balances[from] -=tokens;
           balances[to]+=tokens;
           allowed[from][to]-=tokens;
           
           return true;
           
       }
}


contract CryptosICO  is Cryptos{
    
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // 1eth == 1000 CRPT, 1CRPT = 0.001ETH
    uint public hardCap = 300 ether;
    uint public raisedAmount;// in wei
    uint public saleStart = block.timestamp;//+3600 for ICO to start in 1hour
    uint public saleEnd = block.timestamp + 604800; // ICO ends in one weeks
    uint public tokenTradeStart = saleEnd + 604800; //transferable in a week after sale end
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State {beforeStart, Running, afterEnd, halted}
    
    State  public icoState; 
    
    
    constructor(address payable _deposit){
        
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    
    modifier onlyAdmin(){
        require(admin ==msg.sender,"YOU ARENT THE ADMIN");
        _;
    }
    
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function resume() public onlyAdmin{
        icoState= State.Running;
    }
    
    function changeDepositAddress(address payable _newDepositAddress)public onlyAdmin{
        deposit = _newDepositAddress;
    }
    
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        } 
        else if(block.timestamp < saleStart) {
            return State.beforeStart;
        }
        else if(block.timestamp >= saleStart && block.timestamp <=saleEnd){
            return State.Running;
        }
        
        else{
            return State.afterEnd;
        }
    }
    
    
    event Invest(address investor, uint value, uint tokens);
    function invest() payable public returns(bool){
        require(getCurrentState() == State.Running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value/tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value);
        
        emit Invest(msg.sender, msg.value,tokens);
    
        return true;
    }
    
    receive() payable external{
        invest();
    }
        
     function transfer(address to, uint tokens) public override returns (bool success){
      require(block.timestamp > tokenTradeStart);
      Cryptos.transfer(to,tokens);// super.transfer(to,tokens); -> or we can use keyword super
      return true;
     }
     
     
      function transferFrom(address from, address to, uint tokens) public override returns (bool success){
      require(block.timestamp > tokenTradeStart);
      Cryptos.transferFrom(from,to,tokens);  return true;
      }
      
      function burn() public returns(bool){
          icoState = getCurrentState();
          require(icoState==State.afterEnd);
          balances[founder]=0;
          
          return true;
      }
    
    
}