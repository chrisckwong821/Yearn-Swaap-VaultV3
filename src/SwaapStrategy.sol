// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy} from "lib/tokenized-strategy/src/BaseStrategy.sol";
import {SwaapEncodings} from "./utils/SwaapEncodings.sol";
import "./utils/Interfaces.sol";
contract SwaapStrategy is BaseStrategy, SwaapEncodings {
    // dev: the storage of tokenised strat is at completely diff location, hence here proxy aka this contract can have its own storage
    ERC20 internal immutable borrowedAsset;
    ISwaapVault public liquidityPool;
    bytes32 public poolId;
    IAavePool public lendingPool;
    
    constructor(address _asset, address _borrowedAsset, string memory _name, address _liquidityPool, bytes32 _poolId, address _lendingPool) BaseStrategy(_asset, _name) {
        borrowedAsset = ERC20(_borrowedAsset);
        poolId = _poolId;
        liquidityPool = ISwaapVault(_liquidityPool); 
        lendingPool = IAavePool(_lendingPool);

        ERC20(asset).approve(_liquidityPool, type(uint256).max);
        ERC20(_borrowedAsset).approve(_liquidityPool, type(uint256).max);
        ERC20(asset).approve(_lendingPool, type(uint256).max);
        ERC20(_borrowedAsset).approve(_lendingPool, type(uint256).max);
    }
    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attempt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        /** 
         * assume we have 100 excess "want"
         * using "LTV", "price", calculate the amount of "want" to deposit into lending market
         * calculate the amount of "paired" token to borrow
         * borrow "paired" token
         * supply into the swaap pool
         * record any excess "paired" token (if any)
         */ 
         uint256 targetHF = 2 * 1e18; // @audit decide how to decide target HF
         uint256 liqThreshold = _retrieveAaveLiquidationThreshold();
         uint256 targetSwaapRatio = _retriveSwaapTragetPoolRatio();
         (uint256 deposit, uint256 borrowInUnitOfAsset) = 
            _solveAaveDeposit(_amount, liqThreshold, targetSwaapRatio, targetHF);
        lendingPool.deposit(asset, deposit, address(this), 0);
        // assume we need to borrow 25 matic worth of USDC
        // then we need to find 25 / (price of USDC / price of matic)
        // _borrowedAssetInUnitOfAsset = priceOfBorrowed / priceAsset
        uint256 borrow = borrowInUnitOfAsset * 1e18 / _borrowedAssetPriceInUnitOfAsset();
        lendingPool.borrow(borrowedAsset, borrow, 2, 0, address(this));
        // joinPool
        // the amount of asset to supply into Swaap is the input _amount, minus the amount deposited int Aave
        uint256 amountA = _amount - deposit;
        uint256 amountB = borrow;
        // expect a router to enforce slippage protection on top of the ERC4626 vault level
        // 0.5%
        uint256 slippage = 50;
        uint256 minimumBPT = _calcBPToExpect() * (10000 - slippage) / 100000;
        ISwaapVault.JoinPoolRequest memory j;
        j.assets = _gibDynamicArrayERC20(asset, borrowedAsset); // @audit does order matter, refractor this later
        // @TODO use getUserDataForExactJoin
        if (asset < borrowedAsset) {
            j.maxAmountsIn = _gibDynamicArrayUint256(amountA, amountB);
        } else {
            j.maxAmountsIn = _gibDynamicArrayUint256(amountB, amountA);
        }
        j.userData = getUserDataForProportionalJoin(minimumBPT);
        liquidityPool.joinPool(poolId, address(this), address(this), j);
        
    }

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        /** 
         * assume we need 100 "want"
         * we need to scale down the entire position (LP, deposit and borrow in lending market)
         * 1.) withdraw some LP
         * 2.) repay the debt 
         * 3.) withdraw some want
         */ 
        uint256 minimumBPT = 0;
        uint256 amountA = _amount;
        // uint256 amountB = borrow;
        // ISwaapVault.ExitPoolRequest memory e;
        // e.assets = _gibDynamicArrayERC20(asset, borrowedAsset);
        // e.minAmountsOut = _gibDynamicArrayUint256(amountA, amountB);
        // e.userData = getUserDataForProportionalExit(minimumBPT);
        // liquidityPool.exitPool(poolId, address(this), payable(address(this)), e);
        
    }
    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets) {
        /** 
         * this function is part of the report work flow
         * the report function would then update strategy struct 
         * in TokenizedStrategy
         * totalAssets is implemented as totalIdle + totalDebt there
         */
         return getAaveValue() + getLPValue();
    }
        
    
    function rebalance (Action[] memory actions, bytes [] memory params) external onlyManagement {
        
        for (uint256 i=0; i< actions.length; i++)
        {   
            // Lending
            if (actions[i] == Action.deposit) 
            {   
                (uint256 amount) = abi.decode(params[i], (uint256));
                lendingPool.deposit(asset, amount, address(this), 0);
            }
            else if  (actions[i] == Action.withdraw)  {   
                (uint256 amount) = abi.decode(params[i], (uint256));
                lendingPool.withdraw(asset, amount, address(this));
            } 
            else if  (actions[i] == Action.borrow)  {   
                (uint256 amount) = abi.decode(params[i], (uint256));
                lendingPool.borrow(borrowedAsset, amount, 2, 0, address(this)); // @audit do we want option of stable rate ?
            } 
            else if  (actions[i] == Action.repay)  {   
                (uint256 amount) = abi.decode(params[i], (uint256));
                lendingPool.repay(borrowedAsset, amount, 2, address(this)); // @audit do we want option of stable rate ?
            }  
           // Liquidity 
            else if (actions[i] == Action.join) {
                
                (uint256 amountA, uint256 amountB) = abi.decode(params[i], (uint256, uint256));
                ISwaapVault.JoinPoolRequest memory j;
                j.assets = _gibDynamicArrayERC20(asset, borrowedAsset); // @audit does order matter, refractor this later
                j.maxAmountsIn = _gibDynamicArrayUint256(amountA, amountB);
                liquidityPool.joinPool(poolId, address(this), address(this), j);
            }  
            else if (actions[i] == Action.exit)
            {
                (uint256 amountA, uint256 amountB) = abi.decode(params[i], (uint256, uint256));
                ISwaapVault.ExitPoolRequest memory e;
                e.assets = _gibDynamicArrayERC20(asset, borrowedAsset); // @audit does order matter
                e.minAmountsOut = _gibDynamicArrayUint256(amountA, amountB);
                liquidityPool.exitPool(poolId, address(this), payable(address(this)), e);
            }
            else if (actions[i] == Action.swap)
            {

            }
 
        }
    }

    // hacky way to get around, refractor if time permits
    function _gibDynamicArrayERC20(ERC20 a, ERC20 b) internal returns (ERC20[] memory)
    {
           (a, b) = _sortTwoTokens(a, b);
           ERC20[] memory dynamicArray = new ERC20[](2);
           dynamicArray[0] = a;
           dynamicArray[1] = b;
           return dynamicArray;
    }

    function _gibDynamicArrayUint256(uint256 a, uint256 b) internal returns (uint256[] memory)
    {
           uint256[] memory dynamicArray = new uint256[](2);
           dynamicArray[0] = a;
           dynamicArray[1] = b;
           return dynamicArray;
    }

    /**
     * @dev Sorts two tokens in ascending order, returning them as a (tokenA, tokenB) tuple.
     */
    function _sortTwoTokens(ERC20 tokenX, ERC20 tokenY) private pure returns (ERC20, ERC20) {
        return tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    }

    /**
     * given $100 worth of want in (amountWant * priceWant)
     * calculate X to deposit into Aave
     * such that the borrow out paired asset match with the remaining want (100 - X)
     * with (at least) the targeted HF

     * Eg1. we want a HF of 2 (assume liqThreshold 80%), for 50/50 pool
     * then we need to deposit X such that X * 80% (collateral) * 50 / 50 = 2 * (100 - X)
     * X is 71.42857, the borrowed value => 28.56

     * Eg2. we want a HF of 2 (assume liqThreshold 80%), for 60/40 pool
     * then we need to deposit X such that X * 80% (collateral) * 60 / 40 = 2 * (100 - X)
     * X is 62.5, the borrowed value is (100 - 62.5) * 40/60 => 25
    

     * generallize : X * liqThre * poolRatio(asset/borrowedAsset) = targetHF * (worth - X)

                                      targetHF * worth
            X =           --------------------------------------- 
                               liqThre * poolRatio + targetHF 
     */
    function _solveAaveDeposit(uint256 worth, uint256 liqThreshold, uint256 targetPoolRatio, uint256 targetHF) internal view returns(uint256 deposit, uint256 borrow) {
        uint256 discountedTargetPoolRatio = targetPoolRatio * liqThreshold / 10000; // 10000 is liqThresholdConstant
        // decimal: HF 18, worth 18, poolRatio 18 => return decimal 18
        deposit = targetHF * worth  / (discountedTargetPoolRatio + targetHF);
        // targetPoolRatio should be want($) / borrowedAsset($)
        // borrow needs to calibrate to its own decimal
        borrow = (worth - deposit) * 1e18 * (10 ** IERC20Metadata(address(borrowedAsset)).decimals()) 
        /  targetPoolRatio
        / (10 ** IERC20Metadata(address(asset)).decimals());
    }


    function _retriveSwaapTragetPoolRatio() internal view returns(uint256) {
        (address poolAddress, ) = liquidityPool.getPool(poolId);
        // target balance is normalized to 1e18
        (uint256 targetBalance0, uint256 targetBalance1) = ISafeguardPool(poolAddress).getHodlBalancesPerPT();
        // fetch price from the oracle
        ISafeguardPool.OracleParams[] memory oracleParameter = new ISafeguardPool.OracleParams[](2);
        oracleParameter = ISafeguardPool(poolAddress).getOracleParams();
        (,int256 token0Price,,,) = oracleParameter[0].oracle.latestRoundData();
        (,int256 token1Price,,,) = oracleParameter[1].oracle.latestRoundData();
        uint256 token0Value = targetBalance0 * uint256(token0Price);
        uint256 token1Value = targetBalance1 * uint256(token1Price);
        // return asset / borrowedAsset as a targetRatio
        // assume price is in 1e8, we want a value of 1e18
        if (asset > borrowedAsset) {
            return token1Value * 1e18 / token0Value;
        } else {
            return token0Value * 1e18 / token1Value;
        }
    }
    function _retrieveAaveLiquidationThreshold() internal view returns(uint256 liquidationThreshold) {
        uint256 configuration = lendingPool.getConfiguration(address(asset));
        // copied from Aave, reference DataTypes;
        // https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/configuration/ReserveConfiguration.sol#L80-L86
        uint256 LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF;
        uint256 LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
        liquidationThreshold = 
            (configuration & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }



    function getLPValue() public view returns(uint256 lpValue) {
        (address poolAddress, ) = liquidityPool.getPool(poolId);
        uint256[] memory balances = new uint256[](2);
        (,balances,) = ISwaapVault(liquidityPool).getPoolTokens(poolId);
        uint256 totalSupply = ERC20(poolAddress).totalSupply();
        uint256 currentBalance = ERC20(poolAddress).balanceOf(address(this));
        // fetch price from the oracle
        ISafeguardPool.OracleParams[] memory oracleParameter = new ISafeguardPool.OracleParams[](2);
        oracleParameter = ISafeguardPool(poolAddress).getOracleParams();
        (,int256 token0Price,,,) = oracleParameter[0].oracle.latestRoundData();
        (,int256 token1Price,,,) = oracleParameter[1].oracle.latestRoundData();
        uint256 token0Value;
        uint256 token1Value;
        if (asset < borrowedAsset) {
            token0Value = tokenAmountIn18Decimals(asset, balances[0]) * uint256(token0Price);
            token1Value = tokenAmountIn18Decimals(borrowedAsset, balances[1]) * uint256(token1Price);
        } else {
            token0Value = tokenAmountIn18Decimals(borrowedAsset, balances[0]) * uint256(token0Price);
            token1Value = tokenAmountIn18Decimals(asset, balances[1]) * uint256(token1Price);
        }
        // assume price is 1e8
        return currentBalance * (token0Value + token1Value) / totalSupply / 1e8;
    }

    // find the collateralValue - debtValue
    // @audit use aave price or swaap price feed?
    function getAaveValue() public view returns(uint256 netValue) {
        // collateral is asset
        (uint256 totalCollateralBase, uint256 totalDebtBase,,,,) = lendingPool.getUserAccountData(address(this));
        netValue = totalCollateralBase - totalDebtBase;
    }

    // return priceBorrowedAsset / priceAsset in unit of 18
    function _borrowedAssetPriceInUnitOfAsset() private view returns(uint256) {
        (address poolAddress, ) = liquidityPool.getPool(poolId);
        ISafeguardPool.OracleParams[] memory oracleParameter = new ISafeguardPool.OracleParams[](2);
        oracleParameter = ISafeguardPool(poolAddress).getOracleParams();
        (,int256 token0Price,,,) = oracleParameter[0].oracle.latestRoundData();
        (,int256 token1Price,,,) = oracleParameter[1].oracle.latestRoundData();
        if (asset > borrowedAsset) {
            // asset is token1
            return uint256(token0Price * 1e18 / token1Price);
        } else {
            return uint256(token1Price * 1e18 / token0Price);
        }
    }

    function _calcBPToExpect() internal view returns(uint256) {
        (address poolAddress, ) = liquidityPool.getPool(poolId);
        uint256[] memory balances = new uint256[](2);
        (,balances,) = ISwaapVault(liquidityPool).getPoolTokens(poolId);
        uint256 totalSupply = ERC20(poolAddress).totalSupply();
        // fetch price from the oracle
        ISafeguardPool.OracleParams[] memory oracleParameter = new ISafeguardPool.OracleParams[](2);
        oracleParameter = ISafeguardPool(poolAddress).getOracleParams();
        (,int256 token0Price,,,) = oracleParameter[0].oracle.latestRoundData();
        (,int256 token1Price,,,) = oracleParameter[1].oracle.latestRoundData();
        uint256 token0Value;
        uint256 token1Value;
        uint256 currentToken0Value;
        uint256 currentToken1Value;
        if (asset < borrowedAsset) {
            token0Value = tokenAmountIn18Decimals(asset, balances[0]) * uint256(token0Price);
            token1Value = tokenAmountIn18Decimals(borrowedAsset, balances[1]) * uint256(token1Price);
            currentToken0Value = tokenAmountIn18Decimals(asset, ERC20(asset).balanceOf(address(this))) * uint256(token0Price);
            currentToken1Value = tokenAmountIn18Decimals(borrowedAsset, ERC20(borrowedAsset).balanceOf(address(this))) * uint256(token1Price);
        } else {
            token0Value = tokenAmountIn18Decimals(borrowedAsset, balances[0]) * uint256(token0Price);
            token1Value = tokenAmountIn18Decimals(asset, balances[1]) * uint256(token1Price);
            currentToken0Value = tokenAmountIn18Decimals(borrowedAsset, ERC20(borrowedAsset).balanceOf(address(this))) * uint256(token0Price);
            currentToken1Value = tokenAmountIn18Decimals(asset, ERC20(asset).balanceOf(address(this))) * uint256(token1Price);
        }
        // assume price is 1e8
        return (currentToken0Value + currentToken1Value) * totalSupply / (token0Value + token1Value);
    }
    function tokenAmountIn18Decimals(ERC20 asset, uint256 amount) public view returns(uint256) {
        return amount * 1e18 / (10 ** IERC20Metadata(address(asset)).decimals());
    }

}

