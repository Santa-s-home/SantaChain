// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin ERC721 implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SantaNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    uint256 public maxSupply;
    mapping(uint256 => string) private _tokenURIs;

    event CollectibleCreated(address indexed owner, uint256 indexed tokenId, string tokenURI);

    constructor(uint256 _maxSupply) ERC721("SantaNFT", "SANTA") {
        require(_maxSupply > 0, "Max supply must be greater than zero");
        tokenCounter = 0;
        maxSupply = _maxSupply;
    }

    function createCollectible(string memory tokenURI) public onlyOwner returns (uint256) {
        require(tokenCounter < maxSupply, "Max supply reached");

        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        tokenCounter += 1;

        emit CollectibleCreated(msg.sender, newTokenId, tokenURI);

        return newTokenId;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function updateMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= tokenCounter, "New max supply must be greater than or equal to current supply");
        maxSupply = newMaxSupply;
    }

    function transferCollectible(address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _transfer(msg.sender, to, tokenId);
        emit CollectibleTransferred(msg.sender, to, tokenId);
    }

    function renounceOwnership() public onlyOwner {
        address previousOwner = owner();
        _transferOwnership(address(0));
        emit OwnershipRenounced(previousOwner);
    }
}
