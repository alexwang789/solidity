// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// --- Interface for Chainlink Price Feed ---
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// --- Minimal ERC20 interface ---
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// --- OpenZeppelin UUPS Upgradeability ---
abstract contract UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// --- OpenZeppelin Ownable ---
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function owner() public view returns (address) {
        return _owner;
    }
}

// --- OpenZeppelin ERC721 Minimal Implementation ---
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract NtfERC721 is Ownable {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Token does not exist");
        return owner_;
    }

    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "Approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "Not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        if (to.code.length > 0) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) ==
                    IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        require(to != address(0), "Zero address");
        require(_owners[tokenId] == address(0), "Token already minted");
        _owners[tokenId] = to;
        _balances[to] += 1;
        totalSupply += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}

// --- Chainlink Price Oracle Helper ---
contract PriceOracle {
    AggregatorV3Interface public ethUsdFeed;
    mapping(address => AggregatorV3Interface) public erc20UsdFeeds;

    constructor(address _ethUsdFeed) {
        ethUsdFeed = AggregatorV3Interface(_ethUsdFeed);
    }

    function setERC20Feed(address erc20, address feed) external {
        erc20UsdFeeds[erc20] = AggregatorV3Interface(feed);
    }

    function getETHPriceUSD() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    function getERC20PriceUSD(address erc20) public view returns (uint256) {
        AggregatorV3Interface feed = erc20UsdFeeds[erc20];
        require(address(feed) != address(0), "Feed not set");
        (, int256 price, , , ) = feed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}

// --- Auction Contract (UUPS Upgradeable) ---
contract NFTAuction is UUPSUpgradeable, Ownable {
    struct Bid {
        address bidder;
        address payToken; // address(0) for ETH, or ERC20 address
        uint256 amount;   // in payToken
        uint256 usdValue; // in USD (8 decimals)
    }

    address public nft;
    uint256 public tokenId;
    address public seller;
    uint256 public endTime;
    bool public ended;
    PriceOracle public priceOracle;

    Bid public highestBid;
    mapping(address => uint256) public pendingReturns; // For ETH refunds
    mapping(address => mapping(address => uint256)) public pendingERC20Returns; // bidder => token => amount

    event AuctionCreated(address indexed nft, uint256 indexed tokenId, address seller, uint256 endTime);
    event BidPlaced(address indexed bidder, address payToken, uint256 amount, uint256 usdValue);
    event AuctionEnded(address winner, address payToken, uint256 amount, uint256 usdValue);

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTime, "Auction ended");
        _;
    }
    modifier onlyAfterEnd() {
        require(block.timestamp >= endTime, "Auction not yet ended");
        _;
    }

    function initialize(
        address _nft,
        uint256 _tokenId,
        address _seller,
        uint256 _duration,
        address _priceOracle
    ) external {
        require(nft == address(0), "Already initialized");
        nft = _nft;
        tokenId = _tokenId;
        seller = _seller;
        endTime = block.timestamp + _duration;
        priceOracle = PriceOracle(_priceOracle);

        emit AuctionCreated(_nft, _tokenId, _seller, endTime);
    }

    // Bid with ETH
    function bidWithETH() external payable onlyBeforeEnd {
        require(msg.value > 0, "No ETH sent");
        uint256 usdValue = (msg.value * priceOracle.getETHPriceUSD()) / 1e18;
        require(usdValue > highestBid.usdValue, "Bid not high enough");

        // Refund previous
        if (highestBid.bidder != address(0)) {
            pendingReturns[highestBid.bidder] += highestBid.amount;
        }

        highestBid = Bid(msg.sender, address(0), msg.value, usdValue);
        emit BidPlaced(msg.sender, address(0), msg.value, usdValue);
    }

    // Bid with ERC20
    function bidWithERC20(address erc20, uint256 amount) external onlyBeforeEnd {
        require(amount > 0, "No tokens sent");
        uint256 usdValue = (amount * priceOracle.getERC20PriceUSD(erc20)) / 1e18;
        require(usdValue > highestBid.usdValue, "Bid not high enough");

        // Transfer tokens in
        require(IERC20(erc20).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Refund previous
        if (highestBid.bidder != address(0)) {
            if (highestBid.payToken == address(0)) {
                pendingReturns[highestBid.bidder] += highestBid.amount;
            } else {
                pendingERC20Returns[highestBid.bidder][highestBid.payToken] += highestBid.amount;
            }
        }

        highestBid = Bid(msg.sender, erc20, amount, usdValue);
        emit BidPlaced(msg.sender, erc20, amount, usdValue);
    }

    // Withdraw refunds
    function withdrawRefund() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function withdrawERC20Refund(address erc20) external {
        uint256 amount = pendingERC20Returns[msg.sender][erc20];
        if (amount > 0) {
            pendingERC20Returns[msg.sender][erc20] = 0;
            require(IERC20(erc20).transfer(msg.sender, amount), "ERC20 refund failed");
        }
    }

    // End auction and transfer NFT and funds
    function endAuction() external onlyAfterEnd {
        require(!ended, "Already ended");
        ended = true;

        if (highestBid.bidder != address(0)) {
            // Transfer NFT to winner
            NtfERC721(nft).safeTransferFrom(seller, highestBid.bidder, tokenId);

            // Transfer funds to seller
            if (highestBid.payToken == address(0)) {
                payable(seller).transfer(highestBid.amount);
            } else {
                require(IERC20(highestBid.payToken).transfer(seller, highestBid.amount), "ERC20 payout failed");
            }
        } else {
            // No bids, NFT stays with seller
        }

        emit AuctionEnded(highestBid.bidder, highestBid.payToken, highestBid.amount, highestBid.usdValue);
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// --- Auction Factory (UUPS Upgradeable, UniswapV2-like) ---
contract NFTAuctionFactory is UUPSUpgradeable, Ownable {
    event AuctionCreated(address indexed auction, address indexed nft, uint256 indexed tokenId);

    address[] public allAuctions;
    mapping(address => mapping(uint256 => address)) public getAuction; // nft => tokenId => auction
    address public priceOracle;

    function initialize(address _priceOracle) external {
        require(priceOracle == address(0), "Already initialized");
        priceOracle = _priceOracle;
    }

    function createAuction(
        address nft,
        uint256 tokenId,
        uint256 duration
    ) external returns (address auction) {
        require(getAuction[nft][tokenId] == address(0), "Auction exists");

        // Deploy new auction
        NFTAuction newAuction = new NFTAuction();
        newAuction.initialize(nft, tokenId, msg.sender, duration, priceOracle);

        // Transfer NFT to auction contract
        NtfERC721(nft).safeTransferFrom(msg.sender, address(newAuction), tokenId);

        auction = address(newAuction);
        getAuction[nft][tokenId] = auction;
        allAuctions.push(auction);

        emit AuctionCreated(auction, nft, tokenId);
    }

    function allAuctionsLength() external view returns (uint256) {
        return allAuctions.length;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// --- Chainlink CCIP Cross-chain Auction Placeholder ---
// In production, integrate Chainlink CCIP for cross-chain messaging and asset transfer.
// For demonstration, we provide a stub interface.
interface ICCIPCrossChainAuction {
    function sendBidCrossChain(
        uint64 destinationChainSelector,
        address auction,
        address payToken,
        uint256 amount
    ) external payable;
}
