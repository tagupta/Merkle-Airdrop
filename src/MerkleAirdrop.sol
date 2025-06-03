// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    // Custom errors

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    address[] public claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    bytes32 public constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    event Claim(address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "0.1.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        //Check the signature
        if (!_isValidSignature(account, getMessage(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        //use account and amount to cauculate the leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        //verify the leaf is in the merkle tree
        if (!MerkleProof.verifyCalldata(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        //mark the account as claimed
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        //transfer the airdrop token to the account
        i_airdropToken.safeTransfer(account, amount);
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v,r,s);
        return actualSigner == account;
    }

    function getMessage(address _account, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: _account, amount: _amount})))
        );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function hasClaimed(address account) external view returns (bool) {
        return s_hasClaimed[account];
    }

    function getClaimers() external view returns (address[] memory) {
        return claimers;
    }
}
