// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EchoXInterfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PriceTracking.sol";
import "./CommunityReactions.sol";

contract MemeFactory is ReentrancyGuard {
    address public owner;
    address public echoXPoints;
    address public constant EXTUSDT = 0x32741811ceA2B5F50F288053b90891426a11199c;

    IPriceTracking public priceTracker;
    ICommunityReactions public communityReactions;

    struct MemeTokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        string logo;
        address creator;
        uint256 extusdtReserve;
        uint256 memeReserve;
        bool poolCreated;
    }

    MemeTokenInfo[] public memeTokens;

    mapping(address => uint256) public dailyBuyAmount;
    mapping(address => uint256) public dailySellAmount;
    mapping(address => uint256) public lastBuyTimestamp;
    mapping(address => uint256) public lastSellTimestamp;

    mapping(address => mapping(uint256 => uint256)) public lpTokens;
    mapping(uint256 => uint256) public totalLpTokens;

    uint256 public constant DAILY_BUY_LIMIT_MEME = 10_000 * 10**18;
    uint256 public constant DAILY_SELL_LIMIT_MEME = 5_000 * 10**18;
    uint256 public constant INITIAL_MEME_SUPPLY = 100_000_000 * 10**18;
    uint256 public constant INITIAL_POOL_EXTUSDT = 100_000_000 * 10**18;
    uint256 public constant INITIAL_POOL_MEME = 100_000_000 * 10**18;
    uint256 public constant SWAP_FEE_PERCENT = 3;

    event MemeTokenCreated(address indexed tokenAddress, string name, string symbol, string logo, address indexed creator);
    event MemeCreated(address indexed creator, uint256 amount);
    event MemeTransaction(address indexed creator, uint256 amount, string txType);
    event LiquidityPoolCreated(address indexed initiator, address indexed tokenAddress, uint256 extusdtAmount, uint256 memeAmount);
    event LiquidityAdded(address indexed provider, address indexed tokenAddress, uint256 extusdtAmount, uint256 memeAmount);
    event LiquidityRemoved(address indexed provider, address indexed tokenAddress, uint256 extusdtAmount, uint256 memeAmount);
    event TokenSwap(address indexed user, address indexed tokenAddress, uint256 amountIn, uint256 amountOut, bool isExtusdtToMeme);
    event MemeReactionUpdated(uint256 indexed memeIndex, bool isUpvote, bool isComment, bool isEmoji, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier validMemeIndex(uint256 memeIndex) {
        require(memeIndex < memeTokens.length, "Invalid meme index");
        _;
    }

    constructor(address _echoXPoints, address _priceTracker, address _communityReactions) {
        echoXPoints = _echoXPoints;
        owner = msg.sender;
        priceTracker = IPriceTracking(_priceTracker);
        communityReactions = ICommunityReactions(_communityReactions);
    }

    function updatePointsContract(address _newPointsAddress) external onlyOwner {
        echoXPoints = _newPointsAddress;
    }

    function updatePriceTrackerContract(address _newPriceTrackerAddress) external onlyOwner {
        priceTracker = IPriceTracking(_newPriceTrackerAddress);
    }

    function updateCommunityReactionsContract(address _newCommunityReactionsAddress) external onlyOwner {
        communityReactions = ICommunityReactions(_newCommunityReactionsAddress);
    }

    function updateMemeReactionStats(uint256 memeIndex, bool isUpvote, bool isComment, bool isEmoji) external {
        require(msg.sender == address(communityReactions), "Only CommunityReactions can call this");
        require(memeIndex < memeTokens.length, "Invalid meme index");
        
        emit MemeReactionUpdated(memeIndex, isUpvote, isComment, isEmoji, block.timestamp);
        
    }

    function createMemeToken(
        string memory _name,
        string memory _symbol,
        string memory _logo
    ) external returns (address) {
        MemeToken newToken = new MemeToken(_name, _symbol, msg.sender, INITIAL_MEME_SUPPLY);
        address tokenAddress = address(newToken);

        MemeTokenInfo memory newTokenInfo = MemeTokenInfo({
            tokenAddress: tokenAddress,
            name: _name,
            symbol: _symbol,
            logo: _logo,
            creator: msg.sender,
            extusdtReserve: 0,
            memeReserve: 0,
            poolCreated: false
        });

        memeTokens.push(newTokenInfo);

        try IEchoXPoints(echoXPoints).recordMemeCreation(msg.sender) {
        } catch {
        }

        emit MemeTokenCreated(tokenAddress, _name, _symbol, _logo, msg.sender);
        emit MemeCreated(msg.sender, INITIAL_MEME_SUPPLY);

        return tokenAddress;
    }

    function createLiquidityPool(uint256 memeIndex) external nonReentrant validMemeIndex(memeIndex) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        require(!memeToken.poolCreated, "Pool already created");

        require(IERC20(EXTUSDT).transferFrom(msg.sender, address(this), INITIAL_POOL_EXTUSDT), "EXTUSDT transfer failed");
        require(IERC20(memeToken.tokenAddress).transferFrom(msg.sender, address(this), INITIAL_POOL_MEME), "Meme token transfer failed");

        memeToken.extusdtReserve = INITIAL_POOL_EXTUSDT;
        memeToken.memeReserve = INITIAL_POOL_MEME;
        memeToken.poolCreated = true;

        uint256 lpTokenAmount = 100 * 10**18;
        lpTokens[msg.sender][memeIndex] += lpTokenAmount;
        totalLpTokens[memeIndex] += lpTokenAmount;

        try IEchoXPoints(echoXPoints).recordPoolCreation(msg.sender) {
        } catch {
        }

        emit LiquidityPoolCreated(msg.sender, memeToken.tokenAddress, INITIAL_POOL_EXTUSDT, INITIAL_POOL_MEME);
        
        priceTracker.initializePriceTracking(memeIndex, INITIAL_MEME_SUPPLY, INITIAL_POOL_EXTUSDT, INITIAL_POOL_MEME);
    }

    function addLiquidity(uint256 memeIndex, uint256 extusdtAmount) external nonReentrant validMemeIndex(memeIndex) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        require(memeToken.poolCreated, "Pool not created yet");

        uint256 memeAmount = (extusdtAmount * memeToken.memeReserve) / memeToken.extusdtReserve;

        uint256 oldExtusdtReserve = memeToken.extusdtReserve;
        uint256 oldTotalLp = totalLpTokens[memeIndex];

        require(IERC20(EXTUSDT).transferFrom(msg.sender, address(this), extusdtAmount), "EXTUSDT transfer failed");
        require(IERC20(memeToken.tokenAddress).transferFrom(msg.sender, address(this), memeAmount), "Meme token transfer failed");

        memeToken.extusdtReserve += extusdtAmount;
        memeToken.memeReserve += memeAmount;

        uint256 lpTokenAmount = (extusdtAmount * oldTotalLp) / oldExtusdtReserve;
        lpTokens[msg.sender][memeIndex] += lpTokenAmount;
        totalLpTokens[memeIndex] += lpTokenAmount;

        try IEchoXPoints(echoXPoints).recordLpParticipation(msg.sender, address(this)) {
        } catch {
        }

        emit LiquidityAdded(msg.sender, memeToken.tokenAddress, extusdtAmount, memeAmount);

        priceTracker.updateLiquidity(memeIndex, memeToken.extusdtReserve * 2);
    }

    function removeLiquidity(uint256 memeIndex, uint256 lpAmount) external nonReentrant validMemeIndex(memeIndex) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        require(memeToken.poolCreated, "Pool not created yet");
        require(lpTokens[msg.sender][memeIndex] >= lpAmount, "Insufficient LP tokens");

        uint256 totalLp = totalLpTokens[memeIndex];
        require(totalLp > 0, "No liquidity");

        uint256 extusdtAmount = (lpAmount * memeToken.extusdtReserve) / totalLp;
        uint256 memeAmount = (lpAmount * memeToken.memeReserve) / totalLp;

        lpTokens[msg.sender][memeIndex] -= lpAmount;
        totalLpTokens[memeIndex] -= lpAmount;

        memeToken.extusdtReserve -= extusdtAmount;
        memeToken.memeReserve -= memeAmount;

        require(IERC20(EXTUSDT).transfer(msg.sender, extusdtAmount), "EXTUSDT transfer failed");
        require(IERC20(memeToken.tokenAddress).transfer(msg.sender, memeAmount), "Meme token transfer failed");

        emit LiquidityRemoved(msg.sender, memeToken.tokenAddress, extusdtAmount, memeAmount);

        priceTracker.updateLiquidity(memeIndex, memeToken.extusdtReserve * 2);
    }

    function swapExtusdtForMeme(uint256 memeIndex, uint256 extusdtAmount, uint256 minMemeOut) external nonReentrant validMemeIndex(memeIndex) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        require(memeToken.poolCreated, "Pool not created yet");

        uint256 expectedMemeOutWithoutSlippage = (memeToken.memeReserve * extusdtAmount) / (memeToken.extusdtReserve + extusdtAmount);
        if (block.timestamp / 1 days != lastBuyTimestamp[msg.sender] / 1 days) {
            dailyBuyAmount[msg.sender] = 0;
            lastBuyTimestamp[msg.sender] = block.timestamp;
        }
        require(dailyBuyAmount[msg.sender] + expectedMemeOutWithoutSlippage <= DAILY_BUY_LIMIT_MEME, "Daily buy limit exceeded");

        uint256 fee = (extusdtAmount * SWAP_FEE_PERCENT) / 1000;
        uint256 extusdtAmountAfterFee = extusdtAmount - fee;

        uint256 memeOutput = (memeToken.memeReserve * extusdtAmountAfterFee) / (memeToken.extusdtReserve + extusdtAmountAfterFee);
        require(memeOutput >= minMemeOut, "Slippage too high");

        require(IERC20(EXTUSDT).transferFrom(msg.sender, address(this), extusdtAmount), "EXTUSDT transfer failed");

        memeToken.extusdtReserve += extusdtAmountAfterFee;
        memeToken.memeReserve -= memeOutput;

        require(IERC20(memeToken.tokenAddress).transfer(msg.sender, memeOutput), "Meme token transfer failed");

        dailyBuyAmount[msg.sender] += memeOutput;

        try IEchoXPoints(echoXPoints).recordMemeTransaction(memeToken.creator) {
        } catch {
        }

        try IEchoXPoints(echoXPoints).recordDailySwap(msg.sender) {
        } catch {
        }

        emit TokenSwap(msg.sender, memeToken.tokenAddress, extusdtAmount, memeOutput, true);
        emit MemeTransaction(memeToken.creator, memeOutput, "buy");
        
        priceTracker.updatePriceTracking(memeIndex, extusdtAmount, true);
    }

    function swapMemeForExtusdt(uint256 memeIndex, uint256 memeAmount, uint256 minExtusdtOut) external nonReentrant validMemeIndex(memeIndex) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        require(memeToken.poolCreated, "Pool not created yet");

        if (block.timestamp / 1 days != lastSellTimestamp[msg.sender] / 1 days) {
            dailySellAmount[msg.sender] = 0;
            lastSellTimestamp[msg.sender] = block.timestamp;
        }
        require(dailySellAmount[msg.sender] + memeAmount <= DAILY_SELL_LIMIT_MEME, "Daily sell limit exceeded");

        uint256 fee = (memeAmount * SWAP_FEE_PERCENT) / 1000;
        uint256 memeAmountAfterFee = memeAmount - fee;

        uint256 extusdtOutput = (memeToken.extusdtReserve * memeAmountAfterFee) / (memeToken.memeReserve + memeAmountAfterFee);
        require(extusdtOutput >= minExtusdtOut, "Slippage too high");

        require(IERC20(memeToken.tokenAddress).transferFrom(msg.sender, address(this), memeAmount), "Meme token transfer failed");

        memeToken.memeReserve += memeAmountAfterFee;
        memeToken.extusdtReserve -= extusdtOutput;

        require(IERC20(EXTUSDT).transfer(msg.sender, extusdtOutput), "EXTUSDT transfer failed");

        dailySellAmount[msg.sender] += memeAmount;

        try IEchoXPoints(echoXPoints).recordMemeTransaction(memeToken.creator) {
        } catch {
        }

        try IEchoXPoints(echoXPoints).recordDailySwap(msg.sender) {
        } catch {
        }

        emit TokenSwap(msg.sender, memeToken.tokenAddress, memeAmount, extusdtOutput, false);
        emit MemeTransaction(memeToken.creator, memeAmount, "sell");
        
        priceTracker.updatePriceTracking(memeIndex, memeAmount, false);
    }

    function getMemeTokenAddress(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (address) {
        return memeTokens[memeIndex].tokenAddress;
    }

    function getMemePrice(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];

        if (!memeToken.poolCreated || memeToken.memeReserve == 0) {
            return 0;
        }

        return (memeToken.extusdtReserve * 10**18) / memeToken.memeReserve;
    }

    function getAmountOut(uint256 memeIndex, uint256 amountIn, bool isExtusdtToMeme) external view validMemeIndex(memeIndex) returns (uint256) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];

        if (!memeToken.poolCreated) {
            return 0;
        }

        uint256 fee = (amountIn * SWAP_FEE_PERCENT) / 1000;
        uint256 amountInAfterFee = amountIn - fee;

        if (isExtusdtToMeme) {
            return (memeToken.memeReserve * amountInAfterFee) / (memeToken.extusdtReserve + amountInAfterFee);
        } else {
            return (memeToken.extusdtReserve * amountInAfterFee) / (memeToken.memeReserve + amountInAfterFee);
        }
    }

    function getUserLpTokens(address user, uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256) {
        return lpTokens[user][memeIndex];
    }

    function getTotalLpTokens(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256) {
        return totalLpTokens[memeIndex];
    }

    function getPoolReserves(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256 extusdtReserve, uint256 memeReserve) {
        MemeTokenInfo storage memeToken = memeTokens[memeIndex];
        return (memeToken.extusdtReserve, memeToken.memeReserve);
    }

    function getMemeTokenCount() external view returns (uint256) {
        return memeTokens.length;
    }

    function getMemeToken(uint256 index) external view returns (
        address tokenAddress,
        string memory name,
        string memory symbol,
        string memory logo,
        address creator,
        bool poolCreated
    ) {
        require(index < memeTokens.length, "Index out of bounds");
        MemeTokenInfo storage m = memeTokens[index];
        return (m.tokenAddress, m.name, m.symbol, m.logo, m.creator, m.poolCreated);
    }

    function getUserDailyLimits(address user) external view returns (
        uint256 buyAmount,
        uint256 sellAmount,
        uint256 buyLimit,
        uint256 sellLimit
    ) {
        if (block.timestamp / 1 days != lastBuyTimestamp[user] / 1 days) {
            buyAmount = 0;
        } else {
            buyAmount = dailyBuyAmount[user];
        }

        if (block.timestamp / 1 days != lastSellTimestamp[user] / 1 days) {
            sellAmount = 0;
        } else {
            sellAmount = dailySellAmount[user];
        }

        return (buyAmount, sellAmount, DAILY_BUY_LIMIT_MEME, DAILY_SELL_LIMIT_MEME);
    }
}

interface IPriceTracking {
    function initializePriceTracking(uint256 memeIndex, uint256 totalMemeSupply, uint256 initialExtusdtReserve, uint256 initialMemeReserve) external;
    function updatePriceTracking(uint256 memeIndex, uint256 tradeVolume, bool isBuy) external;
    function updateLiquidity(uint256 memeIndex, uint256 totalLiquidity) external;
}

interface ICommunityReactions {
    function getMemeTokenCount() external view returns (uint256);
}

contract MemeToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public creator;

    constructor(string memory _name, string memory _symbol, address _creator, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        creator = _creator;
        totalSupply = _initialSupply;
        balanceOf[_creator] = _initialSupply;
        emit Transfer(address(0), _creator, _initialSupply);
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
