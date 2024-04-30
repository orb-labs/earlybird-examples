// src/RukhVersion/DisputerContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "earlybird/src/Libraries/Rukh/RukhReceiveModule/IRukhReceiveModule.sol";
import "earlybird/src/Libraries/Rukh/RukhReceiveModule/IDisputerContractForRukhReceiveModule.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract DisputerContract is IDisputerContractForRukhReceiveModule, Ownable {

    // Address of rukh library receive module
    address public rukhLibraryReceiveModule;

    // Address of app using this as their disputer contract
    address public app;

    // Reward for disputes
    uint256 public reward;

    // array of all current disputers
    address[] public disputers;

    // mapping of current disputers
    mapping(address => bool) public disputersMap;

    // mapping of dispute to dispute submitters
    mapping(bytes32 => address) public disputesToDisputeSubmitters;

    constructor(address _rukhLibraryReceiveModule) {
        rukhLibraryReceiveModule = _rukhLibraryReceiveModule;
    }

    // Update the app address
    function updateApp(address _app) external onlyOwner {
        app = _app;
    }

    function disputeResolved(bytes32 _disputedMsgProofHash, uint256 _disputeVerdict) external {
        require(msg.sender == rukhLibraryReceiveModule);
        require(_disputeVerdict == uint256(IRukhReceiveModule.DisputeVerdictType.MSG_PROOF_INVALID));

        // reward person who submitted the dispute
        address disputeSubmitter = disputesToDisputeSubmitters[_disputedMsgProofHash];
        (bool sent,) = disputeSubmitter.call{value: reward}("");
        require(sent, "Earlybird - Rukh Library (ReceiveModule): Failed to pay protocol fees in native token");
    }

    function disputeMsgProof(bytes32 _disputedMsgProofHash, uint256 _deliveryBlockNumber, IRukhReceiveModule.MsgProof memory _msgProof) external payable {
        require(disputersMap[msg.sender] == true);
        disputesToDisputeSubmitters[_disputedMsgProofHash] = msg.sender;
        IRukhReceiveModule(rukhLibraryReceiveModule).disputeMsgProof(app, _disputedMsgProofHash, _deliveryBlockNumber, _msgProof);
    }

    // Swaps out the only list of disputers for new ones
    function updateDisputers(address[] memory newDisputers) external onlyOwner {
        for (uint256 i = 0; i < disputers.length; i++) {
            disputersMap[disputers[i]] = false;
        }

        disputers = newDisputers;

        for (uint256 i = 0; i < disputers.length; i++) {
            disputersMap[disputers[i]] = true;
        }
    }

    // allow this contract to receive ether
    receive() external payable {}
}