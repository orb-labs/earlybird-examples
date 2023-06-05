// src/Libraries/Rukh/RukhReceiveModule/IRukhReceiveModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../ILibrary/IRequiredReceiveModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IRukhReceiveModule
 * @notice - Interface for Rukh library's receive module
 */
interface IRukhReceiveModule is IRequiredReceiveModuleFunctions {
    /**
     * @dev - Enum representing config type being updated
     * MIN_DISPUTE_TIME_CHANGE - represents the app's minimum dispute time as the variable being updated.
     * MIN_DISPUTE_RESOLUTION_EXTENSION_CHANGE - represents the app's dispute resolution extension period being updated.
     * DISPUTE_EPOCH_LENGTH_CHANGE - represents the app's dispute epoch length being updated.
     * MAX_VALID_DISPUTES_PER_EPOCH_CHANGE - represents the app's maximum number of valid disputes per epoch being updated.
     * ORACLE_CHANGE - represents the app's oracle being updated.
     * DEFAULT_RELAYER_CHANGE - represents the app's default relayer being updated.
     * DISPUTERS_CONTRACT_CHANGE - represents that the app's disputers contract is being updated.
     * DISPUTE_RESOLVER_CHANGE - represents the app's dispute resolver being updated.
     * RECS_CONTRACT_CHANGE - represents the app's recs contract being updated.
     * MSG_PROOF_BROADCASTING_STATUS_CHANGE - represents the app's msg proof broadcast type being updated.
     * DIRECT_MSG_DELIVERY_STATUS_CHANGE - represents the app's direct msg delivery status being updated.
     * MSG_DELIVERY_PAUSED_STATUS_CHANGE - represents the app's msg delivery status being updated.
     * ORDERED_MSG_NONCE_CHANGE - represents the app's ordered msg nonce being updated.
     */
    enum ConfigType {
        MIN_DISPUTE_TIME_CHANGE,
        MIN_DISPUTE_RESOLUTION_EXTENSION_CHANGE,
        DISPUTE_EPOCH_LENGTH_CHANGE,
        MAX_VALID_DISPUTES_PER_EPOCH_CHANGE,
        ORACLE_CHANGE,
        DEFAULT_RELAYER_CHANGE,
        DISPUTERS_CONTRACT_CHANGE,
        DISPUTE_RESOLVER_CHANGE,
        RECS_CONTRACT_CHANGE,
        MSG_PROOF_BROADCASTING_STATUS_CHANGE,
        DIRECT_MSG_DELIVERY_STATUS_CHANGE,
        MSG_DELIVERY_PAUSED_STATUS_CHANGE,
        ORDERED_MSG_NONCE_CHANGE
    }

    /**
     * @dev - Enum representing dispute verdicts from the dispute resolver.
     * UNDECIDED - indicates a dispute verdict has not be supplied.
     * MSG_PROOF_VALID - indicates that the msg that was disputed is actually valid.
     * MSG_PROOF_INVALID - indicates that the msg that was disputed is invalid.
     */
    enum DisputeVerdictType {
        UNDECIDED,
        MSG_PROOF_VALID,
        MSG_PROOF_INVALID
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
     * @dev - Struct that represents an app's setting within the Rukh receive module
     * minDisputeTime - uint256 indicating the minimum dispute time for each message.
     *                  The recommended dispute time passed by the oracle must exceed this number.
     * minDisputeResolutionExtension - uint256 indicating how long the dispute resolution period should be extended after each dispute.
     * disputeEpochLength - uint256 indicating the number of blocks in a dispute epoch.
     * maxValidDisputesPerEpoch - uint256 indicating the maximum number of valid disputes that can occur in a dispute
     *                            epoch before the library assumes that the oracle has been compromised and pauses msg delivery.
     * oracle - address of app's selected oracle
     * defaultRelayer - address of app's default relayer.  The default relayer is typically responsible for passing
     *                  messages to the app except if the application has configured another relayer to pass messages
     *                  through the variable configs contract.
     * disputersContract - address of app's disputers contract.
     * disputeResolver - address of the app's dispute resolver.
     * recsContract - address of the contract we can call for recommendations for the values we should pass with the msg proof.
     *                i.e. recommended dispute time, msg revealed secret, recommended relayer.
     * emitMsgProofs - bool indicating whether the protocol should broadcast contents of msg proofs when an oracle submits them.
     * directMsgsEnabled - bool indicating whether the receiveModule should deliver messages to the app directly or not.
     * msgDeliveryPaused - bool indicating whether msg delivery is paused or not. If paused, the library will not accept new msg
     *                     proofs or deliver messages to the app.
     */
    struct AppSettings {
        uint256 minDisputeTime;
        uint256 minDisputeResolutionExtension;
        uint256 disputeEpochLength;
        uint256 maxValidDisputesPerEpoch;
        address oracle;
        address defaultRelayer;
        address disputersContract;
        address disputeResolver;
        address recsContract;
        bool emitMsgProofs;
        bool directMsgsEnabled;
        bool msgDeliveryPaused;
    }

    /**
     * @dev - Struct that represents an app's current dispute epoch
     * start - uint64 indicating the block number the epoch started
     * end - uint64 indicating the block number the epoch ends
     * numberOfValidDisputes - uint64 indicating the number of valid disputes found in the current dispute epoch
     */
    struct CurrentDisputeEpoch {
        uint64 start;
        uint64 end;
        uint64 numberOfValidDisputes;
    }

    /**
     * @dev - Struct that represents a struct that tell us a msg proofs validity status.  A msg proof can be invalid for many reasons:
     *        1. It was found that it passed the wrong recommended values when being delivered.
     *        2. Its being disputed
     *        3. The dispute resolver passed a verdict saying the message is invalid.
     *        4. The dispute resolution period is still ongoing.
     * alreadyFailedDueToWrongRecMsgProofData - bool indicating whether message already failed due to oracle passing
     *                                          wrong recommended msg proof values.
     * disputed - bool indicating whether the message was already disputed or not.
     * disputeVerdict - uint8 indicating the dispute verdict type.  Look at the DisputeVerdictType enum.
     * endOfDisputeResolutionBlock - uint256 indicating the block number when the dispute resolution period ends
     */
    struct MsgProofValidityObject {
        bool alreadyFailedDueToWrongRecMsgProofData;
        bool disputed;
        uint8 disputeVerdict;
        uint128 endOfDisputeResolutionBlock;
    }

    /**
     * @dev - Struct that contains data that is encoded and hashed to create a msg proof
     * msgHash - byte32 indicating hash of the message being passed.
     * recommendedDisputeTime - uint256 used to indicate the recommended dispute time for passing a message.
     *                          Must be greater than the minimum dispute time.
     * recommendedDisputeResolutionExtension - uint256 used to indicate the recommended dispute resolution extension after resolving a dispute.
     *                                         Must be greater than the minimum dispute resolution extension.
     * revealedMsgSecret - bytes32 array indicating a revealed secret the oracle must reveal about the message proof
     *                     it is passing. Value can be retrived from calling the app's recsContract. Messages
     *                     with invalid revealed msg secrets can be rejected by the app. Can be used by third party's disputers or rec
     *                     relayers to self-select which message proofs to pay attention to.
     * senderChainId - uint256 indicating the sender's chain id.
     * isSelfBroadcastedMsg - bool indicating whether the message was self broadcasted or sent through the endpoint and broadcasted by the send library.
     * sender - bytes array indicating the address of the sender. (bytes is used since the sender can be on an EVM or non-EVM chain)
     * sourceTxnHash - bytes array indicating the source transaction hash.
     *                 (bytes is used since the source transaction can be on an EVM or non-EVM chain)
     */
    struct MsgProof {
        bytes32 msgHash;
        uint256 recommendedDisputeTime;
        uint256 recommendedDisputeResolutionExtension;
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
     * aggregateMsgProofHashIndex - uint256 indicating the index of the aggregate msg proof hash
     * msgProofHashes - array of bytes32 that indicate hash of msg proofs that were submitted and
     *                  used to create the aggregate msg proof hash
     * msgs - array of MsgData that can be used to recreate msgs and their msg proofs.
     */
    struct MsgsByAggregateProof {
        uint256 aggregateMsgProofHashIndex;
        bytes32[] msgProofHashes;
        MsgData[] msgs;
    }

    /**
     * @dev - Struct used to pass msg data what is used to recreate msg proof and deliver messages.
     *        This struct is a field in MsgsByAggregateProof which is used in MsgsByApp which is used submitMessages.
     * individualMsgProofIndex - uint256 indicating the index of the msgs proof hash in the invidualMsgProofHashes
     *                           array within MsgsByAggregateProof.
     * nonce - nonce of the msg
     * deliveryInfo - struct that contains additional info needed to deliver msgs
     * isOrderedMsg - bool indicating whether the message is an ordered msg or not.
     * isSelfBroadcastedMsg - bool indicating whether the message was self broadcasted or sent through the endpoint and broadcasted by the send library.
     * sourceTxnHash - bytes indicating the source transaction hash for the message. This is used to generate the msg proof hash
     * payload - bytes indicating the actual msg payload
     */
    struct MsgData {
        uint256 individualMsgProofIndex;
        uint256 nonce;
        MsgDeliveryInfo deliveryInfo;
        bool isOrderedMsg;
        bool isSelfBroadcastedMsg;
        bytes sourceTxnHash;
        bytes payload;
    }

    /**
     * @dev - Struct used to pass msg data what is used to recreate msg proof and deliver messages.
     *        This struct is a field in MsgsByAggregateProof which is used in MsgsByApp which is used submitMessages.
     * deliveryBlock - uint256 indicating the block number the message's msgProof was delivered.
     * recommendedDisputeTime - uint256 indicating the recommended dispute time that was supplied when creating the msg proof.
     * recommendedDisputeResolutionExtension - uint256 indicating the recommended dispute resolution extension period.
     * revealedMsgSecret - bytes32 indicating the revealed msg secret that was provided when supplying the message proof.
     * gas - the amount of gas the message should be passed with
     * failureFee - uint256 indicating the fee user must pay to resend the message if it fails
     */
    struct MsgDeliveryInfo {
        uint256 deliveryBlock;
        uint256 recommendedDisputeTime;
        uint256 recommendedDisputeResolutionExtension;
        bytes32 revealedMsgSecret;
        uint256 gas;
        uint256 failureFee;
    }

    /**
     * @dev - Struct that represents a message that Rukh receive module failed to deliver.
     * failedMsgHash - bytes32 representing failed msg hash
     * fee - uint256 indicating fee caller must pay before they can deliver the new failed message.
     * relayerThatDeliveredMsg - address of relayer that tried delivering the message.
     *                           It also happens to be the address the fee with be paid to.
     */
    struct FailedMsg {
        bytes32 failedMsgHash;
        uint96 fee;
        address relayerThatDeliveredMsg;
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
     * @dev - Event emitted to tell offchain entities amount of gas used for delivery.
     * @param app - address of the app message was being sent to.
     * @param senderChainId - uint256 indicating the chain Id of the sender
     * @param sender - bytes array indicating the address of the sender
     * @param nonce - uint256 indicating the nonce of the failed msg
     * @param gasUsed - uint256 indicating the amount of gas used in the delivery of this individual message
     */
    event MsgGasUsed(
        address indexed app, uint256 indexed senderChainId, bytes sender, uint256 nonce, uint256 gasUsed
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
     * @dev - Event emitted when a message proof is disputed.
     * @param _app - address of the app whose msg proofs are being disputed
     * @param _disputedMsgProofHash - bytes32 indicating the hash of the disputed msg proof
     * @param _deliveryBlockNumber - uint256 indicating the block number the disputed msg proof was delivered.
     * @param _msgProof - MsgProof object corresponding to the disputed msg proof.
     */
    event MsgProofDisputed(
        address indexed _app,
        bytes32 indexed _disputedMsgProofHash,
        uint256 indexed _deliveryBlockNumber,
        MsgProof _msgProof
    );

    /**
     * @dev - Event emitted when a message proof is disputed.
     * @param _app - address of the app whose msg proofs are being disputed
     * @param _disputedMsgProofHash - bytes32 indicating the hash of the disputed msg proof
     * @param _deliveryBlockNumber - uint256 indicating the block number the disputed msg proof was delivered.
     * @param _msgProof - MsgProof object corresponding to the disputed msg proof.
     * @param _disputeVerdict - uint256 indicating the dispute verdict.
     */
    event DisputeResolved(
        address indexed _app,
        bytes32 indexed _disputedMsgProofHash,
        uint256 indexed _deliveryBlockNumber,
        MsgProof _msgProof,
        uint256 _disputeVerdict
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
     * @param _indicesOfMsgProofsToPutInNewAggregateMsgProofHash - uint256 array indicating indices of msg proofs
     *                                                             to put in the new aggregate msg proof hash we are creating.
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
     * @dev - Function that allows the app's oracle to trims/removes some message proofs that are in an aggregate msg hash.
     * @param _app - address of the app msg proofs are being merged.
     * @param _aggregateMsgProofHashIndex - uint256 indicating the index of the first aggregate msg proof index.
     * @param _msgProofsInAggregateMsgProofHash - bytes32 array indicating the msg proofs in first aggregate msg proof.
     * @param _indicesOfMsgProofsInNewAggregateMsgProofHash - uint256 indicating the index of the second aggregate msg proof index.
     */
    function trimMsgProofsInAggregateMsgProof(
        address _app,
        uint256 _aggregateMsgProofHashIndex,
        bytes32[] memory _msgProofsInAggregateMsgProofHash,
        uint256[] memory _indicesOfMsgProofsInNewAggregateMsgProofHash
    ) external;

    /**
     * @dev - Function that allows a disputer to dispute a msg proof.
     * @param _app - address of the app whose msg proofs are being disputed
     * @param _disputedMsgProofHash - bytes32 indicating the hash of the disputed msg proof
     * @param _deliveryBlockNumber - uint256 indicating the block number the disputed msg proof was delivered.
     * @param _msgProof - MsgProof object corresponding to the disputed msg proof.
     * @return epochStart - uint256 indicating when the app's current epoch started
     * @return epochEnd - uint256 indicating when the app's current epoch ends.
     */
    function disputeMsgProof(
        address _app,
        bytes32 _disputedMsgProofHash,
        uint256 _deliveryBlockNumber,
        MsgProof memory _msgProof
    ) external returns (uint256 epochStart, uint256 epochEnd);

    /**
     * @dev - Function that allows a disputer to dispute a msg proof.
     * @param _app - address of the app whose msg proofs are being disputed
     * @param _disputedMsgProofHash - bytes32 indicating the hash of the disputed msg proof
     * @param _deliveryBlockNumber - uint256 indicating the block number the disputed msg proof was delivered.
     * @param _msgProof - MsgProof object corresponding to the disputed msg proof.
     * @param _disputeVerdict - uint256 indicating the dispute verdict.
     */
    function resolveDispute(
        address _app,
        bytes32 _disputedMsgProofHash,
        uint256 _deliveryBlockNumber,
        MsgProof memory _msgProof,
        uint256 _disputeVerdict
    ) external;

    /**
     * @dev - Function that allows an app's default relayer to submit messages.
     * @param _msgsByApps - Array of msgs by app.
     */
    function submitMessages(MsgsByApp[] memory _msgsByApps) external payable;
}

// See what you are doing about failed msgs on the endpoint
