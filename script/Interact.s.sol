// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DevOpsTools} from "@devops/src/DevOpsTools.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdrop__InvalidSignatureLength();
    address private CLAIMING_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private CLAIMING_AMOUNT = 25 * 1e18; // Assuming the token has 18 decimals
    bytes32[] private proof = [
        bytes32(0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad),
      0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576
    ];
    bytes private signature = hex"4f938e3917d2c340cfd1b223559980e42f3ceaaeb3b083c0faaa640f9e40488a7636008eb1c85727974edf73c7974deaf7b1c66cd338c5657f9f2b14dfd82b851b";

    function claimAirdrop(address airdropAddress) public {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        vm.startBroadcast();
        MerkleAirdrop(airdropAddress).claim(CLAIMING_ACCOUNT, CLAIMING_AMOUNT, proof, v,r,s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        if(sig.length != 65) revert ClaimAirdrop__InvalidSignatureLength();
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
        // // Adjust v to be 27 or 28
        // if (v < 27) {
        //     v += 27;
        // }
    }

    function run() external {
        address mostRecentlyDeployedAirdrop = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedAirdrop);
    }

    
 }
