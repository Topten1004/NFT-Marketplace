// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SOLSNFT.sol" ;
import "./SOLSTOKEN.sol" ;
import "./Legendary.sol" ;
import "./Rare.sol" ;
import "./Bid.sol";

contract SOLSMarketplace is Ownable{
    using Counters for Counters.Counter ;
    Counters.Counter nft_counter ;

    SOLSTOKEN private SOLT;
    SOLSNFT private SOLN ;
    Legendary private LEGEN ;
    Rare private RARE ;
    Bid private BID ;

    address marketplace_owner ;

    address[] private units ;
    string[] private product_types = ["Ebook","Video","Image","Music"] ;
    string[] private price_types = ["legendary", "rare"] ;
   
    struct nft {
        uint256 nft_id;
        uint256 product_id ;
        uint256 price_id ;
        string name ;
        string description ;
        string uri ;
        address[] owners;
    }

    mapping(uint256 => nft) private nfts ;

    event NFTListed(uint256) ;

    constructor ( address _SOLT, address _LEGEN, address _RARE, address _BID, address _SOLN ) {
        SOLT = SOLSTOKEN(_SOLT);
        LEGEN = Legendary(_LEGEN) ;
        RARE = Rare(_RARE) ;
        BID = Bid(_BID) ;
        SOLN = SOLSNFT(_SOLN) ;

        marketplace_owner = msg.sender ;

        LEGEN.setSolsMarketplaceToLegen(address(this));
        RARE.setSolsMarketplaceToRare(address(this));
        BID.setSolsMarketplaceToBid(address(this)) ;
        SOLN.setSolsMarketplaceToNFT(address(this));

        units.push(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede);
        units.push(_SOLT) ;
    }

    function mintNFT(
        address _from,
        uint256 _amount,
        uint256 product_id, 
        uint256 price_id,
        string memory name,
        string memory description,
        string memory uri
    ) 
    private returns(uint256) {
        uint256 new_nft_id = nft_counter.current();

        nft_counter.increment() ;

        nfts[new_nft_id].nft_id = new_nft_id ;
        nfts[new_nft_id].product_id = product_id ;
        nfts[new_nft_id].price_id = price_id ;
        nfts[new_nft_id].name = name ;
        nfts[new_nft_id].description = description ;
        nfts[new_nft_id].uri = uri ;
        nfts[new_nft_id].owners.push(_from) ;

        SOLN.mint(_from, new_nft_id , _amount);

        return new_nft_id ;
    }

    function mintLegendary(
        address creator,
        uint256 product_id,
        Legendary.legen_param memory _legen_param,
        string memory name,
        string memory description,
        string memory uri
    ) external isValidProductId(product_id) isValidUnitId(_legen_param.product_unit) isValidUnitId(_legen_param.ticket_unit) onlyOwner  {
        require(_legen_param.product_price > 0, "Product price is too low");
        require(_legen_param.ticket_price > 0, "Ticket price is too low");
        require(_legen_param.ticket_available > 0, "# of Tickets available should be bigger than 0") ;
        require(_legen_param.royalty >= 1, "Royalty should be bigger than 1") ;

        uint256 new_nft_id ;
        if(_legen_param.resell) new_nft_id = mintNFT(creator, _legen_param.ticket_available , product_id , 1, name, description, uri) ;
        else new_nft_id = mintNFT(creator, 1 , product_id , 1, name, description, uri) ;

        LEGEN.insertLegen(new_nft_id, _legen_param, creator, false);
        LEGEN.updateOwner(new_nft_id, 1,  creator);
        emit NFTListed(new_nft_id) ;
    }

    function buyLegendaryAsNFT(uint256 nft_id) external isValidNftId(nft_id) isLegendary(nft_id) onlyOwner {
        address buyer = msg.sender ;

        Legendary.legendary memory _legen = LEGEN.fetchLegen(nft_id);
        address creator =  _legen.creator;
        uint256 ticket_unit = _legen.ticket_unit ;
        uint256 ticket_price = _legen.ticket_price ;

        require(_legen.resell, "This nft can not be resell");
        require(!LEGEN.checkOwner(nft_id, buyer), "You have already reseller role about this nft") ;
        require(!_legen.sold, "All these nfts have already been sold to resellers") ;
        
        require(IERC20(units[ticket_unit]).balanceOf(buyer) >= ticket_price, "Reseller have not enough balance");
        
        require(IERC20(units[ticket_unit]).transferFrom(buyer, marketplace_owner, ticket_price * 1 / 100), "Failed to send from buyer to marketplace") ;
        require(IERC20(units[ticket_unit]).transferFrom(buyer, creator , ticket_price * (100 - 1) / 100), "Failed to send from buyer to creator") ;

        SOLN.transfer(nft_id, creator, buyer, 1) ;

        uint256 _balanceOfOwner = SOLN.balanceOf(creator, nft_id); 

        if(_balanceOfOwner == 0) {
            address last_owner = nfts[nft_id].owners[nfts[nft_id].owners.length -1];

            nfts[nft_id].owners[0] = last_owner ;
            nfts[nft_id].owners.pop() ;

            LEGEN.updateSold(nft_id, true) ;
            LEGEN.updateOwner(nft_id,  1, last_owner) ;
            LEGEN.deleteOwner(nft_id, creator);
        }

        nfts[nft_id].owners.push(buyer) ;
        LEGEN.updateOwner(nft_id, nfts[nft_id].owners.length, buyer);

        delete _legen ;
    }

    function buyLegendaryAsProduct(uint256 nft_id, address wallet) external isValidNftId(nft_id) isLegendary(nft_id) isNotOwner(msg.sender) {
        address buyer = msg.sender ;

        Legendary.legendary memory _legen = LEGEN.fetchLegen(nft_id);
        uint256 product_unit = _legen.product_unit ;
        uint256 product_price = _legen.product_price ;

        require(!LEGEN.checkBuyer(nft_id, buyer), "You have already bought this nft") ;
        require(!LEGEN.checkOwner(nft_id, buyer), "You have already reseller role about this nft") ;
        require(LEGEN.checkOwner(nft_id, wallet), "Receiver is not owner of this product") ;

        require(IERC20(units[product_unit]).balanceOf(buyer) >= product_price, "Buyer have not enough balance");

        IERC20(units[product_unit]).transferFrom(buyer, marketplace_owner, product_price * 1 / 100);
        IERC20(units[product_unit]).transferFrom(buyer, wallet, product_price * (100 - 1) / 100);

        LEGEN.updateBuyer(nft_id, buyer);

        delete _legen ;
    }

    function mintRare(
        uint256 product_id,
        Rare.rare_param memory _rare_param,
        string memory name,
        string memory description,
        string memory uri
    ) public isValidProductId(product_id) isValidUnitId(_rare_param.bid_unit) isNotOwner(msg.sender) {
        require(_rare_param.minimum_bidding > 0, "Minimum bid price is too low");
        require(_rare_param.item_available > 0, "# of Item available should be bigger than 0");
        require(_rare_param.royalty >= 1, "Royalty should be bigger than 1") ;

        address creator = msg.sender ;
        uint256 new_nft_id = mintNFT(msg.sender, _rare_param.item_available , product_id, 2, name, description, uri) ;

        RARE.insertRare(
            new_nft_id,
            _rare_param,
            creator,
            false
        ) ;

        RARE.updateOwner(new_nft_id, creator, 1);

        emit NFTListed(new_nft_id) ;
    }

    function placeBid(uint256 nft_id, uint256 _amount, uint256 _price) external isValidNftId(nft_id) isRare(nft_id) {
        Rare.rare memory _rare = RARE.fetchRare(nft_id);

        address creator = _rare.creator ;
        uint256 _amount_of_creator = SOLN.balanceOf(creator, nft_id) ;

        require(_amount_of_creator >= _amount, "Bid price is higher than balance of creator") ;
        require(!_rare.sold, "All these nfts have been sold out") ;
        require(_rare.creator != msg.sender , "You are creator of this nft") ;
        require(_rare.item_available >= _amount, "Amount is higher than # of item available") ;
        require(_rare.minimum_bidding <= _price, "Bid price is lower than minimum bid price") ;

        BID.place(nft_id, creator, msg.sender, _amount, _price) ;

        delete _rare ;
    }

    function acceptBid(uint256 bid_id) external isNotOwner(msg.sender) {
        Bid.bid memory _bid = BID.fetchBid(bid_id) ;
        Rare.rare memory _rare = RARE.fetchRare(_bid.nft_id);

        require(_rare.creator == msg.sender, "You can't accept this bid") ;
        require(BID.isPending(bid_id), "This bid is already checked.") ;

        address buyer = _bid.to ;
        uint256 nft_id = _bid.nft_id ;
        uint256 _amount = _bid.amount ;
        uint256 _price = _bid.price ;

        address creator = _rare.creator;
        bool sold = _rare.sold;

        require(!sold, "All these nfts have been sold out") ;

        uint256 _balanceOfCreator = SOLN.balanceOf(creator, nft_id);
        
        require( _balanceOfCreator >= _amount, 'Bid amount is higher than your balance') ;

        require(IERC20(units[_rare.bid_unit]).balanceOf(buyer) >= _price , "Buyer have not enough balance");

        IERC20(units[_rare.bid_unit]).transferFrom(buyer, marketplace_owner, _price * 1 / 100);
        IERC20(units[_rare.bid_unit]).transferFrom(buyer, creator, _price * (100 - 1) / 100);
        // onERC1155Received(address(this), buyer, nft_id, _amount, "");
        SOLN.transfer(nft_id, creator, buyer, _amount);

        if(_balanceOfCreator - _amount == 0) {
            address last_owner = nfts[nft_id].owners[nfts[nft_id].owners.length - 1] ;
            
            nfts[nft_id].owners[0] = last_owner ;
            nfts[nft_id].owners.pop() ;

            RARE.updateOwner(nft_id, last_owner, 1);
            RARE.updateSold(nft_id, true);
        }

        nfts[nft_id].owners.push(buyer) ;
        RARE.updateOwner(nft_id, buyer, nfts[nft_id].owners.length);

        BID.accept(bid_id) ;

        uint256 left_balanceOfCreator = SOLN.balanceOf(creator, nft_id);

        BID.autoCheck(bid_id, left_balanceOfCreator) ;

        delete _rare ;
        delete _bid ;
    }

    function payment(address _to, uint256 price, uint256 price_unit) external  isValidUnitId(price_unit) isNotOwner(msg.sender) {
        require(IERC20(units[price_unit]).balanceOf(msg.sender) >= price , "Buyer have not enough balance");

        IERC20(units[price_unit]).transferFrom(msg.sender, marketplace_owner, price * 1 / 100);
        IERC20(units[price_unit]).transferFrom(msg.sender, _to, price * (100 - 1) / 100);
    }

    function fetchAllNFTs() external view returns(nft[] memory) {
        nft[] memory _nfts = new nft[](nft_counter.current()) ;

        for(uint256 i = 0 ; i < nft_counter.current(); i++) {
            _nfts[i] = nfts[i] ;
        }
        
        return _nfts ;
    }

    function fetchUnitById(uint256 unit_id) external view returns(address) {
        return units[unit_id] ;
    }
    function fetchNFTById(uint256 nft_id) external view returns(nft memory) {
        return nfts[nft_id] ;
    }
    function _marketplace () external view returns(address) {
        return marketplace_owner ;
    }
    modifier isValidNftId(uint256 nft_id) {
        require(nft_id < nft_counter.current(), "Nft id is invalid") ;
        _;
    }
    modifier isOwner(address account) {
        require(account == marketplace_owner, "Your are owner of contract") ;
        _;
    }
    modifier isLegendary(uint256 nft_id) {
        require(nfts[nft_id].price_id == 1, "This nft price type isn't legendary");
        _;
    }
    modifier isRare(uint256 nft_id) {
        require(nfts[nft_id].price_id == 2, "This nft price type isn't rare");
        _;
    }
    modifier isValidProductId(uint256 product_id) {
        require(product_id < product_types.length) ;
        _;
    }
    modifier isValidUnitId(uint256 unit_id) {
        require(unit_id < units.length) ;
        _;
    }
}
