// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EchoXInterfaces.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract EchoXPool is ReentrancyGuard {
    struct Pool {
        address nftAddress;
        uint256 currentPrice;
        uint256 liquidity;
        uint256 feePercentage;
        address creator;
    }
    
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(uint256 => address)) public nftOwners;
    mapping(uint256 => mapping(address => uint256)) public liquidityProviderShares;
    
    uint256 public nextPoolId;
    address public owner;
    
    IERC20 public ex;
    IEchoXPoints public points;
    
    event PoolCreated(uint256 indexed poolId, address indexed creator, address nftAddress, uint256 initialLiquidity);
    event LiquidityAdded(uint256 indexed poolId, address indexed provider, uint256 amount);
    event NFTPurchased(uint256 indexed poolId, address indexed buyer, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed poolId, address indexed seller, uint256 tokenId, uint256 price);
    event LiquidityWithdrawn(uint256 indexed poolId, address indexed user, uint256 amount);
    
    constructor(address exTokenAddress, address pointsAddress) {
        ex = IERC20(exTokenAddress);
        points = IEchoXPoints(pointsAddress);
        owner = msg.sender;
    }
    
    function createPool(
        address nftAddress,
        uint256 initialLiquidity,
        uint256 initialPrice,
        uint256 feePercentage
    ) external nonReentrant {
        require(feePercentage <= 10000, "Fee too high");
        require(initialLiquidity > 0, "Zero liquidity");
        
        ex.transferFrom(msg.sender, address(this), initialLiquidity);
        
        pools[nextPoolId] = Pool({
            nftAddress: nftAddress,
            currentPrice: initialPrice,
            liquidity: initialLiquidity,
            feePercentage: feePercentage,
            creator: msg.sender
        });
        
        liquidityProviderShares[nextPoolId][msg.sender] += initialLiquidity;
        
        try points.recordPoolCreation(msg.sender) {
            
        } catch {
            
        }
        
        emit PoolCreated(nextPoolId, msg.sender, nftAddress, initialLiquidity);
        nextPoolId++;
    }
    
    function addLiquidity(uint256 poolId, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Pool storage pool = pools[poolId];
        ex.transferFrom(msg.sender, address(this), amount);
        pool.liquidity += amount;
        liquidityProviderShares[poolId][msg.sender] += amount;
        
        try points.recordLpParticipation(msg.sender, address(this)) {
            
        } catch {
            
        }
        
        emit LiquidityAdded(poolId, msg.sender, amount);
    }
    
    function buyNFT(uint256 poolId, uint256 tokenId) external nonReentrant {
        Pool storage pool = pools[poolId];
        uint256 fee = (pool.currentPrice * pool.feePercentage) / 10000;
        uint256 totalCost = pool.currentPrice + fee;
        
        address currentOwner = IERC721(pool.nftAddress).ownerOf(tokenId);
        require(currentOwner != address(0), "Invalid NFT owner");
        
        ex.transferFrom(msg.sender, address(this), totalCost);
        IERC721(pool.nftAddress).transferFrom(currentOwner, msg.sender, tokenId);
        
        pool.liquidity += pool.currentPrice;
        
        try points.recordPoolTransaction(pool.creator) {
            
        } catch {
            
        }
        
        emit NFTPurchased(poolId, msg.sender, tokenId, pool.currentPrice);
    }
    
    function sellNFT(uint256 poolId, uint256 tokenId) external nonReentrant {
        Pool storage pool = pools[poolId];
        require(pool.liquidity >= pool.currentPrice, "Insufficient pool liquidity");
        
        IERC721(pool.nftAddress).transferFrom(msg.sender, address(this), tokenId);
        ex.transfer(msg.sender, pool.currentPrice);
        
        pool.liquidity -= pool.currentPrice;
        
        try points.recordPoolTransaction(pool.creator) {
            
        } catch {
            
        }
        
        emit NFTSold(poolId, msg.sender, tokenId, pool.currentPrice);
    }
    
    function withdrawLiquidity(uint256 poolId, uint256 amount) external nonReentrant {
        require(amount > 0, "Zero amount");
        require(liquidityProviderShares[poolId][msg.sender] >= amount, "Insufficient share");
        
        Pool storage pool = pools[poolId];
        require(pool.liquidity >= amount, "Pool liquidity low");
        
        liquidityProviderShares[poolId][msg.sender] -= amount;
        pool.liquidity -= amount;
        
        ex.transfer(msg.sender, amount);
        
        emit LiquidityWithdrawn(poolId, msg.sender, amount);
    }
    
    function updatePointsContract(address newAddress) external {
        require(msg.sender == owner, "Only owner");
        points = IEchoXPoints(newAddress);
    }
    
    function updateEXToken(address newAddress) external {
        require(msg.sender == owner, "Only owner");
        ex = IERC20(newAddress);
    }
}
