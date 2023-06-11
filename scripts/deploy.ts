import { ethers, run } from 'hardhat'
import { PonziRepGovernor__factory, PonziRep__factory } from '../typechain-types'
import { parseUnits } from 'ethers/lib/utils'

const VOTING_DELAY = 5 // BLOCKS
const VOTING_PERIOD = 12 // BLOCKS
const QUORUM_NUMERATOR = 10 // 10%
const FUNDING_FATHERS = [
    '0xFd37f4625CA5816157D55a5b3F7Dd8DD5F8a0C2F',
    '0x77fb4fa1ABA92576942aD34BC47834059b84e693',
    '0x84e1056eD1B76fB03b43e924EF98833dBA394b2B',
    '0x55F5429343891f0a2b2A8da63a48E82DA8D9f2F6',
    '0x4fFACe9865bDCBc0b36ec881Fa27803046A88736',
]

export async function deploy() {
    const [deployer, bobTheBuilder, bobRoss, bobMarley, bobsYourUncle, sideshowBob] =
        await ethers.getSigners()

    // Deploy PonziRep social capital token
    const ponzirepArgs: Parameters<PonziRep__factory['deploy']> = [
        'PonziRep',
        'PP',
        FUNDING_FATHERS,
    ]
    const ponzirep = await new PonziRep__factory(deployer).deploy(...ponzirepArgs)
    // const ponzirep = await new PonziRep__factory(deployer).attach(
    //     '0x9309bd93a8b662d315Ce0D43bb95984694F120Cb'
    // )
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
    // const governor = await new PonziRepGovernor__factory(deployer).attach(
    //     '0xb3a2EAB23AdC21eA78e1851Dd4b1316cb2275D9E'
    // )
    console.log(`Deployed PonziRepGovernor to: ${governor.address}`)

    // Set gov (permanent)
    await ponzirep.setGovernance(governor.address)
    console.log(`Set ponzirep governor to: ${governor.address}`)

    await new Promise((resolve) => setTimeout(resolve, 60_000)) // wait 1 min for Gnosisscan to update
    await run('verify:verify', {
        address: ponzirep.address,
        constructorArguments: ponzirepArgs,
    })
    await run('verify:verify', {
        address: governor.address,
        constructorArguments: governorArgs,
    })

    console.log('Verified on Gnosisscan.')
}

deploy()
    .then(() => {
        console.log('Done')
    })
    .catch((err) => {
        console.error(err)
    })
