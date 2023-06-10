import * as dotenv from 'dotenv'

import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomiclabs/hardhat-etherscan'
import 'hardhat-storage-layout'
import 'hardhat-contract-sizer'
import 'hardhat-storage-layout-changes'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import 'hardhat-abi-exporter'

dotenv.config()

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.18',
        settings: {
            viaIR: false,
            optimizer: {
                enabled: true,
                runs: 1000,
                details: {
                    yul: false,
                },
            },
        },
    },
    networks: {
        hardhat: {
            chainId: 137,
            forking: {
                enabled: true,
                url: process.env.MATIC_URL as string,
                blockNumber: 43532937,
            },
            accounts: {
                count: 10,
            },
        },
        matic: {
            url: process.env.MATIC_URL as string,
            chainId: 137,
            accounts: [process.env.MAINNET_PK as string],
        },
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        gasPrice: 60,
    },
    etherscan: {
        apiKey: {
            polygon: process.env.POLYGONSCAN_API_KEY!,
        },
    },
    paths: {
        storageLayouts: '.storage-layouts',
    },
    storageLayoutChanges: {
        contracts: ['PonziRep'],
        fullPath: false,
    },
    abiExporter: {
        path: './exported-abi',
        runOnCompile: true,
        clear: true,
        flat: true,
        only: ['PonziRep'],
        spacing: 2,
    },
}

export default config