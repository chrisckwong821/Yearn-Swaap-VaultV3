
import {ERC20} from "lib/tokenized-strategy/src/BaseStrategy.sol";

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
