//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "hardhat/console.sol";

contract Presale is ReentrancyGuard, Ownable {

    uint256 public constant HARD_CAP = 30_000 ether; //$30k

    bool public state = false;

    address public beneficiary;
    address public oracle;

    uint256 public maxContribution = 5_000 ether; //$5k
    uint256 public contributed;


    mapping(address => uint256) public contributions;
    mapping(address => bool) public approvedTokens;

    event Contribution(address indexed buyer, address indexed token, uint256 amount);
    event TokenState(address indexed token, bool state);

    error Closed();
    error ZeroAddress();
    error ERC20TransferFailed();
    error AmountZero();
    error Unauthorized(address account);
    error UnapprovedToken(address token);
    error OverMaxContribution(uint256 amount);
    error OverHardCap(uint256 amount);
    
    constructor(address beneficiary_, address oracle_) {
        setBeneficiary(beneficiary_);
        setOracle(oracle_);
    }

    function setBeneficiary(address account) public onlyOwner {
        if(account == address(0)) revert ZeroAddress();

        beneficiary = account;
    }

    function setOracle(address account) public onlyOwner {
        if(account == address(0)) revert ZeroAddress();

        oracle = account;
    }

    function setApprovedTokens(address[] memory tokens, bool[] memory approved) public onlyOwner {
        for(uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert ZeroAddress();
            approvedTokens[tokens[i]] = approved[i];

            emit TokenState(tokens[i], approved[i]);
        }
    }

    function setMaxContribution(uint256 max) external onlyOwner {
        if (max == 0) {
            max = type(uint256).max;
        }

        maxContribution = max;
    }
    
    function setState(bool newState) external onlyOracleOrOwner {
        state = newState;
    }

    function contribute(address token, uint256 amount) external nonReentrant {
        if (!state) revert Closed();
        if (!approvedTokens[token]) revert UnapprovedToken(token);
        if (amount == 0) revert AmountZero();
        if (amount > maxContribution) revert OverMaxContribution(amount);
        if (amount + contributed > HARD_CAP) revert OverHardCap(amount + contributed);

        contributed += amount;
        contributions[msg.sender] += amount;

        IERC20(token).transferFrom(msg.sender, beneficiary, amount);

        emit Contribution(msg.sender, token, amount);
    }

    modifier onlyOracleOrOwner() {
        if (msg.sender != oracle && msg.sender != owner()) revert Unauthorized(msg.sender);
        _;
    }


}
