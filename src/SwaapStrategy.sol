// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy, ERC20} from "lib/tokenized-strategy/src/BaseStrategy.sol";

interface ISwaapVault {

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        ERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

   function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        ERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    } 

}

interface IAavePool {
 function deposit(
    ERC20 asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    ERC20 asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    ERC20 asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    ERC20 asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);
}

enum Action {
        deposit,
        withdraw, 
        borrow,
        repay,
        join, 
        exit,
        swap
}

contract SwaapStrategy is BaseStrategy {
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

}