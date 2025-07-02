// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReferralSystem {
    uint256 constant MAX_CODE_USAGE = 20;
    uint256 constant REFERRAL_REWARD = 100;
    uint256 constant NUM_CODES = 10;
    uint256 constant CODE_LENGTH = 7;

    string public constant GENESIS_CODE = "0000000";
    uint256 public constant GENESIS_CODE_LIMIT = 8;

    struct CodeData {
        address owner;
        uint256 uses;
    }

    mapping(address => bool) public hasJoined;
    mapping(address => string[]) public userCodes;
    mapping(string => CodeData) public codeInfo;
    mapping(address => uint256) public userPoints;

    event ReferralVerified(address indexed user, string refCode);
    event CodesGenerated(address indexed user, string[] codes);
    event ReferralUsed(string code, address indexed referred, address indexed referrer);

    constructor() {
        codeInfo[GENESIS_CODE] = CodeData({owner: address(0), uses: 0});
    }

    function joinAirdrop(string memory refCode) public {
        require(!hasJoined[msg.sender], "Already joined");
        require(codeInfo[refCode].owner != address(0) || keccak256(bytes(refCode)) == keccak256(bytes(GENESIS_CODE)), "Invalid referral code");

        if (keccak256(bytes(refCode)) == keccak256(bytes(GENESIS_CODE))) {
            require(codeInfo[GENESIS_CODE].uses < GENESIS_CODE_LIMIT, "Genesis code usage limit reached");
            codeInfo[GENESIS_CODE].uses++;
            emit ReferralUsed(GENESIS_CODE, msg.sender, address(0));
        } else {
            CodeData storage data = codeInfo[refCode];
            require(data.uses < MAX_CODE_USAGE, "Referral code usage limit reached");
            data.uses++;
            userPoints[data.owner] += REFERRAL_REWARD;
            emit ReferralUsed(refCode, msg.sender, data.owner);
        }

        hasJoined[msg.sender] = true;

        string[] memory newCodes = new string[](NUM_CODES);
        for (uint256 i = 0; i < NUM_CODES; i++) {
            string memory code = generateCode(msg.sender, i);
            newCodes[i] = code;
            userCodes[msg.sender].push(code);
            codeInfo[code] = CodeData({owner: msg.sender, uses: 0});
        }

        emit ReferralVerified(msg.sender, refCode);
        emit CodesGenerated(msg.sender, newCodes);
    }

    function getOrJoinAirdrop(string memory refCode) external {
        if (!hasJoined[msg.sender]) {
            joinAirdrop(refCode);
        }
    }

    function generateCode(address user, uint256 index) internal pure returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(user, index));
        uint256 number = uint256(hash) % 10**CODE_LENGTH;

        bytes memory buffer = new bytes(CODE_LENGTH);
        for (uint256 i = 0; i < CODE_LENGTH; i++) {
            buffer[CODE_LENGTH - 1 - i] = bytes1(uint8(48 + number % 10));
            number /= 10;
        }

        return string(buffer);
    }

    function getUserCodes(address user) external view returns (string[] memory) {
        return userCodes[user];
    }

    function getCodeData(string memory code) external view returns (address owner, uint256 uses) {
        CodeData memory data = codeInfo[code];
        return (data.owner, data.uses);
    }

    function getPoints(address user) external view returns (uint256) {
        return userPoints[user];
    }

    function hasUserJoined(address user) external view returns (bool) {
        return hasJoined[user];
    }
}
