//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../../../common/ConcatHelper.sol";
import "./ICheddaVerifier.sol";

/// @title TwitterAPIConsumer
/// @notice Makes a request using Chainlink Any API call to verify off-chain condition
/// @dev Note: If this contract is created by contract, parent contract must implement
/// function to withdraw link tokens sent to this contract.
contract TwitterAPIConsumer is Ownable, ChainlinkClient, ICheddaVerifier {

    event VerificationStatusReceived(address indexed user, bool status);

    using Chainlink for Chainlink.Request;
    address private _oracle;
    bytes32 private _jobId;
    uint256 private _fee;
    string public requestURL;

    mapping (address => bool) public verified;
    mapping (bytes32 => address) public requestIds;

    /// @notice Constructor
    /// @dev Explain to a developer any extra details
    /// @param linkAddress Chainlink token address
    /// @param oracleAddress Address of oracle
    /// @param jobId jobId
    /// @param linkFee Fee in Link token for node operator
    /// LinkRiver Get > Bool
    /// oracle:
    /// polygon Mumbai:0xc8D925525CA8759812d0c299B902 
    /// jobIds: 
    /// - polygon Mumbai Testnet :99b1b806a8f84b14a254230ccf094747 
    constructor(address linkAddress, address oracleAddress, bytes32 jobId, uint256 linkFee) {
        if (linkAddress == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(linkAddress);
        }
        _oracle = oracleAddress;
        _jobId = jobId;
        _fee = linkFee;
        requestURL = "https://ea0tz0tjv8.execute-api.us-east-1.amazonaws.com/default/twitter-follow-verification?u=";
    }

    /// @notice Makes request to chainlink
    /// @dev Explain to a developer any extra details
    /// @param user the address of the user
    /// @param userToken unique token for the user. The API endpoint uses this to identify which user is making the call.
    /// user is authenticated on fronted and receives a token which is tied to their twitter user id.
    /// @return requestId the Chainlink request ID
    function requestVerification(address user, bytes memory userToken) public override returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        request.add("get", _buildRequestURL(userToken));
        request.add("path", "verified");
        requestId = sendChainlinkRequestTo(_oracle, request, _fee);
        requestIds[requestId] = user;
        return requestId;
    }

    /// @notice Chainlink callback function after off-chain verification completes.
    /// @param requestId Chainlink request ID
    /// @param result Boolean value indicating if verification succeeded or failed
    function fulfill(bytes32 requestId, bool result) public override {
        validateChainlinkCallback(requestId);
        address user = requestIds[requestId];
        if (user != address(0)) {
            _setVerified(user, result);
        }
    }

    /// @notice Cancels a pending request.
    /// Call this function if no response is received within 5 minutes
    /// @param requestId the request ID to cancel
    /// @param payment the payment specified for request to cancel
    /// @param callbackFunctionId the function ID 
    /// @param expiration the expiratin time
    function cancelRequest(bytes32 requestId, uint256 payment, bytes4 callbackFunctionId, uint256 expiration) public onlyOwner() {
        cancelChainlinkRequest(requestId, payment, callbackFunctionId, expiration);
    }

    /// @notice Withdraw any LINK tokens sent to this contract
    /// @dev Can only be called by contract owner. Note: If contract owner is contract,
    /// parent contract must implement function to call this function
    function withdrawLink() public onlyOwner() {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        uint256 linkBalance = getLinkBalance();
        require(linkToken.transfer(_msgSender(), linkBalance), "TAPI: transfer failed");
    }

    /// @notice Get Chainlink token address
    /// @return Chainlink token address specified at time of creation or default
    /// Chainlink token address on chain.
    function getLinkTokenAddress() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getLinkBalance() public view returns (uint256) {
       LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        return linkToken.balanceOf(address(this)); 
    }

    function _setVerified(address user, bool status) private {
        verified[user] = status;

        emit VerificationStatusReceived(user, status);
    }

    function _buildRequestURL(bytes memory userToken) private view returns (string memory) {
        return string(ConcatHelper.concat(bytes(requestURL), userToken));
    }
}
