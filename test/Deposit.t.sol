// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import {SwaapStrategy, ERC20, Action} from "../src/SwaapStrategy.sol";
import {SwaapStrategyImplV1} from "../src/SwaapStrategyImplV1.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface ILendingPool {
    
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

contract DepositTest is Test {

    uint256 polygonFork;
    SwaapStrategyImplV1 public strategyImplFunctions;
    SwaapStrategy public strategyProxyFunctions;
    ERC20 USDC = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    ERC20 WMATIC = ERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address USDCWhale = 0xf89d7b9c864f589bbF53a82105107622B35EaA40;

    address SwaapVault = 0xd315a9C38eC871068FEC378E4Ce78AF528C76293;
    bytes32 poolId= 0x3fbf7753ff5b217ca8ffbb441939c20bf3ec3be1000200000000000000000002;
    address AavePool = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address TokenizedStrategyAddress =0x2e234DAe75C793f67A35089C9d99245E1C58470b;

    function setUp() public {
        string memory POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
        polygonFork = vm.createFork(POLYGON_RPC_URL);
        vm.selectFork(polygonFork);
        strategyProxyFunctions = new SwaapStrategy(address(USDC), address(WMATIC), "Spankers", SwaapVault, poolId, AavePool);
        strategyImplFunctions = SwaapStrategyImplV1(address(strategyProxyFunctions));
        vm.etch(TokenizedStrategyAddress, address(address(new SwaapStrategyImplV1())).code);
        strategyImplFunctions.init(address(USDC), "Spank", address(this), address(this), address(this));

        vm.startPrank(USDCWhale);
        USDC.transfer(address(this), 100000e6);
        vm.stopPrank();
    }

    // @audit test some cases when some time has passed and interest has occured 
    function testDeposit() public {
        USDC.approve(address(strategyProxyFunctions), type(uint256).max);
        SwaapStrategyImplV1(address(strategyProxyFunctions)).deposit(1e6, USDCWhale);
        (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        ) = ILendingPool(AavePool).getUserAccountData(address(strategyProxyFunctions));
        assertGe(totalCollateralETH, 0);
        assertGe(totalDebtETH, 0);
        console.log(totalCollateralETH);
        console.log(totalDebtETH);
    }
}