// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin ERC721 implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SantaNFT is ERC721, Ownable {
    uint256 public tokenCounter;

    constructor() ERC721("SantaNFT", "SANTA") {
        tokenCounter = 0;
    }

    function createCollectible() public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        tokenCounter += 1;
        return newTokenId;
    }

}
