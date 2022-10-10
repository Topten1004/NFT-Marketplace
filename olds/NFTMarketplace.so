// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter ;

    Counters.Counter nft_counter ;
    Counters.Counter nft_sold_counter ;

    // address private owner ;
    uint256 private royalty_fee = 5 ;
    uint256 private max_supply = 10000 ;
    mapping(uint256 => nft) private nfts ;
    string[] private collections = ["sport","policy","game","video","image","music"] ;

    struct nft {
        uint256 nft_id ;
        string collection_name ;
        string nft_name ;
        string nft_description ;
        string nft_uri ;
        uint256 nft_price ;
        address payable owner ;
        address payable seller ;
        bool sold ;
        // uint256 royalty ;
    }

    uint256 listing_price = 0.025 ether ;

    constructor() ERC721("Metaverse", "METT") {
        // owner = payable(msg.sender) ;
    }

    function createNFT(string memory cname, string memory name, string memory description, string memory uri, uint256 price) public payable returns(uint256){
        require(price > 0, "createNFT: price is too low");
        require(msg.value == listing_price, "createNFT: msg.value != listing_price") ;
        require(nft_counter.current() < max_supply, "createNFT: overflow supply");
        require(checkCollectionName(cname), "Invalid Collection");

        nft_counter.increment() ;

        uint256 new_nft_id = nft_counter.current() ;

        _safeMint(msg.sender, new_nft_id) ;
        _setTokenURI(new_nft_id, uri);

        nfts[new_nft_id] = nft(
            new_nft_id,
            cname,
            name,
            description,
            uri,
            price,
            payable(address(this)),
            payable(msg.sender),
            false
        );

        _transfer(msg.sender, address(this), new_nft_id);

        return new_nft_id ;
    }

    function buyNFT(uint256 tokenId) public payable {
        uint256 price = nfts[tokenId].nft_price ;
        address seller = nfts[tokenId].seller ;

        require(price > 0) ;
        require(msg.value == price) ;

        nfts[tokenId].owner = payable(msg.sender) ;
        nfts[tokenId].seller = payable(address(0)) ;
        nfts[tokenId].sold = true ;

        nft_sold_counter.increment() ;

        _transfer(address(this), msg.sender, tokenId) ;

        payable(owner()).transfer(listing_price + msg.value * royalty_fee / 100) ;
        payable(seller).transfer(msg.value * (100 - royalty_fee) / 100) ;
    }

    function resellNFT(uint256 tokenId, uint256 price) public payable {
        require(msg.sender == nfts[tokenId].owner) ;
        require(msg.value == listing_price) ;

        nfts[tokenId].owner = payable(address(this)) ;
        nfts[tokenId].seller = payable(msg.sender) ;
        nfts[tokenId].nft_price = price ;
        nfts[tokenId].sold = false ;

        nft_sold_counter.decrement() ;
        
        _transfer(msg.sender, address(this), tokenId) ;
    }

    function fetchSoldNFTs() public view returns(nft[] memory) {

        uint256 sold_nfts_count = 0 ;
        uint256 current_index = 0 ;

        for(uint256 i = 0 ; i < nft_counter.current(); i++) {
            if(nfts[i+1].sold == true) {
                sold_nfts_count++;
            }
        }

        nft[] memory sold_nfts = new nft[]( sold_nfts_count ) ;

        for(uint256 i = 0 ; i < nft_counter.current() ; i++) {
            if(nfts[i+1].sold == true) {
                sold_nfts[current_index] = nfts[i+1] ;
                current_index++;
            }
        }

        return sold_nfts ;
    }

    function fetchUnsoldNFTs() public view returns(nft[] memory) {
        
        uint256 unsold_nft_count = 0 ;
        uint256 current_index = 0 ;

        for(uint256 i = 0 ; i < nft_counter.current(); i++) {
            if(nfts[i+1].sold == false) {
                unsold_nft_count++ ;
            }
        }

        nft[] memory unsold_nfts = new nft[](unsold_nft_count) ;

        for(uint256 i = 0 ; i < nft_counter.current() ; i++) {
            if(nfts[i+1].sold == false) {
                unsold_nfts[current_index] = nfts[i+1] ;
                current_index++;
            }
        }

        return unsold_nfts ;
    }
    
    function fetchMyNFTs() public view returns(nft[] memory) {
        uint256 myNft_count = 0 ;
        uint256 current_index = 0 ;

        for(uint256 i = 0 ; i < nft_counter.current() ; i++) {
            if(nfts[i+1].owner == msg.sender) {
                myNft_count++ ;
            }
        }

        nft[] memory myNfts = new nft[](myNft_count) ;

        for(uint256 i = 0 ; i < nft_counter.current(); i++) {
            if(nfts[i+1].owner == msg.sender) {
                myNfts[current_index] = nfts[i+1];
                current_index++ ; 
            }
        }

        return myNfts ;
    }

    function fetchNFTs() public view returns(nft[] memory) {
        nft[] memory all_nfts = new nft[](nft_counter.current());

        for(uint256 i = 0 ; i < nft_counter.current() ; i++){
            all_nfts[i] = nfts[i+1] ;
        }

        return all_nfts ;
    }

    function fetchListedNFTs() public view returns(nft[] memory) {

        uint256 listed_nft_count = 0;
        
        for(uint256 i = 0 ; i < nft_counter.current() ; i++) {
            if(nfts[i+1].seller == msg.sender) {
                listed_nft_count++ ;
            }
        }

        nft[] memory listed_nfts = new nft[](listed_nft_count) ;
        uint256 current_index = 0 ;

        for(uint256 i = 0 ; i < nft_counter.current() ; i++) {
            if(nfts[i+1].seller == msg.sender) {
                listed_nfts[current_index] = nfts[i+1] ;

                current_index++;
            }
        }

        return listed_nfts ;
    }

    function checkCollectionName(string memory cname) public view returns(bool) {
        bool isExist = false ;

        for(uint256 i = 0 ; i < collections.length ; i++){
            if(keccak256(abi.encodePacked(collections[i])) == keccak256(abi.encodePacked(cname))){
                isExist = true ;
                break ;
            }
        }   

        return isExist ;
    }

    function getOwnerAddress() public view returns(address) {
        return owner();
    }

    function getContractBalance() public view returns (uint256){
        return payable(address(this)).balance;
    }

    function getRoyaltyFee() public view onlyOwner returns(uint) {
        return royalty_fee ;
    }

    function updateRoyaltyFee(uint256 new_royalty_fee) public onlyOwner{
        royalty_fee = new_royalty_fee ;
    }
    
    function getCollectionNames() public view returns(string[] memory) {
        return collections ;
    }
}
