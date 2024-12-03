// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IProfile {
    struct UserProfile {
        string displayName;
        string bio;
    }

    function getProfile(
        address _user
    ) external view returns (UserProfile memory);
}

contract Twitter is Ownable {
    uint256 public MAX_TWEET_LENGTH = 280;

    struct Tweet {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
    }

    mapping(address => Tweet[]) public tweets;
    IProfile profileContract;

    event TweetCreated(
        uint256 indexed id,
        address author,
        string content,
        uint256 timestamp
    );
    event TweetLiked(
        address indexed liker,
        address tweetAuthor,
        uint256 tweetId,
        uint256 newLikeCount
    );
    event TweetUnliked(
        address indexed unliker,
        address tweetAuthor,
        uint256 tweetId,
        uint256 newLikeCount
    );

    constructor(address _profileContract) Ownable(msg.sender) {
        profileContract = IProfile(_profileContract);
    }

    modifier onlyRegistered() {
        require(
            bytes(profileContract.getProfile(msg.sender).displayName).length >
                0,
            "NOT A REGISTERED USER"
        );
        _;
    }

    function changeTweetLength(uint256 _newTweetLength) public onlyOwner {
        MAX_TWEET_LENGTH = _newTweetLength;
    }

    function createTweet(string memory _tweet) public onlyRegistered {
        require(bytes(_tweet).length <= MAX_TWEET_LENGTH, "Tweet is too long.");

        Tweet memory newTweet = Tweet({
            id: tweets[msg.sender].length,
            author: msg.sender,
            content: _tweet,
            timestamp: block.timestamp,
            likes: 0
        });

        tweets[msg.sender].push(newTweet);
        emit TweetCreated(
            newTweet.id,
            newTweet.author,
            newTweet.content,
            newTweet.timestamp
        );
    }

    function getTweet(uint _index) public view returns (Tweet memory) {
        return tweets[msg.sender][_index];
    }

    function getAllTweets(address _owner) public view returns (Tweet[] memory) {
        return tweets[_owner];
    }

    function likeTweet(uint256 id, address author) external onlyRegistered {
        require(tweets[author][id].id == id, "Tweet not found");
        tweets[author][id].likes += 1;
        emit TweetLiked(msg.sender, author, id, tweets[author][id].likes);
    }

    function dislikeTweet(uint256 id, address author) external onlyRegistered {
        require(tweets[author][id].id == id, "Tweet not found");
        require(tweets[author][id].likes > 0, "Tweet has no likes");
        tweets[author][id].likes -= 1;
        emit TweetUnliked(msg.sender, author, id, tweets[author][id].likes);
    }

    function getTotalLikes(address _author) external view returns (uint256) {
        uint256 totalLikes = 0;
        for (
            uint likeCounter = 0;
            likeCounter < tweets[_author].length;
            likeCounter++
        ) {
            totalLikes += tweets[_author][likeCounter].likes;
        }
        return totalLikes;
    }
}
