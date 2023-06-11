import { ethers } from 'hardhat'
import { PonziRepGovernor__factory, PonziRep__factory } from '../typechain-types'

const VOTING_DELAY = 5 // BLOCKS
const VOTING_PERIOD = 12 // BLOCKS
const QUORUM_NUMERATOR = 10 // 10%

export async function deploy() {
    const [deployer, bobTheBuilder, bobRoss, bobMarley, bobsYourUncle, sideshowBob] =
        await ethers.getSigners()

    // Deploy PonziRep social capital token
    const ponzirepArgs: Parameters<PonziRep__factory['deploy']> = [
        'PonziRep',
        'PP',
        [
            bobTheBuilder.address,
            bobRoss.address,
            bobMarley.address,
            bobsYourUncle.address,
            sideshowBob.address,
        ],
    ]
    const ponzirep = await new PonziRep__factory(deployer).deploy(...ponzirepArgs)
    console.log(`Deployed PonziRep to: ${ponzirep.address}`)

    // Deploy governor
    const governorArgs: Parameters<PonziRepGovernor__factory['deploy']> = [
        'Church of Ponzology',
        ponzirep.address,
        VOTING_DELAY,
        VOTING_PERIOD,
        QUORUM_NUMERATOR,
    ]
    const governor = await new PonziRepGovernor__factory(deployer).deploy(...governorArgs)
    console.log(`Deployed PonziRepGovernor to: ${governor.address}`)

    // Set gov (permanent)
    await ponzirep.setGovernance(governor.address)
    console.log(`Set ponzirep governor to: ${governor.address}`)
}

deploy()
    .then(() => {
        console.log('Done')
    })
    .catch((err) => {
        console.error(err)
    })
