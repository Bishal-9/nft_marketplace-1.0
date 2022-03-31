// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {

    // State variables
    address payable public immutable feeAccount; // The account that receives fees
    uint public immutable feePercent; // The fee percent on sales
    uint public itemCount;

    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    // Creating event for storing in blockchain
    event Offered (
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );
    event Bought (
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    mapping(uint => Item) public items;

    constructor(uint _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function makeItem (IERC721 _nft, uint _tokenId, uint _price) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");

        // Increase itemCount
        itemCount++;

        // Transfer NFT
        _nft.transferFrom(msg.sender, address(this), _tokenId);

        // Add new item to items mapping
        items[itemCount] = Item (
            itemCount,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );

        // Emit Offered event
        emit Offered (
            itemCount,
            address(_nft),
            _tokenId,
            _price,
            msg.sender
        );
    }

    function purchaseItem(uint _itemId) external payable nonReentrant {
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];
        require (_itemId > 0 && _itemId <= itemCount, "Item doesn't exist.");
        require (msg.value >= _totalPrice, "Not enough ETH to cover item price and market fee.");
        require (!item.sold, "Item is already sold.");

        // Pay seller and  feeAccount
        item.seller.transfer(item.price);
        feeAccount.transfer(_totalPrice - item.price);

        // Update item to sold
        item.sold = true;

        // Transfer NFT
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);

        // Emit Bought event
        emit Bought (
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }

     function getTotalPrice (uint _itemId) view public returns (uint) {
         return (items[_itemId].price * (100 + feePercent) / 100);
     }
}