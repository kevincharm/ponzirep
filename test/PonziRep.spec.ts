import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { PonziRepGovernor__factory, PonziRep__factory } from '../typechain-types'
import { ethers } from 'hardhat'
import { parseEther, solidityKeccak256, splitSignature } from 'ethers/lib/utils'
import { expect } from 'chai'

const VOTING_DELAY = 5 // BLOCKS
const VOTING_PERIOD = 12 // BLOCKS
const QUORUM_NUMERATOR = 10 // 10%

function splitAndCombineSigs(sig: string) {
    const { v, r, s } = splitSignature(sig)
    return ethers.utils.solidityPack(['uint8', 'bytes32', 'bytes32'], [v, r, s])
}

describe('PonziRep', () => {
    let deployer: SignerWithAddress
    let bob1: SignerWithAddress
    let bob2: SignerWithAddress
    let bob3: SignerWithAddress
    let bob4: SignerWithAddress
    let bob5: SignerWithAddress
    let alice: SignerWithAddress
    beforeEach(async () => {
        ;[deployer, bob1, bob2, bob3, bob4, bob5, alice] = await ethers.getSigners()
    })

    it('should p2p e2e', async () => {
        const ponzirep = await new PonziRep__factory(deployer).deploy('PonziRep', 'PP', [
            bob1.address,
            bob2.address,
            bob3.address,
            bob4.address,
            bob5.address,
        ])
        const gov = await new PonziRepGovernor__factory(deployer).deploy(
            'Church of Ponzology',
            ponzirep.address,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_NUMERATOR
        )
        await ponzirep.setGovernance(gov.address)

        // Create trade
        const nonce = await ponzirep.nonces(bob1.address)
        await ponzirep.connect(bob1).createTradeOffer(parseEther('1.0'), parseEther('1800'), {
            value: parseEther('1.0'), // must agree with `uReceive`
        })
        expect(await ponzirep.getTradesCount()).to.eq(1)
        console.log(await ponzirep.getTrades())
        const tradeOfferId = ethers.utils.keccak256(
            ethers.utils.defaultAbiCoder.encode(['address', 'uint256'], [bob1.address, nonce])
        )
        expect((await ponzirep.tradeOffers(tradeOfferId)).status).to.deep.eq(1) // Initialised

        // // Try withdraw
        // await ponzirep.connect(bob1).withdrawTradeOffer(nonce)
        // expect((await ponzirep.tradeOffers(tradeOfferId)).status).to.eq(3)

        // bob1 and bob2 agree on trade
        const { chainId } = await ethers.provider.getNetwork()
        const bob1Sig = splitAndCombineSigs(
            await bob1._signTypedData(
                {
                    name: 'PonziRep',
                    version: '1',
                    chainId,
                    verifyingContract: ponzirep.address,
                },
                {
                    FinaliseTrade: [
                        { name: 'offerCreator', type: 'address' },
                        { name: 'offerCreatorNonce', type: 'uint256' },
                    ],
                },
                {
                    offerCreator: bob1.address,
                    offerCreatorNonce: nonce,
                }
            )
        )
        const bob2Sig = splitAndCombineSigs(
            await bob2._signTypedData(
                {
                    name: 'PonziRep',
                    version: '1',
                    chainId,
                    verifyingContract: ponzirep.address,
                },
                {
                    FinaliseTrade: [
                        { name: 'offerCreator', type: 'address' },
                        { name: 'offerCreatorNonce', type: 'uint256' },
                    ],
                },
                {
                    offerCreator: bob1.address,
                    offerCreatorNonce: nonce,
                }
            )
        )
        await ponzirep.finaliseTrade(bob1.address, nonce, bob1Sig, bob2Sig)
        expect((await ponzirep.tradeOffers(tradeOfferId)).status).to.eq(2) // Finalised
    })
})
