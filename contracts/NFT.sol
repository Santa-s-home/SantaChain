// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin ERC721 implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SantaNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    uint256 public maxSupply;
    mapping(uint256 => string) private _tokenURIs;

    // ERC20 Token for rewards
    ERC20 public rewardToken;
    uint256 public rewardAmount;

    event CollectibleCreated(address indexed owner, uint256 indexed tokenId, string tokenURI);
    event CollectibleTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event OwnershipRenounced(address indexed previousOwner);
    event RewardClaimed(address indexed claimer, uint256 amount);
    event RoyaltySet(uint256 indexed tokenId, address indexed recipient, uint256 percentage);
    event RoyaltyPaid(address indexed recipient, uint256 amount);
    event Staked(address indexed staker, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 tokenId, uint256 timestamp);

    struct RoyaltyInfo {
        address recipient;
        uint256 percentage; // in basis points (e.g., 100 = 1%)
    }

    struct StakeInfo {
        address staker;
        uint256 timestamp;
    }

    mapping(uint256 => RoyaltyInfo) private _royalties;
    mapping(uint256 => StakeInfo) private _stakes;

    constructor(uint256 _maxSupply, address _rewardToken, uint256 _rewardAmount) ERC721("SantaNFT", "SANTA") {
        require(_maxSupply > 0, "Max supply must be greater than zero");
        require(_rewardToken != address(0), "Invalid reward token address");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");

        tokenCounter = 0;
        maxSupply = _maxSupply;
        rewardToken = ERC20(_rewardToken);
        rewardAmount = _rewardAmount;
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
        _payRoyalty(tokenId);
        emit CollectibleTransferred(msg.sender, to, tokenId);
    }

    function renounceOwnership() public onlyOwner {
        address previousOwner = owner();
        _transferOwnership(address(0));
        emit OwnershipRenounced(previousOwner);
    }

    function claimReward() public {
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Not enough reward tokens in contract");

        rewardToken.transfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function updateRewardAmount(uint256 newRewardAmount) public onlyOwner {
        require(newRewardAmount > 0, "Reward amount must be greater than zero");
        rewardAmount = newRewardAmount;
    }

    function setRoyalty(uint256 tokenId, address recipient, uint256 percentage) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(percentage <= 1000, "Royalty percentage too high"); // Max 10%
        _royalties[tokenId] = RoyaltyInfo(recipient, percentage);
        emit RoyaltySet(tokenId, recipient, percentage);
    }

    function _payRoyalty(uint256 tokenId) internal {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        if (royalty.recipient != address(0) && royalty.percentage > 0) {
            uint256 royaltyAmount = (rewardAmount * royalty.percentage) / 10000;
            rewardToken.transfer(royalty.recipient, royaltyAmount);
            emit RoyaltyPaid(royalty.recipient, royaltyAmount);
        }
    }

    function stake(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(_stakes[tokenId].staker == address(0), "Token is already staked");

        _stakes[tokenId] = StakeInfo({
            staker: msg.sender,
            timestamp: block.timestamp
        });

        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function unstake(uint256 tokenId) public {
        require(_stakes[tokenId].staker == msg.sender, "Caller is not the staker");

        delete _stakes[tokenId];

        emit Unstaked(msg.sender, tokenId, block.timestamp);
    }

    function getStakeInfo(uint256 tokenId) public view returns (StakeInfo memory) {
        return _stakes[tokenId];
    }
}
