// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC20, ERC20Permit, ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract PonziRep is ERC20Votes {
    using Strings for address;

    struct TradeOffer {
        uint256 uReceive;
        uint256 iReceive;
        bool isFinalised;
    }

    mapping(address => uint256) public userTradeNonce;
    mapping(address => mapping(uint256 => TradeOffer)) public tradeOffers;
    address public governor;
    mapping(address => bool) public shunned;

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

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
    {}

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

    function createTradeOffer(uint256 uReceive, uint256 iReceive)
        external
        payable
    {
        require(msg.value >= uReceive, "Not enough ETH deposited");
        _assertNotShunned(msg.sender);
        uint256 nonce = userTradeNonce[msg.sender]++;
        tradeOffers[msg.sender][nonce] = (
            TradeOffer({
                uReceive: uReceive,
                iReceive: iReceive,
                isFinalised: false
            })
        );
        emit TradeOfferCreated(msg.sender, nonce, uReceive, iReceive);
    }

    function withdrawTradeOffer(uint256 nonce) external {
        TradeOffer memory tradeOffer = tradeOffers[msg.sender][nonce];
        require(!tradeOffer.isFinalised, "Trade already finalised");
        delete tradeOffers[msg.sender][nonce];
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
        bytes32 msgHash = keccak256(
            abi.encode(offerCreator, offerCreatorNonce)
        );
        address cryptoSide = recoverSigner(msgHash, sigCryptoSide);
        address fiatSide = recoverSigner(msgHash, sigFiatSide);
        _assertNotShunned(cryptoSide);
        _assertNotShunned(fiatSide);

        TradeOffer storage tradeOffer = tradeOffers[cryptoSide][
            offerCreatorNonce
        ];
        require(!tradeOffer.isFinalised, "Offer already finalised");
        tradeOffer.isFinalised = true;
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
    }

    function shun(address naughtyBoy) external onlyGovernance {
        ERC20Votes._burn(naughtyBoy, balanceOf(naughtyBoy));
        shunned[naughtyBoy] = true;
        emit AtInverseBrah(naughtyBoy);
    }

    /// @notice Social capital can't be transferred
    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        revert("lol no");
    }
}
