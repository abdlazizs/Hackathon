// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IToken.sol";

contract LandRegistration{

    Itoken iToken;
    // the struct below is the struct that contains all details of the land
    struct LandDetails{
        string state;
        string district;
        string location;
        string landmark;
        uint plotNumber;
        address currentOwner;
        uint priceSelling;
        bool isAvailable;
        address requester;
        ReqStatus reqStatus;
    }
    //This enum here shows the request status
    enum ReqStatus{
        Default,
        Pending,
        Reject,
        Approved
    }
    //shows the unique numbers attached to a current owner
    struct profiles{
        uint[] assetList;
    }
    // a mapping that links the unique number to the specific land property
    mapping(uint => LandDetails) Land;
    // the address of the person that deploys the contract
    address Deployer;
    //a mapping that maps each district to its managers
    mapping(string => address) managers;
    // a mapping that maps each address to profiles(list of all lands the user has)
    mapping(address => profiles) profile ;
    //this constructor ensures that the deployer is the person who deployed the contract and is some sort of admin 
     constructor(address _account){
        Deployer = msg.sender;
        iToken = Itoken(_account);
    }

 function calculateNumber(uint _plotNumber,
        string memory _location,
        string memory _district,
        string memory _state) internal pure returns(uint _uniqueNumber){
            return uint(keccak256(abi.encodePacked(_plotNumber, _location, _district, _state)))%10000000000000;
        }

    function addManager(address _manager, string memory _district) public {
        require(msg.sender == Deployer, "Only Deployer can add Manager");
        managers[_district] = _manager;
    }

    //Registration of land details
    function register(string memory _state,string memory _district,
        string memory _location,
        string memory _landmark,
        uint _plotNumber,
        address payable _ownerAddress,
        uint _priceSelling) public returns(bool){
            uint _uniqueNumber = calculateNumber(_plotNumber, _location, _district,_state);
            require(Land[_uniqueNumber].plotNumber == 0, "Land already exists");
            require(msg.sender == managers[_district] || msg.sender == Deployer, "Only a manager of this district can register land owners");

            Land[_uniqueNumber].state = _state;
            Land[_uniqueNumber].district = _district;
            Land[_uniqueNumber].location = _location;
            Land[_uniqueNumber].landmark = _landmark;
            Land[_uniqueNumber].plotNumber = _plotNumber;
            Land[_uniqueNumber].currentOwner = _ownerAddress;
            Land[_uniqueNumber].priceSelling = _priceSelling;

            

            profile[_ownerAddress].assetList.push(_uniqueNumber);
        
            iToken.safeMint(_ownerAddress, _location) ;


            return true;
            
        }
        function checkId(address _addr) external view returns(uint) {

            return iToken.checkId(_addr);
        }

    // the owner function checks to show details of the land to the owner
    function Owner(uint _uniqueNumber) public view returns(string memory,
    string memory,string memory, uint256, bool, address, ReqStatus){
        return (Land[_uniqueNumber].state,
                Land[_uniqueNumber].district,
                Land[_uniqueNumber].location,
                Land[_uniqueNumber].plotNumber,
                Land[_uniqueNumber].isAvailable,
                Land[_uniqueNumber].requester,
                Land[_uniqueNumber].reqStatus);
    }
    // the buyer function checks to show details of the land to the buyer
    function Buyer(uint _uniqueNumber) public view returns(address, uint, bool, address, ReqStatus){
        return (Land[_uniqueNumber].currentOwner,
                Land[_uniqueNumber].priceSelling,
                Land[_uniqueNumber].isAvailable,
                Land[_uniqueNumber].requester,
                Land[_uniqueNumber].reqStatus);
    }

    //To push a request to the land owner
    function requestToLandOwner(uint _uniqueNumber) public{
        require(Land[_uniqueNumber].isAvailable, "This land is not available");
        Land[_uniqueNumber].requester = msg.sender;
        Land[_uniqueNumber].isAvailable = false;
        Land[_uniqueNumber].reqStatus = ReqStatus.Pending;
    }

    // To view assets of a particular address
    function viewAssets() public view returns(uint [] memory){
        return profile[msg.sender].assetList;
    }

    // to view requests on a particular land
    function viewRequest(uint _uniqueNumber) public view returns(address){
        return Land[_uniqueNumber].requester;
    }
    //processing the request for either accepted or rejected
    function processRequest(uint _uniqueNumber, ReqStatus status) public {
        require(Land[_uniqueNumber].currentOwner == msg.sender, "You cannot process request cause you are not the owner of the asset");
        Land[_uniqueNumber].reqStatus = status;
        if(status == ReqStatus.Reject){
            Land[_uniqueNumber].requester = address(0);
            Land[_uniqueNumber].reqStatus = ReqStatus.Default;
        }
    }
    //availing Land for sale
    function makeAvailable(uint _uniqueNumber) public{
        require(Land[_uniqueNumber].currentOwner == msg.sender, "Only owner of property can make it available");
        Land[_uniqueNumber].isAvailable = true;
    }

    //buying the approved land
    function purchaseLand(uint _uniqueNumber) external payable{
        require(Land[_uniqueNumber].reqStatus == ReqStatus.Approved, "The Owner of the land hasnt approved the sales");
        require(msg.value >= Land[_uniqueNumber].priceSelling, "The price should be more tha or equal to the selling price");
        
        (bool success, ) = payable(Land[_uniqueNumber].currentOwner).call{value: msg.value}("");
        require(success, "failed to send");
        removeOwnership(Land[_uniqueNumber].currentOwner, _uniqueNumber);
        Land[_uniqueNumber].currentOwner = msg.sender;
        Land[_uniqueNumber].isAvailable = false;
        Land[_uniqueNumber].requester = address(0);
        Land[_uniqueNumber].reqStatus = ReqStatus.Default;
        profile[msg.sender].assetList.push(_uniqueNumber);
        // iTicket.transferFrom(currentOwner, msg.sender, );
    }
    
    //removing the ownership of the seller of the land

    function removeOwnership(address _previousOwner, uint _uniqueNumber) private{
        uint index = findIndex(_uniqueNumber, _previousOwner);
        profile[_previousOwner].assetList[index] = profile[_previousOwner].assetList[profile[_previousOwner].assetList.length - 1];
        delete profile[_previousOwner].assetList[profile[_previousOwner].assetList.length - 1];
        profile[_previousOwner].assetList.length - 1;
    }

    //A function that finds the index of a particular unique number
    function findIndex(uint _id, address _addr) public view returns(uint){
        uint i;
        for(i=0;i<profile[_addr].assetList.length;i++){
            if(profile[_addr].assetList[i] == _id){
                return i;
            }
        }
        return i;
    }

   

    
}