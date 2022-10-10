// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Rare {

     struct rare {
        uint256 minimum_bidding ;
        uint256 bid_unit;
        uint256 item_available ;
        uint256 royalty ;
        address creator ;
        bool sold ;
    }

    struct rare_param {
        uint256 minimum_bidding ;
        uint256 bid_unit ;
        uint256 item_available  ;
        uint256 royalty ;
    }

    address private _solsMarketplace = address(0);

    mapping(uint256 => rare) private lists ;
    mapping(uint256 => mapping(address => uint256)) owners ;

    constructor () {}

    function setSolsMarketplaceToRare(address solsMarketplace) external {
        require(_solsMarketplace ==  address(0), "Rare Contract: Don't attemp to change marketplace address!") ;

        _solsMarketplace = address(solsMarketplace) ;
    }

    function insertRare(
        uint256 new_nft_id, 
        rare_param memory _rare_param,
        address creator, 
        bool sold
    ) external isCalledMarketplace {
        lists[new_nft_id] = rare (
            _rare_param.minimum_bidding ,
            _rare_param.bid_unit,
            _rare_param.item_available ,
            _rare_param.royalty ,
            creator,
            sold
        );
        owners[new_nft_id][creator] = 1 ;
    }

    function updateSold(uint256 nft_id, bool sold) external isCalledMarketplace {
        lists[nft_id].sold = sold ;
    }
    function updateOwner(uint256 nft_id, address owner, uint256 index) external isCalledMarketplace {
        owners[nft_id][owner] = index ;
    }

    function fetchRare(uint256 nft_id) external view returns(rare memory) {
        return lists[nft_id] ;
    }
    function checkOwner(uint256 nft_id , address _owner) external view returns(bool) {
        if(owners[nft_id][_owner] > 0) return true ;
        return false ;
    }

     modifier isCalledMarketplace() {
        require(_solsMarketplace == msg.sender, "isCalledMarketplace: you can't call this function") ;
        _;
    }
}