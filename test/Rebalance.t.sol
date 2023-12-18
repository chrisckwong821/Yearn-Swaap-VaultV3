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

contract HarvestTest is Test {

    uint256 polygonFork;
    SwaapStrategyImplV1 public strategyImplFunctions;
    SwaapStrategy public strategyProxyFunctions;
    ERC20 USDC = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    ERC20 WMATIC = ERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address USDCWhale = 0xf89d7b9c864f589bbF53a82105107622B35EaA40;
    address WMATICWhale = 0x0c54a0BCCF5079478a144dBae1AFcb4FEdf7b263;

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

        vm.startPrank(WMATICWhale);
        WMATIC.transfer(address(this), 100000e18);
        vm.stopPrank();
    }

    function testSetup() public {
       //console.logBytes32());
       assertEq(address(strategyProxyFunctions.liquidityPool()), SwaapVault);
       assertEq(strategyImplFunctions.symbol(), "ysUSDC");
    }

    // @audit test some cases when some time has passed and interest has occured 
    function testRebalanceDeposit() public {
        Action[] memory actions = new Action[](1);
        bytes[] memory params = new bytes[](1);
        actions[0] = Action.deposit;
        params[0] = abi.encode(100e6);

        USDC.transfer(address(strategyProxyFunctions), 100e6);
        strategyProxyFunctions.rebalance(actions, params);
        (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        ) = ILendingPool(AavePool).getUserAccountData(address(strategyProxyFunctions));
        assertGe(totalCollateralETH, 0);
        console.log(totalCollateralETH);
    }

    function testRebalanceDepositWithdraw() public {
        Action[] memory actions = new Action[](2);
        bytes[] memory params = new bytes[](2);
        actions[0] = Action.deposit;
        params[0] = abi.encode(100e6);
        actions[1] = Action.withdraw;
        params[1] = abi.encode(100e6);

        USDC.transfer(address(strategyProxyFunctions), 100e6);
        strategyProxyFunctions.rebalance(actions, params);
        (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        ) = ILendingPool(AavePool).getUserAccountData(address(strategyProxyFunctions));
        assertEq(totalCollateralETH, 0);
        console.log(totalCollateralETH);
    }


    function testRebalanceDepositBorrowRepay() public { 
        Action[] memory actions = new Action[](2);
        bytes[] memory params = new bytes[](2);
        actions[0] = Action.deposit;
        params[0] = abi.encode(100e6);
        actions[1] = Action.borrow;
        params[1] = abi.encode(10e18);

        USDC.transfer(address(strategyProxyFunctions), 100e6);
        strategyProxyFunctions.rebalance(actions, params);
        assertEq(WMATIC.balanceOf(address(strategyProxyFunctions)), 10e18);

        Action[] memory actions2 = new Action[](1);
        bytes[] memory params2 = new bytes[](1);
        actions2[0] = Action.repay;
        params2[0] = abi.encode(10e18);
        strategyProxyFunctions.rebalance(actions2, params2);
        assertEq(WMATIC.balanceOf(address(strategyProxyFunctions)), 0);
    }

    function testRebalanceJoinPool() public {
        Action[] memory actions = new Action[](1);
        bytes[] memory params = new bytes[](1);
        actions[0] = Action.join;
        params[0] = abi.encode(10000e6, 100e18, 1e6);

        USDC.transfer(address(strategyProxyFunctions), 10000e6);
        WMATIC.transfer(address(strategyProxyFunctions), 100e18);

        strategyProxyFunctions.rebalance(actions, params);
        // (
        // uint256 totalCollateralETH,
        // uint256 totalDebtETH,
        // uint256 availableBorrowsETH,
        // uint256 currentLiquidationThreshold,
        // uint256 ltv,
        // uint256 healthFactor
        // ) = ILendingPool(AavePool).getUserAccountData(address(strategyProxyFunctions));
        // assertGe(totalCollateralETH, 0);
        // console.log(totalCollateralETH);
    }
}