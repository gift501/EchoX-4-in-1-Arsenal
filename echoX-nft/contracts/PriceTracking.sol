// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMemeFactoryCaller {
    function getPoolReserves(uint256 memeIndex) external view returns (uint256 extusdtReserve, uint256 memeReserve);
    function getMemeTokenCount() external view returns (uint256);
}

contract PriceTracking {
    struct PricePoint {
        uint256 timestamp;
        uint256 price;
        uint256 volume24h;
        uint256 marketCap;
        uint256 liquidity;
    }

    struct TradingMetrics {
        uint256 totalVolume;
        uint256 volume24h;
        uint256 trades24h;
        uint256 lastTradeTimestamp;
        uint256 highPrice24h;
        uint256 lowPrice24h;
        uint256 openPrice24h;
    }

    mapping(uint256 => PricePoint[]) public priceHistory;
    mapping(uint256 => TradingMetrics) public tradingMetrics;

    mapping(uint256 => mapping(uint256 => uint256)) public dailyVolume;
    mapping(uint256 => mapping(uint256 => uint256)) public hourlyVolume;
    mapping(uint256 => mapping(uint256 => uint256)) public dailyAveragePrice;
    mapping(uint256 => mapping(uint256 => uint256)) public hourlyAveragePrice;

    uint256 public constant PRICE_UPDATE_INTERVAL = 300;
    uint256 public constant MAX_PRICE_POINTS = 10000;
    uint256 public constant INITIAL_MEME_SUPPLY = 10_000_000 * 10**18;

    address public memeFactory;

    mapping(uint256 => mapping(uint256 => uint256)) private dailyPrices7d;
    mapping(uint256 => mapping(uint256 => uint256)) private dailyPrices30d;

    mapping(uint256 => uint256) public latestPrice;
    mapping(uint256 => uint256) public latestTimestamp;

    mapping(uint256 => mapping(uint256 => uint256)) public dailyVolumes7d;
    mapping(uint256 => mapping(uint256 => uint256)) public dailyVolumes30d;


    event PriceUpdated(uint256 indexed memeIndex, uint256 price, uint256 timestamp, uint256 volume, uint256 liquidity);
    event TradingMetricsUpdated(uint256 indexed memeIndex, uint256 volume24h, uint256 trades24h, uint256 high24h, uint256 low24h);
    event TradeEvent(uint256 indexed memeIndex, uint256 price, uint256 volume, bool isBuy, uint256 timestamp);
    event DailyPriceUpdated(
        uint256 indexed memeIndex,
        uint256 indexed day,
        uint256 price,
        uint256 totalVolume
    );

    constructor(address _memeFactory) {
        memeFactory = _memeFactory;
    }

    modifier onlyMemeFactory() {
        require(msg.sender == memeFactory, "Only MemeFactory can call this");
        _;
    }

    modifier validMemeIndex(uint256 memeIndex) {
        require(memeIndex < IMemeFactoryCaller(memeFactory).getMemeTokenCount(), "Invalid meme index");
        _;
    }

    function updateMemeFactory(address _newMemeFactory) external onlyMemeFactory {
        memeFactory = _newMemeFactory;
    }

    function initializePriceTracking(uint256 memeIndex, uint256 totalMemeSupply, uint256 initialExtusdtReserve, uint256 initialMemeReserve) external onlyMemeFactory {
        require(initialMemeReserve > 0, "Meme reserve must be greater than 0");
        uint256 initialPrice = (initialExtusdtReserve * 1e18) / initialMemeReserve;
        uint256 currentDay = block.timestamp / 86400;

        priceHistory[memeIndex].push(PricePoint({
            timestamp: block.timestamp,
            price: initialPrice,
            volume24h: 0,
            marketCap: (totalMemeSupply * initialPrice) / 1e18,
            liquidity: initialExtusdtReserve * 2
        }));

        tradingMetrics[memeIndex] = TradingMetrics({
            totalVolume: 0,
            volume24h: 0,
            trades24h: 0,
            lastTradeTimestamp: block.timestamp,
            highPrice24h: initialPrice,
            lowPrice24h: initialPrice,
            openPrice24h: initialPrice
        });

        latestPrice[memeIndex] = initialPrice;
        latestTimestamp[memeIndex] = block.timestamp;
        dailyPrices7d[memeIndex][currentDay] = initialPrice;
        dailyPrices30d[memeIndex][currentDay] = initialPrice;
        dailyVolumes7d[memeIndex][currentDay] = 0;
        dailyVolumes30d[memeIndex][currentDay] = 0;

        emit PriceUpdated(memeIndex, initialPrice, block.timestamp, 0, initialExtusdtReserve * 2);
        emit DailyPriceUpdated(memeIndex, currentDay, initialPrice, 0);
    }

    function updatePriceTracking(uint256 memeIndex, uint256 tradeVolume, bool isBuy) external onlyMemeFactory validMemeIndex(memeIndex) {
        (uint256 extusdtReserve, uint256 memeReserve) = IMemeFactoryCaller(memeFactory).getPoolReserves(memeIndex);
        if (memeReserve == 0) return;

        uint256 currentPrice = (extusdtReserve * 1e18) / memeReserve;
        TradingMetrics storage metrics = tradingMetrics[memeIndex];

        uint256 previousTimestamp = metrics.lastTradeTimestamp;
        metrics.totalVolume += tradeVolume;
        metrics.lastTradeTimestamp = block.timestamp;

        uint256 currentDay = block.timestamp / 1 days;
        uint256 currentHour = block.timestamp / 1 hours;
        uint256 lastTradeDay = previousTimestamp / 1 days;

        if (currentDay != lastTradeDay) {
            metrics.volume24h = tradeVolume;
            metrics.trades24h = 1;
            metrics.highPrice24h = currentPrice;
            metrics.lowPrice24h = currentPrice;
            metrics.openPrice24h = currentPrice;
        } else {
            metrics.volume24h += tradeVolume;
            metrics.trades24h += 1;
            if (currentPrice > metrics.highPrice24h) metrics.highPrice24h = currentPrice;
            if (currentPrice < metrics.lowPrice24h) metrics.lowPrice24h = currentPrice;
        }

        dailyVolume[memeIndex][currentDay] += tradeVolume;
        hourlyVolume[memeIndex][currentHour] += tradeVolume;

        uint256 oldDailyPrice = dailyAveragePrice[memeIndex][currentDay];
        uint256 oldHourlyPrice = hourlyAveragePrice[memeIndex][currentHour];

        dailyAveragePrice[memeIndex][currentDay] = oldDailyPrice == 0 ? currentPrice : (oldDailyPrice + currentPrice) / 2;
        hourlyAveragePrice[memeIndex][currentHour] = oldHourlyPrice == 0 ? currentPrice : (oldHourlyPrice + currentPrice) / 2;

        emit TradeEvent(memeIndex, currentPrice, tradeVolume, isBuy, block.timestamp);

        latestPrice[memeIndex] = currentPrice;
        latestTimestamp[memeIndex] = block.timestamp;

        dailyPrices7d[memeIndex][currentDay] = currentPrice;
        dailyVolumes7d[memeIndex][currentDay] += tradeVolume;

        dailyPrices30d[memeIndex][currentDay] = currentPrice;
        dailyVolumes30d[memeIndex][currentDay] += tradeVolume;

        emit DailyPriceUpdated(memeIndex, currentDay, currentPrice, dailyVolumes7d[memeIndex][currentDay]);


        PricePoint[] storage history = priceHistory[memeIndex];
        bool shouldUpdatePrice = false;

        if (history.length == 0) {
            shouldUpdatePrice = true;
        } else {
            PricePoint storage lastPoint = history[history.length - 1];
            uint256 timeDiff = block.timestamp - lastPoint.timestamp;
            uint256 priceDiff = currentPrice > lastPoint.price ? currentPrice - lastPoint.price : lastPoint.price - currentPrice;
            
            uint256 priceChangePercent = lastPoint.price == 0 ? (priceDiff > 0 ? 100 : 0) : (priceDiff * 100) / lastPoint.price;

            if (timeDiff >= PRICE_UPDATE_INTERVAL || priceChangePercent >= 1) {
                shouldUpdatePrice = true;
            }
        }

        if (shouldUpdatePrice) {
            if (history.length >= MAX_PRICE_POINTS) {
                uint256 removeCount = MAX_PRICE_POINTS / 10;
                for (uint256 i = removeCount; i < history.length; i++) {
                    history[i - removeCount] = history[i];
                }
                for (uint256 i = 0; i < removeCount; i++) {
                    history.pop();
                }
            }

            uint256 marketCap = (INITIAL_MEME_SUPPLY * currentPrice) / 1e18;
            uint256 totalLiquidity = extusdtReserve * 2;

            history.push(PricePoint({
                timestamp: block.timestamp,
                price: currentPrice,
                volume24h: metrics.volume24h,
                marketCap: marketCap,
                liquidity: totalLiquidity
            }));

            emit PriceUpdated(memeIndex, currentPrice, block.timestamp, metrics.volume24h, totalLiquidity);
            emit TradingMetricsUpdated(memeIndex, metrics.volume24h, metrics.trades24h, metrics.highPrice24h, metrics.lowPrice24h);
        }
    }

    function updateLiquidity(uint256 memeIndex, uint256 totalLiquidity) external onlyMemeFactory {
        PricePoint[] storage history = priceHistory[memeIndex];
        if (history.length > 0) {
            history[history.length - 1].liquidity = totalLiquidity;
        }
    }

    function getPriceHistory(uint256 memeIndex, uint256 fromTimestamp, uint256 toTimestamp, uint256 maxPoints)
        external view validMemeIndex(memeIndex)
        returns (
            uint256[] memory timestamps,
            uint256[] memory prices,
            uint256[] memory volumes,
            uint256[] memory marketCaps,
            uint256[] memory liquidities
        )
    {
        PricePoint[] storage history = priceHistory[memeIndex];
        if (history.length == 0) {
            return (new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0));
        }

        uint256 startIndex = 0;
        uint256 endIndex = history.length;

        for (uint256 i = 0; i < history.length; i++) {
            if (history[i].timestamp >= fromTimestamp) {
                startIndex = i;
                break;
            }
        }

        for (uint256 i = history.length; i > 0; i--) {
            if (history[i - 1].timestamp <= toTimestamp) {
                endIndex = i;
                break;
            }
        }

        if (startIndex >= endIndex) {
            return (new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0));
        }

        uint256 totalPoints = endIndex - startIndex;
        uint256 step = 1;
        if (maxPoints > 0 && totalPoints > maxPoints) {
            step = totalPoints / maxPoints;
            if (totalPoints % maxPoints != 0) {
                step++;
            }
            totalPoints = (endIndex - startIndex + step -1) / step;
        }

        timestamps = new uint256[](totalPoints);
        prices = new uint256[](totalPoints);
        volumes = new uint256[](totalPoints);
        marketCaps = new uint256[](totalPoints);
        liquidities = new uint256[](totalPoints);

        uint256 outputIndex = 0;
        for (uint256 i = startIndex; i < endIndex; i += step) {
            if (outputIndex < totalPoints) {
                PricePoint storage point = history[i];
                timestamps[outputIndex] = point.timestamp;
                prices[outputIndex] = point.price;
                volumes[outputIndex] = point.volume24h;
                marketCaps[outputIndex] = point.marketCap;
                liquidities[outputIndex] = point.liquidity;
                outputIndex++;
            } else {
                break;
            }
        }

        if (outputIndex < totalPoints) {
            assembly {
                mstore(timestamps, outputIndex)
                mstore(prices, outputIndex)
                mstore(volumes, outputIndex)
                mstore(marketCaps, outputIndex)
                mstore(liquidities, outputIndex)
            }
        }
    }


    function getLatestPriceData(uint256 memeIndex)
        external
        view
        validMemeIndex(memeIndex)
        returns (
            uint256 currentPrice,
            int256 priceChange24h,
            uint256 volume24h,
            uint256 marketCap,
            uint256 liquidity
        )
    {
        PricePoint[] storage history = priceHistory[memeIndex];
        if (history.length == 0) return (0, 0, 0, 0, 0);

        PricePoint storage latest = history[history.length - 1];
        currentPrice = latest.price;
        volume24h = latest.volume24h;
        marketCap = latest.marketCap;
        liquidity = latest.liquidity;

        TradingMetrics storage metrics = tradingMetrics[memeIndex];
        if (metrics.openPrice24h == 0) {
            priceChange24h = 0;
        } else if (currentPrice >= metrics.openPrice24h) {
            priceChange24h = int256(currentPrice - metrics.openPrice24h);
        } else {
            priceChange24h = -int256(metrics.openPrice24h - currentPrice);
        }
    }

    function getDailyAveragePrice(uint256 memeIndex, uint256 day) external view returns (uint256) {
        return dailyAveragePrice[memeIndex][day];
    }

    function getHourlyAveragePrice(uint256 memeIndex, uint256 hour) external view returns (uint256) {
        return hourlyAveragePrice[memeIndex][hour];
    }

    function getPrice7d(uint256 memeIndex, uint256 day) external view validMemeIndex(memeIndex) returns (uint256) {
        return dailyPrices7d[memeIndex][day];
    }

    function getPrice30d(uint256 memeIndex, uint256 day) external view validMemeIndex(memeIndex) returns (uint256) {
        return dailyPrices30d[memeIndex][day];
    }

    function getLastNDaysPrices7d(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256[] memory prices) {
        prices = new uint256[](7);
        uint256 currentDay = block.timestamp / 86400;
        for (uint256 i = 0; i < 7; i++) {
            if (currentDay >= i) {
                prices[i] = dailyPrices7d[memeIndex][currentDay - i];
            } else {
                prices[i] = 0;
            }
        }
    }

    function getLastNDaysPrices30d(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (uint256[] memory prices) {
        prices = new uint256[](30);
        uint256 currentDay = block.timestamp / 86400;
        for (uint256 i = 0; i < 30; i++) {
            if (currentDay >= i) {
                prices[i] = dailyPrices30d[memeIndex][currentDay - i];
            } else {
                prices[i] = 0;
            }
        }
    }
}
