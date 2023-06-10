// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {IVotes, GovernorVotes, GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract PonziRepGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotesQuorumFraction
{
    constructor(
        string memory name_,
        address tokenAddress_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 quorumNumerator_
    )
        Governor(name_)
        GovernorSettings(votingDelay_, votingPeriod_, 1)
        GovernorVotes(IVotes(tokenAddress_))
        GovernorVotesQuorumFraction(quorumNumerator_)
    {
        require(votingDelay_ != 0, "Voting delay must be nonzero");
        require(votingPeriod_ != 0, "Voting period must be nonzero");
        require(quorumNumerator_ != 0, "Quorum numerator must be nonzero");
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return GovernorSettings.proposalThreshold();
    }
}
