pragma solidity ^0.6.0;

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract ctenaPriceFeed is ChainlinkClient {
    uint256 public price;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    constructor() public {
        setPublicChainlinkToken();
        //oracle = "Address chaninlink oracle";
        //jobId = "job id per http get"
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        
    }
    
    function request() public returns(bytes32 requestId){
        string memory url = "";
        string memory path = "";
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this),this.response.selector);
        
        req.add("get", url);
        req.add("path", path);
        
        return sendChainlinkRequestTo(oracle,req,fee);
    }
    
    function response(bytes32 _requestId,uint256 _price) public recordChainlinkFulfillment(_requestId) {
        price = _price;
    }
    
    function getPrice() public view returns(uint256){
        return price;
    }
    
    
    function withdrawLink() private {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender,linkToken.balanceOf(address(this))),"non ci sono fondi");
    }
}
