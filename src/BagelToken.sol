// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BagelToken is ERC20, Ownable{
    string public constant NAME = "Bagel Token";
    string public constant SYMBOL = "BAGEL";

    constructor() ERC20(NAME, SYMBOL) Ownable(msg.sender){
    }

    function  mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}