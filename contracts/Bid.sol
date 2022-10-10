// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Bid {
    using Counters for Counters.Counter ;

    Counters.Counter bid_counter ;

    address private _solsMarketplace = address(0);
    enum BidStatus { Pending, Accepted, Denied }

    struct bid {
        uint256 bid_id ;
        uint256 nft_id ;
        address from ;
        address to ;
        uint256 amount ;
        uint256 price ;
        BidStatus status ;
        uint256 placed_at ;
        uint256 checked_at ;
    }

    mapping(uint256 => bid) private bids ;

    constructor () {}

    function setSolsMarketplaceToBid(address solsMarketplace) external {
        require(_solsMarketplace ==  address(0), "Don't attemp to change marketplace address!") ;

        _solsMarketplace = solsMarketplace ;
    }

    function place(uint256 nft_id, address _from, address _to, uint256 _amount, uint256 _price) external isCalledMarketplace {
        uint256 new_bid_id = bid_counter.current();

        bids[new_bid_id].bid_id = new_bid_id ;
        bids[new_bid_id].nft_id = nft_id ;
        bids[new_bid_id].from = _from ;
        bids[new_bid_id].to = _to ;
        bids[new_bid_id].amount = _amount ;
        bids[new_bid_id].price = _price ;
        bids[new_bid_id].placed_at = block.timestamp ;
        bids[new_bid_id].checked_at = block.timestamp ;
        bids[new_bid_id].status = BidStatus.Pending ;

        bid_counter.increment();
    }

    function accept(uint256 bid_id) external isValidBidId(bid_id) isCalledMarketplace {
        bids[bid_id].status = BidStatus.Accepted ;
        bids[bid_id].checked_at = block.timestamp ;
    }

    function denyBid(uint256 bid_id) external isValidBidId(bid_id) {
        require(bids[bid_id].from == msg.sender, "You can't deny this bid") ;

        bids[bid_id].status = BidStatus.Denied ;
        bids[bid_id].checked_at = block.timestamp ;
    }

    function autoCheck(uint256 bid_id, uint256 balanceOfCreator) external isValidBidId(bid_id) isCalledMarketplace {
        for(uint256 i = 0 ; i < bid_counter.current() ; i++) {
            if(
                bids[i].amount > balanceOfCreator 
                && bids[i].status == BidStatus.Pending 
                && bids[i].nft_id == bids[bid_id].nft_id
            ) {
                bids[i].status = BidStatus.Denied ;
                bids[i].checked_at = block.timestamp ;
            }
        }
    }

    function fetchBid(uint256 bid_id) external isValidBidId(bid_id) view returns(bid memory){
        return bids[bid_id] ;
    }
    function isPending(uint256 bid_id) external isValidBidId(bid_id) view returns(bool) {
        if(bids[bid_id].status == BidStatus.Pending) return true ;
        return false ;
    }

    function fetchBidsByOwner(address _owner) external view returns(bid[] memory) {
        uint256 _count = 0 ;

        for(uint256 i = 0 ; i < bid_counter.current(); i++) {
            if(bids[i].from == _owner) {
                _count ++;
            }
        }

        bid[] memory _bids = new bid[](_count) ;
        _count = 0 ;

        for(uint256 i = 0 ; i < bid_counter.current(); i++) {
            if(bids[i].from == _owner) {
                _bids[_count] = bids[i] ;
                _count ++;
            }
        }

        return _bids ;
    }
    function fetchOrdersByBidder(address _bidder) external view returns(bid[] memory) {
        uint256 _count = 0 ;

        for(uint256 i = 0 ; i < bid_counter.current(); i++) {
            if(bids[i].to == _bidder) {
                _count ++;
            }
        }

        bid[] memory _bids = new bid[](_count) ;
        _count = 0 ;

        for(uint256 i = 0 ; i < bid_counter.current(); i++) {
            if(bids[i].to == _bidder) {
                _bids[_count] = bids[i] ;
                _count ++;
            }
        }

        return _bids ;
    }
    modifier isValidBidId(uint256 bid_id) {
        require(bid_counter.current() > bid_id, "Bid Contract: Bid id is invalid") ;
        _;
    }
    modifier isCalledMarketplace() {
        require(_solsMarketplace == msg.sender, "isCalledMarketplace: you can't call this function") ;
        _;
    }
}