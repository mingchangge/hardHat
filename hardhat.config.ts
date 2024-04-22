import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
require('dotenv').config()

const INFURA_API_KEY = process.env.INFURA_API_KEY || ''
const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY || ''
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || 'key'
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || 'key'
const config: HardhatUserConfig = {
  solidity: '0.8.24',
  defaultNetwork: 'hardhat',
  networks: {
    localhost: {
      url: 'http://localhost:8545'
    }
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [`0x${RINKEBY_PRIVATE_KEY}`],
    // },
  }
}

export default config
