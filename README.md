![On (1)](https://github.com/chrisckwong821/Yearn-Swaap-VaultV3/assets/46760063/b9afbb57-1aba-4b72-8894-c4255c803f02)

# YearnV3 Swaap Strategy
### Description : [<img src="https://github.com/chrisckwong821/Yearn-Swaap-VaultV3/assets/46760063/fd390e5c-b96b-4739-a40d-3b98a0c4965b" width="30px">](https://docs.google.com/document/d/1vwDHR1XDhflGrWFtU8cfNUQPEMmlLKfm/edit#heading=h.lws6qfu8qwsl)
### Strategy Behaviour (Video) : [<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/YouTube_play_button_icon_%282013%E2%80%932017%29.svg/1280px-YouTube_play_button_icon_%282013%E2%80%932017%29.svg.png" width="30px">](https://drive.google.com/file/d/1nvQA_QubLmjkKfb9GH1yEnJQVjA59p0K/view?usp=sharing)

## Contracts
```
./src
Interfaces.sol : Common file for all user interfaces
SwaapEncodings.sol : Swaap specific encodings for join and exit pool
SwaapStrategy.sol: MAIN CONTRACT, (Proxy Contract for SwaapStrategyImplV1, Inherits Base Strategy)
SwaapStrategyImplV1.sol: Just place holder for Yearn's TokenizedStrategy Implementation
```
### Installation and Tests 
```
forge build 
forge test 
// all test files reside in ./src/test
```

## Disclaimer (Security)
We have tested the happy scenarios, but thorough testing of all edge cases is needed before using this strategy live.</br>
We strongly advise against using this code in its current form on the mainnet.</br>
The main purpose of this repository was to demonstrate a proof-of-concept for the Yearn Swaap strategy on Polygon for the Yearn Hackathon and gauge the response.</br>
We have also made some trust assumptions, which we have marked with the "@audit" tag as comments in the contracts. </br>
Some of these assumptions are precautionary, while others must be carefully considered before actively using this strategy.</br>

## Future Vision 
Depending upon feedback from you all, if we are confident that users would love to use this, we can continue the development of this strategy. </br>
Initially, we will prioritize testing all scenarios and reviewing our assumptions.</br>
Subsequently, we intend to implement some improvements into the current strategies and a DOUBLE strategy as demonstrated in the following video.</br>
**Future implementations** : [<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/YouTube_play_button_icon_%282013%E2%80%932017%29.svg/1280px-YouTube_play_button_icon_%282013%E2%80%932017%29.svg.png" width="30px">](https://drive.google.com/file/d/1NthnMwXqwwoR442BtO1iS9nsBSPfBOKy/view?usp=drive_link)
