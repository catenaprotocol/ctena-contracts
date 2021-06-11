// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title A simple smart contract which only records everyone’s voting on each proposal.
 */
contract CatenaVoting {
    using SafeMath for uint256;

    // Meta data
    struct Meta {
        uint256 beginBlock;
        uint256 endBlock;
    }

    // Vote content
    enum Content { INVALID, FOR, AGAINST }

    // Min CATENA rate of totalSupply for creating a new proposal
    uint256 public constant MIN_PROPOSAL_RATE = 10**16; // 1% according to https://github.com/mcdexio/documents/blob/master/en/Mai-Protocol-v3.pdf

    // Min voting period in blocks. 1 day for 15s/block
    uint256 public constant MIN_PERIOD = 5760;

    // MCB address
    IERC20 public ctn;

    // All proposal meta data
    Meta[] public proposals;

    // Compatible with the old VoteBox
    uint256 public constant PROPOSAL_ID_OFFSET = 20;

    /**
     * @dev The new proposal is created
     */
    event Proposal(uint256 indexed id, string link, uint256 beginBlock, uint256 endBlock);

    /**
     * @dev Someone changes his/her vote on the proposal
     */
    event Vote(address indexed voter, uint256 indexed id, Content voteContent);

    /**
     * @dev    Constructor
     * @param  ctnAddress Catena address
     */
    constructor(address ctnAddress)
        public
    {
        ctn = IERC20(ctnAddress);
        for (uint i = 0; i < PROPOSAL_ID_OFFSET; i++) {
            proposals.push(Meta({
                beginBlock: 0,
                endBlock: 0
            }));
        }
    }

    /**
     * @dev    Accessor to the total number of proposal
     */
    function totalProposals()
        external view returns (uint256)
    {
        return proposals.length;
    }

    /**
     * @dev    Create a new proposal, need a proposal privilege
     * @param  title       description of proposal
     * @param  description       description of proposal
     * @param  beginBlock Voting is enabled between [begin block, end block]
     * @param  endBlock   Voting is enabled between [begin block, end block]
     */
    function propose(string calldata title, string calldata description, uint256 beginBlock, uint256 endBlock)
        external
    {
        uint256 minProposalCTN = ctn.totalSupply().mul(MIN_PROPOSAL_RATE).div(10**18);
        require(ctn.balanceOf(msg.sender) >= minProposalCTN, "proposal privilege required");
        require(bytes(description).length > 0, "empty description");
        require(bytes(title).length > 0, "empty title");
        require(block.number <= beginBlock, "old proposal");
        require(beginBlock.add(MIN_PERIOD) <= endBlock, "period is too short");
        proposals.push(Meta({
            beginBlock: beginBlock,
            endBlock: endBlock
        }));
        emit Proposal(proposals.length - 1, title, description, beginBlock, endBlock);
    }

    /**
     * @notice  Vote for/against the proposal with id
     * @param   id          Proposal id
     * @param   voteContent Vote content
     */
    function vote(uint256 id, Content voteContent)
        external
    {
        require(id < proposals.length, "invalid id");
        require(voteContent != Content.INVALID, "invalid content");
        require(proposals[id].beginBlock <= block.number, "< begin");
        require(block.number <= proposals[id].endBlock, "> end");
        emit Vote(msg.sender, id, voteContent);
    }
}
