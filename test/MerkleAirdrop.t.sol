// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ZkSyncChainChecker} from "@devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    BagelToken public s_token;
    MerkleAirdrop public s_airdrop;
    uint256 constant INITIAL_TOKEN_AMOUNT = 1000 ether;
    uint256 constant CLAIM_AMOUNT = 25 ether;
    bytes32 public s_root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32[] private s_proofs = [
        bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576
    ];
    address user;
    uint256 userPrivateKey;
    DeployMerkleAirdrop private s_deployer;

    function setUp() public {
        if (isZkSyncChain()) {
            s_token = new BagelToken();
            s_airdrop = new MerkleAirdrop(s_root, IERC20(address(s_token)));
            s_token.mint(s_token.owner(), INITIAL_TOKEN_AMOUNT);
            s_token.transfer(address(s_airdrop), INITIAL_TOKEN_AMOUNT);
        } else {
            //deploy the airdrop contract using the deploy script
            s_deployer = new DeployMerkleAirdrop();
            (s_airdrop, s_token) = s_deployer.deployMerkleAirdrop();
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function testUserCanClaimTokens() external {
        uint256 startingBalance = s_token.balanceOf(user);
        assertEq(startingBalance, 0, "User should start with 0 tokens");
        vm.startPrank(user);
        s_airdrop.claim(user, CLAIM_AMOUNT, s_proofs);
        vm.stopPrank();
        uint256 endingBalance = s_token.balanceOf(user);
        assertEq(endingBalance, CLAIM_AMOUNT, "User should have received the correct amount of tokens");
        bool hasClaimed = s_airdrop.hasClaimed(user);
        assertTrue(hasClaimed, "User should have claimed the tokens");
    }
}
