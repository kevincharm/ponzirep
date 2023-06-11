// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC20, ERC20Permit, ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Sets} from "./Sets.sol";

contract PonziRep is ERC20Votes {
    using Strings for address;
    using Strings for uint256;
    using Sets for Sets.Set;

    enum TradeOfferStatus {
        Uninitialised, /** Empty state; trade does not exist */
        Initialised, /** Initialised and waiting for counterparty to commit */
        Finalised, /** Done */
        Cancelled
    }

    struct TradeOffer {
        uint256 uReceive;
        uint256 iReceive;
        TradeOfferStatus status;
    }

    mapping(address => uint256) public userTradeNonce;
    mapping(bytes32 => TradeOffer) public tradeOffers;
    Sets.Set private tradeOffersSet;
    address public governor;
    mapping(address => bool) public shunned;
    // referree (address that got referred) -> referrer
    mapping(address => address) public referrers;

    event TradeOfferCreated(
        address indexed offerer,
        uint256 nonce,
        uint256 uReceive,
        uint256 iReceive
    );
    event TradeOfferFinalised(
        address indexed offerer,
        uint256 nonce,
        uint256 uReceive,
        uint256 iReceive
    );
    event TradeOfferWithdrawn(address indexed cryptoSide, uint256 nonce);
    event AtInverseBrah(address rekt);

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory fundingFathers
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        tradeOffersSet.init();
        require(fundingFathers.length >= 5, "Not enough funding fathers");
        // The funding fathers get a premine
        for (uint256 i; i < fundingFathers.length; ++i) {
            _mint(fundingFathers[i], 10e18);
        }
    }

    // TODO: Limit this to onlyOwner or something
    function setGovernance(address governor_) external {
        require(governor == address(0), "Governor already set");
        governor = governor_;
    }

    modifier onlyGovernance() {
        require(msg.sender == governor, "Caller is not governor");
        _;
    }

    function _assertNotShunned(address guy) internal view {
        require(
            !shunned[guy],
            string(abi.encodePacked(guy.toHexString(), " is a social outcast"))
        );
    }

    function invite(address noob) external {
        // Only members with a certain threshold (let's say 10PP) can invite
        // new members to the community. Then they become the referral that
        // receives 50% of any social capital awarded from trades of the
        // referee.
        require(balanceOf(msg.sender) >= 10e18, "Not enough social capital");
        referrers[noob] = msg.sender;
        // Mint 1 PP
        _mint(noob, 1e18);
    }

    function createTradeOffer(uint256 uReceive, uint256 iReceive)
        external
        payable
    {
        require(balanceOf(msg.sender) >= 1e18, "Not enough social capital");
        require(msg.value >= uReceive, "Not enough ETH deposited");
        _assertNotShunned(msg.sender);
        uint256 nonce = userTradeNonce[msg.sender]++;
        bytes32 tradeOfferId = keccak256(abi.encode(msg.sender, nonce));
        tradeOffers[tradeOfferId] = (
            TradeOffer({
                uReceive: uReceive,
                iReceive: iReceive,
                status: TradeOfferStatus.Initialised
            })
        );
        tradeOffersSet.add(keccak256(abi.encode(msg.sender, nonce)));
        emit TradeOfferCreated(msg.sender, nonce, uReceive, iReceive);
    }

    function withdrawTradeOffer(uint256 nonce) external {
        TradeOffer storage tradeOffer = tradeOffers[
            keccak256(abi.encode(msg.sender, nonce))
        ];
        require(
            tradeOffer.status == TradeOfferStatus.Initialised,
            "Offer not initialised"
        );
        tradeOffer.status = TradeOfferStatus.Cancelled;
        (bool success, ) = msg.sender.call{value: tradeOffer.uReceive}("");
        require(success, "Refund failed");
        emit TradeOfferWithdrawn(msg.sender, nonce);
    }

    function recoverSigner(bytes32 messageHash, bytes calldata sig)
        internal
        pure
        returns (address)
    {
        uint8 v = uint8(bytes1(sig[0:1]));
        bytes32 r = bytes32(sig[1:33]);
        bytes32 s = bytes32(sig[33:65]);
        return ECDSA.recover(messageHash, v, r, s);
    }

    function finaliseTrade(
        address offerCreator,
        uint256 offerCreatorNonce,
        bytes calldata sigCryptoSide,
        bytes calldata sigFiatSide
    ) external {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "FinaliseTrade(address offerCreator,uint256 offerCreatorNonce)"
                    ),
                    offerCreator,
                    offerCreatorNonce
                )
            )
        );
        address cryptoSide = recoverSigner(digest, sigCryptoSide);
        address fiatSide = recoverSigner(digest, sigFiatSide);
        require(
            balanceOf(cryptoSide) >= 1 && balanceOf(fiatSide) >= 1,
            "One side of trade is a social outcast"
        );
        _assertNotShunned(cryptoSide);
        _assertNotShunned(fiatSide);

        TradeOffer storage tradeOffer = tradeOffers[
            keccak256(abi.encode(cryptoSide, offerCreatorNonce))
        ];
        require(
            tradeOffer.status == TradeOfferStatus.Initialised,
            "Offer not initialised"
        );
        tradeOffer.status = TradeOfferStatus.Finalised;
        (bool success, ) = payable(fiatSide).call{value: tradeOffer.uReceive}(
            ""
        );
        require(success, "Payment failed");
        emit TradeOfferFinalised(
            cryptoSide,
            offerCreatorNonce,
            tradeOffer.uReceive,
            tradeOffer.iReceive
        );

        // +1 social credit (bing chilling)
        ERC20Votes._mint(cryptoSide, 1e18);
        ERC20Votes._mint(fiatSide, 1e18);

        // +0.5 social credit to the referrers (next LEVEL up)
        // NB:
        //  - referrer might be zero address (funding fathers)
        //  - referrer might be shunned
        address cryptoSideReferrer = referrers[cryptoSide];
        if (cryptoSideReferrer != address(0) && !shunned[cryptoSideReferrer]) {
            ERC20Votes._mint(cryptoSide, 1e18 / 2);
        }
        address fiatSideReferrer = referrers[fiatSide];
        if (fiatSideReferrer != address(0) && !shunned[fiatSideReferrer]) {
            ERC20Votes._mint(fiatSide, 1e18 / 2);
        }
    }

    function shun(address naughtyBoy) external onlyGovernance {
        ERC20Votes._burn(naughtyBoy, balanceOf(naughtyBoy));
        shunned[naughtyBoy] = true;
        emit AtInverseBrah(naughtyBoy);
    }

    /// @notice Social capital can't be transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        bool isMint = from == address(0);
        bool isBurn = to == address(0);
        if (!isMint && !isBurn) {
            revert("lol no");
        }
    }

    function getTradesCount() external view returns (uint256) {
        return tradeOffersSet.size;
    }

    /// @notice Returns all trades regardless of their status (#yolonoindexer)
    function getTrades() external view returns (TradeOffer[] memory out) {
        uint256 size = tradeOffersSet.size;
        if (size == 0) {
            return new TradeOffer[](0);
        }

        out = new TradeOffer[](size);
        bytes32 element = tradeOffersSet.tail();
        for (uint256 i; i < size; ++i) {
            out[size - i - 1] = tradeOffers[element];
            element = tradeOffersSet.prev(element);
        }
        return out;
    }
}
