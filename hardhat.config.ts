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
        xdai: {
            url: process.env.XDAI_URL as string,
            chainId: 0x64,
            accounts: [process.env.MAINNET_PK as string],
        },
        optimism: {
            url: process.env.OPTIMISM_URL as string,
            chainId: 10,
            accounts: [process.env.MAINNET_PK as string],
        },
        scrollAlpha: {
            url: 'https://alpha-rpc.scroll.io/l2',
            chainId: 534353,
            accounts: [process.env.MAINNET_PK as string],
        },
        mantleTestnet: {
            url: 'https://rpc.testnet.mantle.xyz',
            chainId: 5001,
            accounts: [process.env.MAINNET_PK as string],
        },
        taikoTestnet: {
            url: 'https://rpc.test.taiko.xyz',
            chainId: 167005,
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
            gnosis: process.env.GNOSISSCAN_API_KEY as string,
            optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY as string,
            scrollAlpha: 'abcdef',
            mantleTestnet: 'abcdef',
            taikoTestnet: 'abcdef',
        },
        customChains: [
            {
                network: 'scrollAlpha',
                chainId: 534353,
                urls: {
                    apiURL: 'https://blockscout.scroll.io/api',
                    browserURL: 'https://blockscout.scroll.io',
                },
            },
            {
                network: 'mantleTestnet',
                chainId: 5001,
                urls: {
                    apiURL: 'https://explorer.testnet.mantle.xyz/api',
                    browserURL: 'https://explorer.testnet.mantle.xyz',
                },
            },
            {
                network: 'taikoTestnet',
                chainId: 167005,
                urls: {
                    apiURL: 'https://explorer.test.taiko.xyz/api',
                    browserURL: 'https://explorer.test.taiko.xyz',
                },
            },
        ],
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
