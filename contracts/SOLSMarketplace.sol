// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SOLSNFT.sol" ;

contract SOLSMarketplace is Ownable {
    using Counters for Counters.Counter ;
    Counters.Counter nft_counter ;

    SOLSNFT private SOLN ;

    address marketplace_owner ;
   
    struct nft {
        address creator_used_wallet ;
        string creator_uuid_hash ;
        uint256 nft_id ;
        uint256 nft_type ;
        uint256 nft_price ;
        uint256 resell_price ;
        uint256 minted_amount ;
        uint256 royalty ;
        bool resell ;
        string uri ;
    }

    struct nft_param {
        address creator_used_wallet ;
        string creator_uuid_hash ;
        uint256 nft_type ;
        uint256 nft_price ;
        uint256 resell_price ;
        uint256 minted_amount ;
        uint256 royalty ;
        bool resell ;
        string uri ;
    }

    struct nft_owner {
        address used_wallet ;
        string  uuid_hash ;
    }    

    nft[] private nfts ;

    mapping(uint256 => nft_owner[] ) private owners ;

    event NFTListed(uint256) ;

    constructor ( address _SOLN ) {
        SOLN = SOLSNFT(_SOLN) ;

        marketplace_owner = msg.sender ;

        SOLN.setSolsMarketplaceToNFT(address(this));
    }

    function mintNFT( nft_param memory _params ) external onlyOwner{
        require(_params.creator_used_wallet != address(0), "creator wallet error") ;
        // require(_params.nft_price > 0, "nft price error") ;
        // require(_params.minted_amount > 0, "minted amount error") ;

        // if(_params.resell) require(_params.resell_price > 0, "resell price error") ;

        uint256 new_nft_id = nft_counter.current();

        nft_counter.increment() ;

        nfts.push(
            nft(
                _params.creator_used_wallet,
                _params.creator_uuid_hash,
                new_nft_id,
                _params.nft_type,
                _params.nft_price,
                _params.resell_price,
                _params.minted_amount,
                _params.royalty,
                _params.resell,
                _params.uri
            )
        ) ;

        SOLN.mint(_params.creator_used_wallet, new_nft_id , _params.minted_amount);

        emit NFTListed(new_nft_id);
    }

    function sellNFT( address _to, string memory uuid_hash, uint256 nft_id, uint256 amount ) external isValidNftId(nft_id) onlyOwner {
        require(SOLN.balanceOf(nfts[nft_id].creator_used_wallet, nft_id) > 1) ;
        require(SOLN.balanceOf(nfts[nft_id].creator_used_wallet, nft_id) > amount ) ;

        SOLN.transfer(nft_id, nfts[nft_id].creator_used_wallet, _to, amount ) ;

        nft_owner memory new_owner = nft_owner(
            _to,
            uuid_hash
        );

        owners[nft_id].push(new_owner) ;
    }

    function fetchAllNFTs() external view returns(nft[] memory) {
        return nfts ;
    }

    // function fetchOwners(uint256 nft_id) external view returns(nft_owner[] memory) {
    //     return owners[nft_id] ;
    // } 
    
    // function fetchNFTById(uint256 nft_id) external view returns(nft memory) {
    //     return nfts[nft_id] ;
    // }

    // function fetchSupplyAmount() external view returns(uint256) {
    //     return nfts.length ;
    // }

    modifier isValidNftId(uint256 nft_id) {
        require(nft_id < nft_counter.current(), "Nft id is invalid") ;
        _;
    }
}
