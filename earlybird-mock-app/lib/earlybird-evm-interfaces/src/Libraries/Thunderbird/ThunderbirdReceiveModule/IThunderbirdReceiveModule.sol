// src/Libraries/Thunderbird/ThunderbirdReceiveModule/IThunderbirdReceiveModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../ILibrary/IRequiredReceiveModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IThunderbirdReceiveModule
 * @notice - Interface for Thunderbird library's receive module
 */
interface IThunderbirdReceiveModule is IRequiredReceiveModuleFunctions {
    /**
     * @dev - Enum representing config type being updated
     * ORACLE_CHANGE - represents the app's oracle being updated.
     * RELAYER_CHANGE - represents the app's default relayer being updated.
     * RECS_CONTRACT_CHANGE - represents the app's default recommendations contract being updated.
     * MSG_PROOF_BROADCASTING_STATUS_CHANGE - represents the app's msg proof broadcast type being updated.
     * DIRECT_MSG_DELIVERY_STATUS_CHANGE - represents the app's direct msg delivery status being updated.
     * MSG_DELIVERY_PAUSED_STATUS_CHANGE - represents the app's msg delivery status being updated.
     * NONCE_CHANGE - represents the app's msg nonce being updated.
     */
    enum ConfigType {
        ORACLE_CHANGE,
        RELAYER_CHANGE,
        RECS_CONTRACT_CHANGE,
        MSG_PROOF_BROADCASTING_STATUS_CHANGE,
        DIRECT_MSG_DELIVERY_STATUS_CHANGE,
        MSG_DELIVERY_PAUSED_STATUS_CHANGE,
        NONCE_CHANGE
    }

    /**
     * @dev - Struct that represent protocol fee settings
     * feeOn - bool indicating whether protocol fees are on
     * feeTo - address indicating who protocol fees should be paid to.
     * collectInNativeToken - bool indicaitng whether protocol fees should be collected in native token.
     * nonNativeFeeToken - address indicating what non-native token protocol fees should be collected in if applicable.
     * amount - uint256 indicating amount of tokens that should be collected as fees.
     */
    struct ProtocolFeeSettings {
        bool feeOn;
        address feeTo;
        bool collectInNativeToken;
        address nonNativeFeeToken;
        uint256 amount;
    }

    /**
     * @dev - Struct that represents an app's setting within the Thunderbird receive module
     * oracle - address of app's selected oracle
     * relayer - address of app's selected relayer
     * recsContract - address of the contract we can call for recommendations for the values we should pass with the msg proof.
     *                i.e. msg revealed secret, recommended relayer.
     * emitMsgProofs - bool indicating whether the protocol should broadcast msg proofs when they are submitted by an oracle.
     * directMsgsEnabled - bool indicating whether the receive module should deliver messages to the app directly or not.
     * msgDeliveryPaused - bool indicating whether msg delivery is paused or not. If paused, the library will not accept new msg
     *                     proofs or deliver messages to the app.
     */
    struct AppSettings {
        address oracle;
        address relayer;
        address recsContract;
        bool emitMsgProofs;
        bool directMsgsEnabled;
        bool msgDeliveryPaused;
    }

    /**
     * @dev - Struct that represents a message that Thunderbird receive module failed to deliver.
     * failedMsgHash - bytes32 representing failed msg hash
     * fee - uint256 indicating fee caller must pay before they can deliver the new failed message.
     * relayerThatDeliveredMsg - address of relayer that tried delivering the message.
     *                           It also happens to be the address the fee with be paid to.
     */
    struct FailedMsg {
        bytes32 failedMsgHash;
        uint256 fee;
        address relayerThatDeliveredMsg;
    }

    /**
     * @dev - Struct that contains data that is encoded and hashed to create a msg proof
     * msgHash - byte32 indicating hash of the message being passed. Hash of the message emitted by the sender on the
     *           senders chain in the order it was emitted.
     * revealedMsgSecret - bytes array indicating a revealed secret the oracle must reveal about the message proof
     *                     it is passing. Value can be retrived from calling the app's recsContract. Messages
     *                     with invalid revealed msg secrets can be rejected by the app. Can be used by third party's recommended
     *                     relayers to self-select which message proofs to pay attention to.
     * senderChainId - uint256 indicating the sender's chain id.
     * isSelfBroadcastedMsg - bool indicating whether the message was self broadcasted or sent through the endpoint and broadcasted by the send library.
     * sender - bytes indicating the address of the sender. (bytes is used since the sender can be on an EVM or non-EVM chain)
     * sourceTxnHash - bytes indicating the source transaction hash
     */
    struct MsgProof {
        bytes32 msgHash;
        bytes32 revealedMsgSecret;
        uint256 senderChainId;
        bool isSelfBroadcastedMsg;
        bytes sender;
        bytes sourceTxnHash;
    }

    /**
     * @dev - Struct used to pass msg proofs by app.  This struct is the argument for submitMsgProofs().
     *        Plays a major role in how message proofs are stored in the library.
     * app - address of app who the messages are being delivered to.
     * indexToWriteInto - uint256 indicating the index that the hash of msgProofs should be written to.
     * msgProofs - array of MsgProof Bytes representing message proofs for messages that are being sent to the app.
     */
    struct MsgProofsByApp {
        address app;
        uint256 indexToWriteInto;
        MsgProof[] msgProofs;
    }

    /**
     * @dev - Struct used to pass msg by app.  This struct is the argument for submitMessages().
     * app - address of app who the messages are being delivered to.
     * senderChainId - uint256 indicating the index that the hash of msgProofs should be written to.
     * sender - array of MsgProof Bytes representing message proofs for messages that are being sent to the app.
     * msgsByAggregateProofs - array of msg proofs by aggregate proof hash.
     */
    struct MsgsByApp {
        address app;
        uint256 senderChainId;
        bytes sender;
        MsgsByAggregateProof[] msgsByAggregateProofs;
    }

    /**
     * @dev - Struct used to pass msgs by aggregate proof.  This struct is a field in MsgsByApp which is used in submitMessages.
     * @param aggregateMsgProofHashIndex - uint256 indicating the index of the aggregate msg proof hash
     * @param msgProofHashes - array of bytes32 that indicate hash of msg proofs that were submitted and
     *                         used to create the aggregate msg proof hash
     * @param msgs - Array of MsgData that can be used to recreate msgs and their msg proofs.
     */
    struct MsgsByAggregateProof {
        uint256 aggregateMsgProofHashIndex;
        bytes32[] msgProofHashes;
        MsgData[] msgs;
    }

    /**
     * @dev - Struct used to pass msg data that be used to recreate msgs and their msg proofs.
     *        This struct is a field in MsgsByAggregateProof which is used in MsgsByApp which is used submitMessages.
     * @param individualMsgProofIndex - uint256 indicating the index of the msgs proof hash in the invidualMsgProofHashes
     *                                  array within MsgsByAggregateProof.
     * @param nonce - nonce of the msg
     * @param revealedMsgSecret - bytes32 indicating the revealed msg secret that was provided when supplying the message proof.
     * @param isOrderedMsg - bool indicating whether the msg is an ordered msg or not.
     * @param isSelfBroadcastedMsg - bool indicating that a message is a self broadcasted msg or not.
     * @param gas - the amount of gas the message should be passed with
     * @param failureFee - uint256 indicating the fee user must pay to resend the message if it fails
     * @param sourceTxnHash - bytes indicating the source transaction hash for the message.
     *                        This is used to generate the msg proof hash
     * @param payload - bytes indicating the actual msg payload
     */
    struct MsgData {
        uint256 individualMsgProofIndex;
        uint256 nonce;
        bytes32 revealedMsgSecret;
        bool isOrderedMsg;
        bool isSelfBroadcastedMsg;
        uint256 gas;
        uint256 failureFee;
        bytes sourceTxnHash;
        bytes payload;
    }

    /**
     * @dev - Event emitted when msg proofs are submitted
     * @param app - address of the app messages are being sent to.
     * @param indexWrittenTo - uint256 indicating the index the aggregate msg proof should be written into.
     * @param aggregateMsgProofsHash - bytes32 indicating the aggregate msg proof hash
     * @param msgProofs - array of MsgProof
     */
    event MsgProofsSubmitted(
        address indexed app,
        uint256 indexed indexWrittenTo,
        bytes32 indexed aggregateMsgProofsHash,
        MsgProof[] msgProofs
    );

    /**
     * @dev - Event emitted when msg proofs are submitted
     * @param app - address of the app messages are being sent to.
     * @param indexWrittenTo - uint256 indicating the index the aggregate msg proof should be written into.
     * @param aggregateMsgProofsHash - bytes32 indicating the aggregate msg proof hash
     */
    event MsgProofsSubmitted(
        address indexed app, uint256 indexed indexWrittenTo, bytes32 indexed aggregateMsgProofsHash
    );

    /**
     * @dev - Emitted when two aggregate msg proof hashes are merged
     * @param app - address of the app msg proofs are being merged.
     * @param firstAggregateMsgProofHashIndex - uint256 indicating the index of the first aggregate msg proof index.
     * @param secondAggregateMsgProofHashIndex - uint256 indicating the index of the second aggregate msg proof index.
     * @param msgProofsInFirstAggregateMsgProofHash - bytes32 array indicating the msg proofs in first aggregate msg proof.
     * @param msgProofsInSecondAggregateMsgProofHash - bytes32 array indicating the msg proofs in second aggregate msg proof.
     */
    event MergedAggregateMsgProofHashes(
        address indexed app,
        uint256 indexed firstAggregateMsgProofHashIndex,
        uint256 indexed secondAggregateMsgProofHashIndex,
        bytes32[] msgProofsInFirstAggregateMsgProofHash,
        bytes32[] msgProofsInSecondAggregateMsgProofHash
    );

    /**
     * @dev - Emitted when two aggregate msg proof hashes are merged
     * @param app - address of the app msg proofs are being merged.
     * @param aggregateMsgProofHash1Index - uint256 indicating aggregate msg proof hash 1's index
     * @param aggregateMsgProofHash2Index - uint256 indicating aggregate msg proof hash 2's index
     * @param aggregateMsgProofHash1 - bytes32 indicating aggregate msg proof hash 1.
     * @param aggregateMsgProofHash2 - bytes32 indicating aggregate msg proof hash 2.
     * @param msgProofsInAggregateMsgProofHash1 - bytes32 array indicating the msg proofs in aggregate msg proof hash 1
     * @param msgProofsInAggregateMsgProofHash2 - bytes32 array indicating the msg proofs in aggregate msg proof hash 2
     */
    event SplitAggregateMsgProofHash(
        address indexed app,
        uint256 indexed aggregateMsgProofHash1Index,
        uint256 indexed aggregateMsgProofHash2Index,
        bytes32 aggregateMsgProofHash1,
        bytes32 aggregateMsgProofHash2,
        bytes32[] msgProofsInAggregateMsgProofHash1,
        bytes32[] msgProofsInAggregateMsgProofHash2
    );

    /**
     * @dev - Emitted when some msg proofs in an aggregate msg proof hash are removed.
     * @param app - address of the app messages are being sent to.
     * @param aggregateMsgProofHashIndex - uint256 indicating the index that the aggregate msg proof is written into.
     * @param aggregateMsgProofHash - bytes32 indicating the aggregate msg proof hash.
     * @param msgProofsHashesInAggregateMsgProofHash - bytes32 array indicating the hashes of msg proofs in the
     *                                                 aggregate msg proof hash
     */
    event TrimmedAggregateMsgProofHash(
        address indexed app,
        uint256 indexed aggregateMsgProofHashIndex,
        bytes32 indexed aggregateMsgProofHash,
        bytes32[] msgProofsHashesInAggregateMsgProofHash
    );

    /**
     * @dev - Event emitted when msg are delivered
     * @param app - address of the app message was being sent to.
     * @param senderChainId - uint256 indicating the chain Id of the sender
     * @param sender - bytes array indicating the address of the sender
     * @param nonce - uint256 indicating the nonce of the failed msg
     * @param gasUsed - uint256 indicating how much gas was used for delivering msg
     */
    event MsgGasUsed(
        address indexed app, uint256 indexed senderChainId, bytes sender, uint256 nonce, uint256 gasUsed
    );

    /**
     * @dev - Event emitted when a message being delivered fails because it was submitted with wrong rec values.
     * @param app - address of the app message was being sent to.
     * @param senderChainId - uint256 indicating the chain Id of the sender
     * @param sender - bytes array indicating the address of the sender
     * @param nonce - uint256 indicating the nonce of the failed msg
     * @param msgProofHash - bytes32 indicating the msg's nsgProof hash
     */
    event MsgSubmittedWithWrongRecValues(
        address indexed app, uint256 indexed senderChainId, bytes sender, uint256 nonce, bytes32 msgProofHash
    );

    /**
     * @dev - Event emitted when a message being delivered fails because it was submitted by wrong relayer.
     * @param app - address of the app message was being sent to.
     * @param senderChainId - uint256 indicating the chain Id of the sender
     * @param sender - bytes array indicating the address of the sender
     * @param nonce - uint256 indicating the nonce of the failed msg
     * @param msgProofHash - bytes32 indicating the msg's nsgProof hash
     */
    event MsgSubmittedByWrongRelayer(
        address indexed app, uint256 indexed senderChainId, bytes sender, uint256 nonce, bytes32 msgProofHash
    );

    /**
     * @dev - Event emitted when a message being delivered fails.
     * @param app - address of the app message was being sent to.
     * @param senderChainId - uint256 indicating the chain Id of the sender
     * @param sender - bytes array indicating the address of the sender
     * @param nonce - uint256 indicating the nonce of the failed msg
     * @param payload - bytes array indicating the payload of the msg
     * @param additionalInfo - bytes array indicating additional info that was being passed along to the app.
     * @param failureFee - uint256 indicating the fee user must pay to resent message.
     */
    event MsgFailed(
        address indexed app,
        uint256 indexed senderChainId,
        bytes sender,
        uint256 nonce,
        bytes payload,
        bytes additionalInfo,
        uint256 failureFee
    );

    /**
     * @dev - Function that allows an app's oracle to submit message proofs.
     * @param _msgProofsByApp - Array of msg proofs by app.
     */
    function submitMessageProofs(MsgProofsByApp[] memory _msgProofsByApp) external payable;

    /**
     * @dev - Function that allows app's oracle to merge the msg proofs in two aggregate msg proof hashes together.
     *        The final merged aggregate msg proof is stored in the same slot as the first aggregate msg proof.
     * @param _app - address of the app msg proofs are being merged.
     * @param _firstAggregateMsgProofHashIndex - uint256 indicating the index of the first aggregate msg proof index.
     * @param _secondAggregateMsgProofHashIndex - uint256 indicating the index of the second aggregate msg proof index.
     * @param _msgProofsInFirstAggregateMsgProofHash - bytes32 array indicating the msg proofs in first aggregate msg proof.
     * @param _msgProofsInSecondAggregateMsgProofHash - bytes32 array indicating the msg proofs in second aggregate msg proof.
     */
    function mergeAggregateMsgProofHashes(
        address _app,
        uint256 _firstAggregateMsgProofHashIndex,
        uint256 _secondAggregateMsgProofHashIndex,
        bytes32[] memory _msgProofsInFirstAggregateMsgProofHash,
        bytes32[] memory _msgProofsInSecondAggregateMsgProofHash
    ) external;

    /**
     * @dev - Function that allows app's oracle to splits the msg proofs in an aggregate msg proof hash into two
     *        seperate aggregate msg proof hashes holding subset of the original.
     * @param _app - address of the app msg proofs are being split.
     * @param _aggregateMsgProofIndex - uint256 indicating the index of the aggregate msg proof we are splitting.
     * @param _msgProofsInAggregateMsgProofHash - bytes32 array indicating the msg proofs in aggregate msg proof
     *                                            we are splitting.
     * @param _indicesOfMsgProofsToKeepInAggregateMsgProofHash - uint256 array indicating indices of msg proofs
     *                                                           to keep in the original aggregate Msg Proof Hash.
     * @param _indicesOfMsgProofsToPutInNewAggregateMsgProofHash - uint256 array indicating indices of msg proofs to
     *                                                             put in the new aggregate msg proof hash we are creating.
     * @param _newAggregateMsgProofHashIndex - uint256 indicating the index of the new aggregate msg proof hash we created
     */
    function splitAggregateMsgProofHashes(
        address _app,
        uint256 _aggregateMsgProofIndex,
        bytes32[] memory _msgProofsInAggregateMsgProofHash,
        uint256[] memory _indicesOfMsgProofsToKeepInAggregateMsgProofHash,
        uint256[] memory _indicesOfMsgProofsToPutInNewAggregateMsgProofHash,
        uint256 _newAggregateMsgProofHashIndex
    ) external;

    /**
     * @dev - Function that allows the app's oracle to trims/removes some message proofs that are
     *        in an aggregate msg hash.
     * @param _app - address of the app msg proofs are being merged.
     * @param _aggregateMsgProofHashIndex - uint256 indicating the index of the first aggregate msg proof index.
     * @param _msgProofsInAggregateMsgProofHash - bytes32 array indicating the msg proofs in first
     *                                            aggregate msg proof.
     * @param _indicesOfMsgProofsInNewAggregateMsgProofHash - uint256 indicating the index of the second
     *                                                        aggregate msg proof index.
     */
    function trimMsgProofsInAggregateMsgProof(
        address _app,
        uint256 _aggregateMsgProofHashIndex,
        bytes32[] memory _msgProofsInAggregateMsgProofHash,
        uint256[] memory _indicesOfMsgProofsInNewAggregateMsgProofHash
    ) external;

    /**
     * @dev - Function that allows an app's relayer to submit messages.
     * @param _msgsByApps - Array of msgs by app.
     */
    function submitMessages(MsgsByApp[] memory _msgsByApps) external payable;
}
