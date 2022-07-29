// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct tokenData{
        address payable owner;
        string eventId;
        uint64 totaltokens;
    }
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
   tokenData[] tokens;
   mapping(address => tokenData)  private mytokens;
   

    // Mapping owner address to token count
    
   mapping(address => uint) public balance;
    constructor() ERC721("MyToken", "MTK") {}

    function checkId(address _addr) external view returns(uint){
        return _balances[_addr];
    }


    function bulkMint(string calldata _eventId, uint64 _totaltokens ) external  {
    //    uint [i] = _totaltokens;
        
        tokenData memory newtokenData = tokenData({
            owner: payable(msg.sender),
            eventId:_eventId,
            totaltokens:_totaltokens
        });
        for(uint i  = 0; i < _totaltokens; i++ ) {
            if( i < _totaltokens)
            safeMint(msg.sender, _eventId);
        }
        tokens.push(newtokenData);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function purchase(string memory _eventId, uint _totaltokens) external {



    }
     function transfer(address _receiver, uint _totaltokens) external  returns(bool){
        balance[msg.sender] -= _totaltokens;
        balance[_receiver] += _totaltokens;
        mytokens[msg.sender].totaltokens - _totaltokens;
        return true;
    }
    

    function safeMint(address to, string memory uri) public  {
        uint256 tokenId = _tokenIdCounter.current();
        _balances[to] = tokenId;
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function token_owner(uint tokenId) external view returns(address){
       return _owners[tokenId];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
}