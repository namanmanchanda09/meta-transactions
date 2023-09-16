// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "solmate/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


/**
    Receiver NFT contract that implements the ERC2771Context standard
    Minimal implementation of BAYC contract - only considering the mintTo fn for testing
 */
contract MinimalBAYC is ERC721, ERC2771Context {
    uint256 public currentTokenId;
    uint256 public constant apePrice = 10000000000000000; //0.08 ETH
    uint256 public MAX_APES;

    constructor(string memory _name, string memory _symbol, uint256 maxNftSupply, address trustedForwarder)
        ERC721(_name, _symbol)
        ERC2771Context(trustedForwarder)
    {
        MAX_APES = maxNftSupply;
    }

    /**
        calls the ERC2771Context's _msgSender to verify sender
        and mints to the original sender of the transaction
     */
    function mintTo(uint256 numberOfTokens) public payable returns (uint256) {
        // checks if the transaction request is from a trusted forwarder
        address sender = _msgSender();

        require(apePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        uint256 newItemId;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            newItemId = ++currentTokenId;
            if (newItemId < MAX_APES) {
                _safeMint(sender, newItemId);
            }
        }
        return newItemId;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }
}


