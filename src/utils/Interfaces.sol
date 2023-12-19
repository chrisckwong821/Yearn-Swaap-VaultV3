
import {ERC20} from "lib/tokenized-strategy/src/BaseStrategy.sol";


interface IERC20Metadata {
    function decimals() external view returns(uint8);
}

interface AggregatorV3Interface {

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
interface ISafeguardPool {

    struct InitialOracleParams {
        AggregatorV3Interface oracle;
        uint256 maxTimeout;
        bool isStable;
        bool isFlexibleOracle;
    }

    struct OracleParams {
        AggregatorV3Interface oracle;
        uint256 maxTimeout;
        bool isStable;
        bool isFlexibleOracle;
        bool isPegged;
        uint256 priceScalingFactor;
    }
    
    /// @dev returns the current target balances of the pool based on the hodl strategy and latest performance
    function getHodlBalancesPerPT() external view returns(uint256, uint256);
    
    /// @dev returns the on-chain oracle price of tokenIn such that price = amountIn / amountOut
    function getOnChainAmountInPerOut(address tokenIn) external view returns(uint256);
    
    /// @dev returns the current pool oracle parameters
    function getOracleParams() external view returns(OracleParams[] memory);

}


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


    function getPoolTokens(bytes32 poolId) external view returns(
        address[] memory tokens, 
        uint256[] memory balances,
        uint256 lastChangeBlock
    );

    function getPool(bytes32 poolId) external view returns(
        address poolAddress,
        uint8 poolSpecialization
    );


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


  function getConfiguration(
    address reserve
  ) external view returns(uint256);

  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );
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
