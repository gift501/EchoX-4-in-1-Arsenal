// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EchoXPoints {
    address public owner;
    
    mapping(address => uint256) public userPoints;
    mapping(address => uint256[]) public dailySwapTimestamps;
    mapping(address => uint256) public referralTaskCompleted;
    mapping(address => uint256) public referredUsers;
    mapping(address => uint256) public poolCreatedCount;
    mapping(address => uint256) public memeCreatedCount;
    mapping(address => uint256) public memeTxCount;
    mapping(address => uint256) public poolTxCount;
    mapping(address => uint256) public userPoolParticipation;
    mapping(address => bool) public lp3ChallengeCompleted;
    mapping(address => bool) public swap5DaysCompleted;
    
    mapping(address => bool) public authorizedContracts;
    
    event PointsAdded(address indexed user, uint256 amount, string reason);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractAuthorized(address indexed contractAddress);
    event ContractDeauthorized(address indexed contractAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == owner || authorizedContracts[msg.sender], "Not authorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function _addPoints(address user, uint256 amount, string memory reason) internal {
        userPoints[user] += amount;
        emit PointsAdded(user, amount, reason);
    }
    
    function getPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function authorizeContract(address contractAddress) external onlyOwner {
        authorizedContracts[contractAddress] = true;
        emit ContractAuthorized(contractAddress);
    }
    
    function deauthorizeContract(address contractAddress) external onlyOwner {
        authorizedContracts[contractAddress] = false;
        emit ContractDeauthorized(contractAddress);
    }
    
    function recordNftForExSwap(address user) external onlyAuthorized {
        _addPoints(user, 5, "NFT-for-EX Swap");
    }
    
    function recordNftForNftSwap(address user) external onlyAuthorized {
        _addPoints(user, 5, "NFT-for-NFT Swap");
    }
    
    function recordReferralTaskCompletion(address referrer, address referredUser) external onlyAuthorized {
        referralTaskCompleted[referredUser]++;
        if (referralTaskCompleted[referredUser] >= 3) {
            referredUsers[referrer]++;
            _addPoints(referrer, 3, "Referral Milestone (3 Tasks)");
        }
    }
    
    function recordBatchSwap(address user, uint256 nftCount) external onlyAuthorized {
        if (nftCount >= 5) {
            _addPoints(user, 6, "Batch NFT Swap (5+ NFTs)");
        }
    }
    
    function recordLpParticipation(address user, address pool) external onlyAuthorized {
        if (userPoolParticipation[user] < 3) {
            userPoolParticipation[user]++;
            if (userPoolParticipation[user] == 3 && !lp3ChallengeCompleted[user]) {
                _addPoints(user, 7, "LP in 3+ Pools");
                lp3ChallengeCompleted[user] = true;
            }
        }
    }
    
    function recordDailySwap(address user) external onlyAuthorized {
        dailySwapTimestamps[user].push(block.timestamp);
        uint256 count = 0;
        for (uint256 i = 0; i < dailySwapTimestamps[user].length; i++) {
            if (block.timestamp - dailySwapTimestamps[user][i] <= 5 days) {
                count++;
            }
        }
        if (count >= 5 && !swap5DaysCompleted[user]) {
            _addPoints(user, 10, "5-Day Swap Streak");
            swap5DaysCompleted[user] = true;
        }
        _addPoints(user, 2, "Daily Swap");
    }
    
    function recordPoolCreation(address user) external onlyAuthorized {
        poolCreatedCount[user]++;
        _addPoints(user, 3, "Pool Created (100 USDT + 500M Meme)");
    }
    
    function recordPoolTransaction(address poolCreator) external onlyAuthorized {
        poolTxCount[poolCreator]++;
        _addPoints(poolCreator, 1, "Pool Transaction");
    }
    
    function recordMemeCreation(address user) external onlyAuthorized {
        memeCreatedCount[user]++;
        _addPoints(user, 10, "Meme Created (1B Supply)");
    }
    
    function recordMemeTransaction(address memeCreator) external onlyAuthorized {
        memeTxCount[memeCreator]++;
        _addPoints(memeCreator, 3, "Meme Swap");
    }
    
    function recordDexAggregatorTrade(address user, uint256 amountUsd) external onlyAuthorized {
        if (amountUsd >= 50 * 1e18) {
            _addPoints(user, 10, "DEX Aggregator Trade ($50+)");
        } else {
            _addPoints(user, 5, "DEX Aggregator Trade (<$50)");
        }
    }
    
    function giveBonus(address user, uint256 amount, string calldata reason) external onlyAuthorized {
        _addPoints(user, amount, reason);
    }
}
