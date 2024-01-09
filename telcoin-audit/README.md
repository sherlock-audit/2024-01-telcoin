# Telcoin Contracts

![hardhat](https://img.shields.io/badge/hardhat-2.19.4-blue)
![please](https://img.shields.io/badge/node-v18.10.0-brightgreen.svg)
![solidity](https://img.shields.io/badge/solidity-0.8.23-red)
![coverage](https://img.shields.io/badge/coverage->80%25-yellowgreen)
![comments](https://img.shields.io/badge/comments->80%25-yellowgreen)

**Telcoin** is designed to complement telecom, mobile money, and e-wallet partners globally with both traditional fiat and blockchain transaction rails that underpin our fast and affordable digital financial service offerings. Telcoin combines the best parts of the burgeoning DeFi ecosystem with our compliance-first approach to each market, ensuring that the company takes on a fraction of traditional financial counter-party, execution, and custody risks.

## Running Tests

To get started, all you should need to install dependencies and run the unit tests are here.

```shell
npm install
npm test
```

Under the hood `npm test` is running `npx hardhat clean && npx hardhat coverage`

For a quicker unit test run:

```shell
npx hardhat test
```

### Notes

`Test` contracts are dummy contracts created for testing and are outside the scope of the audit. `Mock` contracts are created to be tested in place of the real contract. This is done for testing ease. In some cases using a slightly altered version is significantly simpler to test.

### Version

`nvm` use will switch to node `v18.10.0`

## References

- [Sablier](https://app.sablier.com)
  - [Docs](https://docs.sablier.com)
  - [GitHub](https://github.com/sablier-labs)
- [Snapshot](https://snapshot.org/#/)
  - [Docs](https://docs.snapshot.org)
  - [GitHub](https://github.com/snapshot-labs)
- [Synthetix](https://snapshot.org/#/)
  - [Docs](https://developer.synthetix.io)
  - [GitHub](https://github.com/Synthetixio)
- [Gnosis](https://www.gnosisguild.org)
  - [Zodiac Docs](https://zodiac.wiki/index.php/ZODIAC.WIKI)
  - [Reality Docs](https://zodiac.wiki/index.php/Category:Reality_Module)
  - [Zodiac GitHub](https://github.com/gnosis/zodiac)
  - [Reality GitHub](https://github.com/gnosis/zodiac-module-reality)

```txt
                                     ttttttttttttttt,                           
                              *tttttttttttttttttttttttt,                        
                       *tttttttttttttttttttttttttttttttttt,                     
                ,tttttttttttttttttttttttttttttttttttttttttttt,                  
          .ttttttttttttttttttttttttttttttttttttttttttttttttttttt.               
        ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt.            
       ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt.         
      ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt       
     .ttttttttttttttttttttttttttttttttt    ttttttttttttttttttttttttttttttttt.   
     tttttttttttttttttttttttttttttttt     *ttttttttttttttttttttttttttttttttttt. 
     ttttttttttttttttttttttttttttt.       ttttttttttttttttttttttttttttttttttttt,
    *ttttttttttttttttttttttttt,          ************ttttttttttttttttttttttttttt
    tttttttttttttttttttttttt                        tttttttttttttttttttttttttttt
   *ttttttttttttttttttttttt*                        ttttttttttttttttttttttttttt,
   ttttttttttttttttttttttttttttt        *tttttttttttttttttttttttttttttttttttttt 
  ,tttttttttttttttttttttttttttt,       ,tttttttttttttttttttttttttttttttttttttt* 
  ttttttttttttttttttttttttttttt        ttttttttttttttttttttttttttttttttttttttt  
  tttttttttttttttttttttttttttt.       ,ttttttttttttttttttttttttttttttttttttttt  
 ttttttttttttttttttttttttttttt        ttttttttttttttttttttttttttttttttttttttt   
 ttttttttttttttttttttttttttttt        ttttttttttttttttttttttttttttttttttttttt   
 ttttttttttttttttttttttttttttt         *********tttttttttttttttttttttttttttt.   
 ttttttttttttttttttttttttttttt*                 tttttttttttttttttttttttttttt    
  *ttttttttttttttttttttttttttttt               tttttttttttttttttttttttttttt*    
    .tttttttttttttttttttttttttttttttttttttttttt*ttttttttttttttttttttttttttt     
       .ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt     
          .ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt      
             .tttttttttttttttttttttttttttttttttttttttttttttttttttttttttt,       
                .ttttttttttttttttttttttttttttttttttttttttttttttttttttt          
                   ,ttttttttttttttttttttttttttttttttttttttttttt*                
                      ,ttttttttttttttttttttttttttttttttt*                       
                         ,tttttttttttttttttttttttt.                             
                            ,*ttttttttttttt.                                    
```
