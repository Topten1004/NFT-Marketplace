// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Legendary {

    struct legendary {
        bool resell ;
        uint256 product_price ;
        uint256 product_unit ;
        uint256 ticket_price ;
        uint256 ticket_unit;
        uint256 ticket_available ;
        uint256 royalty ;
        address creator ;
        bool sold ;
    }

    struct legen_param  {
        bool resell;
        uint256 product_price ;
        uint256 product_unit ;
        uint256 ticket_price ;
        uint256 ticket_unit ;
        uint256 ticket_available  ;
        uint256 royalty ;
    }

    address private _solsMarketplace = address(0);

    mapping(uint256 => legendary) private lists ;
    mapping(uint256 => mapping(address => uint256)) owners;
    mapping(uint256 => mapping(address => bool)) buyers ;

    constructor () {}
    
    function setSolsMarketplaceToLegen(address solsMarketplace) external {
        require(_solsMarketplace ==  address(0), "Legendary Contract: Don't attemp to change marketplace address!") ;

        _solsMarketplace = address(solsMarketplace) ;
    }

    function insertLegen(
        uint256 new_nft_id, 
        legen_param memory _legen_param,
        address creator, 
        bool sold
    ) external isCalledMarketplace {
        lists[new_nft_id] = legendary (
            _legen_param.resell,
            _legen_param.product_price ,
            _legen_param.product_unit,
            _legen_param.ticket_price ,
            _legen_param.ticket_unit,
            _legen_param.ticket_available ,
            _legen_param.royalty ,
            creator,
            sold
        );
        owners[new_nft_id][creator] = 1 ;
    }

    function updateSold(uint256 nft_id, bool sold) external isCalledMarketplace {
        lists[nft_id].sold = sold ;
    }
    function updateOwner(uint256 nft_id, uint256 index, address _owner) external isCalledMarketplace {
        owners[nft_id][_owner] = index ;
    }
    function updateBuyer(uint256 nft_id, address _buyer) external isCalledMarketplace {
        buyers[nft_id][_buyer] = true ;
    }
    function deleteOwner(uint256 nft_id, address owner) external isCalledMarketplace {
        delete(owners[nft_id][owner]) ;
    }

    function fetchLegen(uint256 nft_id) external view returns(legendary memory) {
        return lists[nft_id] ;
    }
    function checkOwner(uint256 nft_id , address _owner) external view returns(bool) {
        if(owners[nft_id][_owner] > 0) return true ;
        return false ;
    }
    function checkResell(uint256 nft_id) external view returns(bool) {
        return lists[nft_id].resell ;
    }
    function checkBuyer(uint256 nft_id, address _buyer) external view returns(bool) {
        if(buyers[nft_id][_buyer]) return true ;
        return false ;
    }
    function checkOwnerOrBuyer(uint256 nft_id, address _address) external view returns(bool) {
        if(buyers[nft_id][_address] || owners[nft_id][_address] > 0) return true ;
        return false ;
    }
    function ownerIndex(uint256 nft_id, address owner) external view returns(uint256) {
        return owners[nft_id][owner] ;
    }

    modifier isCalledMarketplace() {
        require(_solsMarketplace == msg.sender, "isCalledMarketplace: you can't call this function") ;
        _;
    }
}