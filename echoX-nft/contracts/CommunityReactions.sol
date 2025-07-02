// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMemeFactory {
    function updateMemeReactionStats(uint256 memeIndex, bool isUpvote, bool isComment, bool isEmoji) external;
    function getMemeTokenCount() external view returns (uint256);
}

contract CommunityReactions {
    struct TextComment {
        address commenter;
        string content;
        uint256 timestamp;
        uint256 memeIndex;
    }

    struct EmojiReaction {
        address reactor;
        string emoji;
        uint256 timestamp;
        uint256 memeIndex;
    }

    struct Vote {
        address voter;
        bool isUpvote;
        uint256 timestamp;
    }

    address public memeFactory;

    mapping(uint256 => TextComment[]) public memeComments;
    mapping(uint256 => EmojiReaction[]) public memeEmojiReactions;
    mapping(uint256 => Vote[]) public memeVotes;

    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => bool)) public hasCommentedToday;
    mapping(address => mapping(uint256 => uint256)) public lastCommentTimestamp;
    mapping(address => uint256) public userReactionPoints;

    uint256 public constant VOTE_POINTS = 1;
    uint256 public constant TEXT_COMMENT_POINTS = 10;
    uint256 public constant EMOJI_REACTION_POINTS = 2;
    uint256 public constant MAX_COMMENT_LENGTH = 50;

    event VoteCast(address indexed voter, uint256 indexed memeIndex, bool isUpvote, uint256 timestamp);
    event TextCommentAdded(address indexed commenter, uint256 indexed memeIndex, string content, uint256 timestamp);
    event EmojiReactionAdded(address indexed reactor, uint256 indexed memeIndex, string emoji, uint256 timestamp);
    event ReactionPointsAwarded(address indexed user, uint256 points, string reactionType);

    modifier onlyMemeFactory() {
        require(msg.sender == memeFactory, "Only MemeFactory can call this");
        _;
    }

    modifier validMemeIndex(uint256 memeIndex) {
        require(memeIndex < IMemeFactory(memeFactory).getMemeTokenCount(), "Invalid meme index");
        _;
    }

    constructor(address _memeFactory) {
        memeFactory = _memeFactory;
    }

    function updateMemeFactory(address _newMemeFactory) external onlyMemeFactory {
        memeFactory = _newMemeFactory;
    }

    function voteOnMeme(uint256 memeIndex, bool isUpvote) external validMemeIndex(memeIndex) {
        require(!hasVoted[msg.sender][memeIndex], "Already voted on this meme");

        hasVoted[msg.sender][memeIndex] = true;
        memeVotes[memeIndex].push(Vote(msg.sender, isUpvote, block.timestamp));
        userReactionPoints[msg.sender] += VOTE_POINTS;

        IMemeFactory(memeFactory).updateMemeReactionStats(memeIndex, isUpvote, false, false);

        emit VoteCast(msg.sender, memeIndex, isUpvote, block.timestamp);
        emit ReactionPointsAwarded(msg.sender, VOTE_POINTS, isUpvote ? "upvote" : "downvote");
    }

    function addTextComment(uint256 memeIndex, string memory content) external validMemeIndex(memeIndex) {
        bytes memory contentBytes = bytes(content);
        require(contentBytes.length > 0, "Comment cannot be empty");
        require(contentBytes.length <= MAX_COMMENT_LENGTH, "Comment exceeds 50 characters");

        uint256 today = block.timestamp / 1 days;
        uint256 lastDay = lastCommentTimestamp[msg.sender][memeIndex] / 1 days;

        if (today == lastDay) {
            require(!hasCommentedToday[msg.sender][memeIndex], "Already commented today on this meme");
        } else {
            hasCommentedToday[msg.sender][memeIndex] = false;
        }

        memeComments[memeIndex].push(TextComment(msg.sender, content, block.timestamp, memeIndex));
        hasCommentedToday[msg.sender][memeIndex] = true;
        lastCommentTimestamp[msg.sender][memeIndex] = block.timestamp;

        userReactionPoints[msg.sender] += TEXT_COMMENT_POINTS;
        IMemeFactory(memeFactory).updateMemeReactionStats(memeIndex, false, true, false);

        emit TextCommentAdded(msg.sender, memeIndex, content, block.timestamp);
        emit ReactionPointsAwarded(msg.sender, TEXT_COMMENT_POINTS, "text_comment");
    }

    function addEmojiReaction(uint256 memeIndex, string memory emoji) external validMemeIndex(memeIndex) {
        bytes memory emojiBytes = bytes(emoji);
        require(emojiBytes.length > 0, "Emoji cannot be empty");
        require(emojiBytes.length <= 100, "Emoji too long");

        memeEmojiReactions[memeIndex].push(EmojiReaction(msg.sender, emoji, block.timestamp, memeIndex));
        userReactionPoints[msg.sender] += EMOJI_REACTION_POINTS;

        IMemeFactory(memeFactory).updateMemeReactionStats(memeIndex, false, false, true);

        emit EmojiReactionAdded(msg.sender, memeIndex, emoji, block.timestamp);
        emit ReactionPointsAwarded(msg.sender, EMOJI_REACTION_POINTS, "emoji_reaction");
    }

    function getMemeReactionStats(uint256 memeIndex) external view validMemeIndex(memeIndex) returns (
        uint256 upvotes,
        uint256 downvotes,
        uint256 totalComments,
        uint256 totalEmojiReactions,
        uint256 totalVotes
    ) {
        Vote[] storage votes = memeVotes[memeIndex];
        uint256 upvoteCount;
        uint256 downvoteCount;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i].isUpvote) upvoteCount++;
            else downvoteCount++;
        }

        return (
            upvoteCount,
            downvoteCount,
            memeComments[memeIndex].length,
            memeEmojiReactions[memeIndex].length,
            votes.length
        );
    }

    function getMemeComments(uint256 memeIndex, uint256 offset, uint256 limit) external view validMemeIndex(memeIndex) returns (
        address[] memory commenters,
        string[] memory contents,
        uint256[] memory timestamps
    ) {
        TextComment[] storage comments = memeComments[memeIndex];
        uint256 end = offset + limit > comments.length ? comments.length : offset + limit;

        commenters = new address[](end - offset);
        contents = new string[](end - offset);
        timestamps = new uint256[](end - offset);

        for (uint256 i = offset; i < end; i++) {
            TextComment storage c = comments[i];
            commenters[i - offset] = c.commenter;
            contents[i - offset] = c.content;
            timestamps[i - offset] = c.timestamp;
        }
    }

    function getMemeEmojiReactions(uint256 memeIndex, uint256 offset, uint256 limit) external view validMemeIndex(memeIndex) returns (
        address[] memory reactors,
        string[] memory emojis,
        uint256[] memory timestamps
    ) {
        EmojiReaction[] storage reactions = memeEmojiReactions[memeIndex];
        uint256 end = offset + limit > reactions.length ? reactions.length : offset + limit;

        reactors = new address[](end - offset);
        emojis = new string[](end - offset);
        timestamps = new uint256[](end - offset);

        for (uint256 i = offset; i < end; i++) {
            EmojiReaction storage r = reactions[i];
            reactors[i - offset] = r.reactor;
            emojis[i - offset] = r.emoji;
            timestamps[i - offset] = r.timestamp;
        }
    }

    function getMemeVotes(uint256 memeIndex, uint256 offset, uint256 limit) external view validMemeIndex(memeIndex) returns (
        address[] memory voters,
        bool[] memory isUpvotes,
        uint256[] memory timestamps
    ) {
        Vote[] storage votes = memeVotes[memeIndex];
        uint256 end = offset + limit > votes.length ? votes.length : offset + limit;

        voters = new address[](end - offset);
        isUpvotes = new bool[](end - offset);
        timestamps = new uint256[](end - offset);

        for (uint256 i = offset; i < end; i++) {
            Vote storage v = votes[i];
            voters[i - offset] = v.voter;
            isUpvotes[i - offset] = v.isUpvote;
            timestamps[i - offset] = v.timestamp;
        }
    }

    function getUserReactionStatus(address user, uint256 memeIndex) external view validMemeIndex(memeIndex) returns (
        bool hasVotedOnMeme,
        bool canCommentToday,
        uint256 totalReactionPoints
    ) {
        uint256 today = block.timestamp / 1 days;
        uint256 lastDay = lastCommentTimestamp[user][memeIndex] / 1 days;
        bool canComment = (today != lastDay) || !hasCommentedToday[user][memeIndex];

        return (
            hasVoted[user][memeIndex],
            canComment,
            userReactionPoints[user]
        );
    }
}
