//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is ReentrancyGuard, Ownable {

    uint256 public constant HARD_CAP = 40_000 ether; //$30k

    bool public isOpen = false;

    address public beneficiary;
    address public oracle;

    uint256 public maxContribution = 5_000 ether; //$5k
    uint256 public minContribution = 10 ether;
    uint256 public contributed;


    mapping(address => uint256) public contributions;
    address[] public contributors;
    mapping(address => bool) public approvedTokens;

    event Contribution(address indexed buyer, address indexed token, uint256 amount);
    event TokenState(address indexed token, bool state);

    error Closed();
    error AddressZero();
    error ERC20TransferFailed();
    error AmountZero();
    error Unauthorized(address account);
    error UnapprovedToken(address token);
    error UnderMinContribution();
    error OverMaxContribution();
    error OverHardCap(uint256 amount);
    
    constructor(address beneficiary_, address oracle_) {
        setBeneficiary(beneficiary_);
        setOracle(oracle_);
    }

    function failOnZeroAddress(address toCheck) internal pure {
        if (toCheck == address(0)) revert AddressZero();
    }

    function setBeneficiary(address account) public onlyOwner {
        failOnZeroAddress(account);

        beneficiary = account;
    }

    function setOracle(address account) public onlyOwner {
        failOnZeroAddress(account);
        oracle = account;
    }

    function setApprovedTokens(address[] memory tokens, bool[] memory approved) public onlyOwner {
        for(uint256 i = 0; i < tokens.length; i++) {
            failOnZeroAddress(tokens[i]);
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
    
    function setSaleOpen(bool newState) external onlyOracleOrOwner {
        isOpen = newState;
    }

    function contribute(address token, uint256 amount) external nonReentrant {
        if (!isOpen) revert Closed();
        if (!approvedTokens[token]) revert UnapprovedToken(token);
        if (amount == 0) revert AmountZero();
        if (amount < minContribution) revert UnderMinContribution();
        if (amount > maxContribution) revert OverMaxContribution();
        if (amount + contributed > HARD_CAP) revert OverHardCap(amount + contributed);

        contributed += amount;
        if(contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += amount;

        IERC20(token).transferFrom(msg.sender, beneficiary, amount);

        emit Contribution(msg.sender, token, amount);
    }

    function withdraw(IERC20 token) external onlyOwner {
        failOnZeroAddress(address(token));

        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
            token.transfer(beneficiary, balance);
        }
    }

    modifier onlyOracleOrOwner() {
        if (msg.sender != oracle && msg.sender != owner()) revert Unauthorized(msg.sender);
        _;
    }


}
