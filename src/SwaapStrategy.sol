// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy} from "lib/tokenized-strategy/src/BaseStrategy.sol";

contract SwaapStrategy is BaseStrategy {

    constructor(address _asset, string memory _name) BaseStrategy(_asset, _name) {
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
         * @TODO
         * assume we have 100 excess "want"
         * using "LTV", "price", calculate the amount of "want" to deposit into lending market
         * calculate the amount of "paired" token to borrow
         * borrow "paired" token
         * supply into the swaap pool
         * record any excess "paired" token (if any)
         */ 
        
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
         * @TODO
         * assume we need 100 "want"
         * we need to scale down the entire position (LP, deposit and borrow in lending market)
         * 1.) withdraw some LP
         * 2.) repay the debt 
         * 3.) withdraw some want
         */ 
        
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
         * @TODO
         * assume after Time T; LP accrues fee/loss
         * 1.) fetch the underlying token0 and token1 amount/*price
         * 2.) collect (if any) gov token and swap to "want"
         * 3.) fetch the collateral and debt in lending market
         * consolidate them
         */
    }
        
    
    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a permissioned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed position maintenance or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal override {
        /** 
         * @TODO
         * input is totalIdle fund, but we may need to check collateral status too
         * assume there is price change(s) in token0 or token1, such that we need to adjust collateral/debt
         * if remove debt:
         * similar to _freefund, we withdraw LP first
         * pay down debt and deposit the excess "want" into collateral
         * report any profit/loss as a result of performance difference incurred.
         * if increase debt (debtToken price decreases):
         * borrow some more debtToken, based on how much _idle fund we have, withdraw deposit if needed
         * pair and supply into LP
         */
    }

    /**
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function _tendTrigger() internal view override returns (bool) {
        /** 
         * @TODO
         * define the condition(health factor upper/lower, and optimal level):
         * which we need to trigger the collateral/debt scale up/down
         * and to what level
         * this function then just against the upper/lower threshold
         */
        return false;
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
    

     * generallize : X * liqThre * poolRatio = targetHF * (worth - X)

                                      targetHF * worth
            X =           --------------------------------------- 
                               liqThre * poolRatio + targetHF 
     * @return . the amount of paired asset to borrow
     */
    function _solveAaveDeposit(uint256 worth, uint256 liqThreshold, uint256 targetPoolRatio, uint256 targetHF) internal pure returns(uint256 deposit, uint256 borrow) {
        uint256 discountedTargetPoolRatio = targetPoolRatio * liqThreshold / 10000; // 10000 is liqThresholdConstant
        // decimal: HF 18, worth 18, poolRatio 18 => return decimal 18
        deposit = targetHF * worth  / (discountedTargetPoolRatio + targetHF);
        // targetPoolRatio should be want($) / borrowedAsset($)
        borrow = deposit * 1e18 / targetPoolRatio;
    }

    function _retrieveAaveLiquidationThreshold(address reserve) internal returns(uint256 liquidationThreshold) {
        uint256 configuration = aavePool.getConfiguration(reserve);
        // copied from Aave, reference DataTypes;
        // https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/configuration/ReserveConfiguration.sol#L109-L113
        uint256 LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF;
        uint256 LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
        liquidationThreshold = 
            (configuration & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }
}
