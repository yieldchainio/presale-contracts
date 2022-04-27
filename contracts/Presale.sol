//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20Decimals.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is ReentrancyGuard, Ownable {

    uint256 public constant MULTIPLIER = 10**18;
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

    event Contribution(address indexed buyer, address indexed token, uint256 normalized, uint256 amount);
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

    /**
    * @notice Revert if given addr is 0x0...
    * @param toCheck address to check
    */
    function failOnZeroAddress(address toCheck) internal pure {
        if (toCheck == address(0)) revert AddressZero();
    }

    /**
    * @notice Configures the beneficiary for the presale
    * @param account beneficiary address
    */
    function setBeneficiary(address account) public onlyOwner {
        failOnZeroAddress(account);

        beneficiary = account;
    }

    /**
    * @notice Set oracle address
    * @param account oracle address
    */
    function setOracle(address account) public onlyOwner {
        failOnZeroAddress(account);
        oracle = account;
    }

    /**
    * @notice Allows configuring tokens accepted for presale
    * @param tokens list of tokens to configure
    * @param approved bool representing if the token should be allowed
    */
    function setApprovedTokens(address[] memory tokens, bool[] memory approved) public onlyOwner {
        for(uint256 i = 0; i < tokens.length; i++) {
            failOnZeroAddress(tokens[i]);
            approvedTokens[tokens[i]] = approved[i];

            emit TokenState(tokens[i], approved[i]);
        }
    }

    /**
    * @notice Set maximal contribution per address
    * @param max maximum contribution
    */
    function setMaxContribution(uint256 max) external onlyOwner {
        if (max == 0) {
            max = type(uint256).max;
        }

        maxContribution = max;
    }
    
    /**
    * @notice Configures whether the presale is open
    * @param newState true/false based on if the sale is open or not
    */
    function setSaleOpen(bool newState) external onlyOracleOrOwner {
        isOpen = newState;
    }

    /**
    * @notice Allows users to contribute to presale
    * @param token address of token user is using to contribute
    * @param amount amount to contribute
    */
    function contribute(address token, uint256 amount) external nonReentrant {
        if (!isOpen) revert Closed();
        if (!approvedTokens[token]) revert UnapprovedToken(token);
        if (amount == 0) revert AmountZero();

        uint256 normalized = (amount * MULTIPLIER) / 10**IERC20Decimals(token).decimals();

        if (normalized < minContribution) revert UnderMinContribution();
        if (normalized > maxContribution) revert OverMaxContribution();
        if (normalized + contributed > HARD_CAP) revert OverHardCap(amount + contributed);

        contributed += normalized;
        if(contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += normalized;

        IERC20Decimals(token).transferFrom(msg.sender, beneficiary, amount);

        emit Contribution(msg.sender, token, normalized, amount);
    }

    /**
    * @notice Allows owner to forward any tokens on contract to beneficiary
    * @param token token to withdraw
    */
    function withdraw(IERC20Decimals token) external onlyOwner {
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
