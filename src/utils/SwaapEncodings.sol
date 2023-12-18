pragma solidity 0.8.18;
contract SwaapEncodings {   

    /*//////////////////////////////////////////////////////////////
                         Join 
    //////////////////////////////////////////////////////////////*/

    // Swaap only supports Exact Tokens Join and Proportional Join
    // Enum structure for Swaap USDC-MATIC pool :  enum JoinKind { INIT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT, EXACT_TOKENS_IN_FOR_BPT_OUT }
    
    // Proportional Join
    // User sends estimated but unknown (computed at run time) quantities of tokens, and receives precise quantity of BPT.
    // ['uint256', 'uint256']
    // [ALL_TOKENS_IN_FOR_EXACT_BPT_OUT, bptAmountOut]
    
    function getUserDataForProportionalJoin(uint256 bptAmountOut) internal view returns (bytes memory)
    {
        return abi.encode(uint256(1), bptAmountOut);
    }

    // Exact Tokens Join
    // User sends precise quantities of tokens, and receives an estimated but unknown (computed at run time) quantity of BPT.
    // ['uint256', 'uint256[]', 'uint256']
    // [EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minimumBPT]

    function getUserDataForExactJoin(uint256 amount0, uint256 amount1, uint256 minimumBPT) internal view returns (bytes memory)
    {
        return abi.encode(uint256(2), [amount0, amount1], minimumBPT);
    }


    /*//////////////////////////////////////////////////////////////
                         Exit 
    //////////////////////////////////////////////////////////////*/
    // enum ExitKind { EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }
 }