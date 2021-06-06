pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "./ctenaPriceFeed.sol";

contract ctenaFarm {
    ctenaPriceFeed priceFeed = new ctenaPriceFeed();
    IERC20 private CTENA;
    IERC20 private WCTENA;
    address private Owner;
    
    address[] public stakers;
    mapping(address=> uint256) public stakingBalance;
    mapping(address=>bool) public hasStaked;
     mapping(address=>bool) public isStaked;
    
    constructor(address ctenaAddress, address wCtenaAddress) public{
        CTENA = IERC20(ctenaAddress);
        WCTENA = IERC20(wCtenaAddress);
        Owner = msg.sender;
        
    }
    
    function stakeCTENA(uint256 _amount) public {
        uint256 balanceStaker = CTENA.balanceOf(msg.sender);
        require(_amount<=balanceStaker, "l'importo inserito eccede il tuo balance");
        CTENA.approve(address(this),_amount);
        CTENA.transferFrom(msg.sender, address(this),_amount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender]+ _amount;
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
        }
        
        hasStaked[msg.sender] = true;
        isStaked[msg.sender] = true;
    }
    
    
    function farmingWCTENA() private {
        require(msg.sender== Owner,"aia, non sei l'owner ");
        for(uint256 i=0;i<stakers.length;i++){
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            if(balance>0){
                WCTENA.transfer(recipient, getUserTotalValue(recipient));
            }
        }
    }
    
    function getUserTotalValue(address user) public returns (uint256) {
       uint256 totalValue = 0;
               totalValue =
                   totalValue +
                   getUserStakingBalanceCTENAValue(user);
           
       
       return totalValue;
   }
   
   function getUserStakingBalanceCTENAValue(address user) public returns (uint256) {
      
       return (stakingBalance[user] * getTokenCTENAPrice()) / (10**18);
   }
   
   
   function getTokenCTENAPrice() public returns ( uint256){
       bytes32 requestId = priceFeed.request();
       
       return priceFeed.getPrice();
   }
   
   
   function withdrawBNB() external {
       uint256 contractBalance = address(this).balance;
        msg.sender.call{value: contractBalance}("");
   }
    
}
