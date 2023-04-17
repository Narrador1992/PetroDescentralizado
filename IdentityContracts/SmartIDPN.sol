// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./SmartIDFactory.sol";
import "./SmartChecks.sol";
import "../BridgeContracts/SmartAddress.sol";

contract SmartID{

    address public Owner;
    address public recovery;
    address _referral;
    
    uint VacationTime;
    uint Time;
    uint timeBackUp;

    mapping (uint => string) StringData; //pseudonim, birthplace and occupation
    mapping (uint => uint) NumberData; //birthday, experience
    mapping (uint => bytes32) Documents; //personal ID documents (contactDetails, governmentID, bankcertificates,personalreferences, educationcertificates, medicaldata)
    mapping (uint => bool) checked;
    mapping (address => bool) Whitelist;
    mapping (address => bool) FreezeTransfer;
    mapping (address => mapping(uint => bool)) Confirmation;
    mapping (uint => address) candidate;
    mapping (uint => address) Protector;
    mapping (uint => address) ForcedAddress;

    bool whitelistActivate;
    bool Vacation;
    bool allchecked;

    SmartAddress SA = SmartAddress(address(0));

    constructor(string memory _pseudonim, string memory _birthplace, uint _birthday_ddmmaaaa, string memory _occupation, uint _experience, address _recovery){ //checked
        require(msg.sender != _recovery);
        Owner = msg.sender;
        StringData[1] = _pseudonim;
        StringData[2] = _birthplace;
        StringData[3] = _occupation;
        NumberData[1] = _birthday_ddmmaaaa;
        NumberData[2] = _experience;
        recovery = _recovery;
        Time = block.timestamp;
        uint i = 1;
        for (i; i <= 5; i++){
            checked[i] = true;
        }
    }

    modifier OnlyOwner(){
        require(msg.sender == Owner);
        _;
    }

    modifier OnlyRecovery(){
        require(msg.sender == recovery);
        _;
    }

    //Identity Functions

    function uploadCoreHash(uint InternalIndex, bytes32 File) public OnlyOwner{ //Checked
        require(InternalIndex >= 1);
        checked[InternalIndex + 5] = false; 
        if(InternalIndex <= 2){
            allchecked = false;
        }
        Documents[InternalIndex] = File;
    }

    function changeData(uint InternalIndex, uint InternalBenchmark, string memory stringdata, uint numberdata) public OnlyOwner{ // checked
        require(InternalBenchmark == 1 || InternalBenchmark == 2);
        if(InternalBenchmark == 1){
            require(InternalIndex == 2 || InternalIndex == 3);
            StringData[InternalIndex] = stringdata;
            checked[InternalIndex] = false;
            allchecked = false;
        } else {
            require(InternalIndex == 1 || InternalIndex == 2);
            NumberData[InternalIndex] = numberdata;
            checked[InternalIndex + 3] = false;
            allchecked = false;
        }
    }

    function search(uint InternalIndex, uint InternalBenchmark) public view returns (string memory, uint, bytes32){ //checked
        require(InternalBenchmark <= 3 && InternalBenchmark >= 1);
        if(InternalBenchmark == 1){
            require(InternalIndex <= 3 && InternalIndex >= 1);
            return (StringData[InternalIndex],0,0);
        } else if(InternalBenchmark == 2){
            require(InternalIndex == 1 || InternalIndex == 2);
            return ("",NumberData[InternalIndex],0);
        } else {
            return ("",0,Documents[InternalIndex]);
        }
    }

    function proofOfID(string memory _pseudonim) public view returns (bool){
       if(keccak256(abi.encodePacked(StringData[1])) == keccak256(abi.encodePacked(_pseudonim))){
           return true;
       } else{
           return false;
       }
    }

    function checkAddresses(uint InternalIndex) public view returns (address){
        require (InternalIndex == 1 || InternalIndex == 2, "InternalIndex must be 1 or 2");
        if (InternalIndex == 1){
            return Owner;
        } else {
            return recovery;
        }
    }

    //Approval Functions

    function _checked(uint InternalIndex) public {
        SmartIDFactory SIF = SmartIDFactory(address(0));
        require(SIF.isComplianceManager(msg.sender) == true);
        require(checked[InternalIndex] == false);
        require(InternalIndex <= 7 && InternalIndex >= 1);
        checked[InternalIndex] = true;
        uint i = 1;
        uint j;
        for(i; i <= 7; i++){
            if(checked[i] == true){
                j += 1;
            } 
        }
        if (j == 7){
            allchecked = true;
        }
    }

    //Change SmartID Ownership

    function changeOwnership(address newaccount, uint InternalIndex) public{ //checked
        require (msg.sender == Owner || msg.sender == recovery);
        require (InternalIndex == 1 || InternalIndex == 2);
        if(Confirmation[Owner][InternalIndex] == false && Confirmation[recovery][InternalIndex] == false){
            candidate[InternalIndex] = newaccount;
        }
        if(Confirmation[msg.sender][InternalIndex] == false){
            require(newaccount == candidate[InternalIndex], "Select the correct Candidate");
            Confirmation[msg.sender][InternalIndex] = true;
        }
        if(Confirmation[Owner][InternalIndex] == true && Confirmation[recovery][InternalIndex] == true){
            Confirmation[Owner][InternalIndex] = false;
            Confirmation[recovery][InternalIndex] = false;
            candidate[InternalIndex] = address(0);
            InternalIndex == 1 ? Owner = newaccount : recovery = newaccount;
            SmartIDCheck Check = SmartIDCheck(address(0));
            if (InternalIndex == 1){
            Check.ChangeSID(address(this), newaccount);
            }
        }
    }

    function setBackUp(address _ForcedAddress) public OnlyOwner{
        require(block.timestamp > timeBackUp + 90 days);
        SmartIDCheck Check = SmartIDCheck(address(0));
        require(Check.SIDstatus(_ForcedAddress) == true);
        SmartID SIDx = SmartID(_ForcedAddress);
        ForcedAddress[1] = SIDx.checkAddresses(1);
        ForcedAddress[2] = SIDx.checkAddresses(2);
        timeBackUp = block.timestamp;
    }

    function renewTimeBackUp() public OnlyOwner{
        timeBackUp = block.timestamp;
    }

    function forcedChange() public{
        require(msg.sender == SA.checkAddress(0,1));
        SmartIDCheck Check = SmartIDCheck(address(0));
        Owner = ForcedAddress[1];
        Check.ChangeSID(address(this), ForcedAddress[1]);
        recovery = ForcedAddress[2];
    }

    //Financial Functions

    function WhitelistActivate(bool status) public OnlyRecovery{ //checked
        require (status != whitelistActivate);
        whitelistActivate = status;
    }

    function _isWhitelistActivate() public view returns (bool){ //checked
        return whitelistActivate;
    }

    function AddToWhitelist(address target, bool status) public OnlyRecovery{ //checked
        require (status != Whitelist[target]);
        Whitelist[target] = status;
    }

    function _isWhitelisted(address target) public view returns (bool){ //checked
        return Whitelist[target];
    }

    function _FreezeTransfer(address target, bool status) public OnlyRecovery{ //checked
        FreezeTransfer[target] = status;
    }

    function _isFrozen(address target) public view returns (bool){ //checked
        return FreezeTransfer[target];
    }

    function _Vacation(bool status) public OnlyRecovery{ //checked
        require (status != Vacation);
        if (status == true){
            Vacation = status;
            VacationTime = block.timestamp;
        } else {
            require(block.timestamp > VacationTime + 30 days);
            Vacation = status;
        }
    }

    function _isVacation() public view returns (bool){ //checked
        return Vacation;
    }

    //Marketing Functions 

    function Marketed(address account) public OnlyOwner{ //checked
        _referral = account;
    }

    function _isClient() public view returns(address){ //checked
        return _referral;
    }

    //Civil Law Compliance

    function protect(address address1, address address2) public OnlyRecovery{ //checked
        Time = block.timestamp + 365 days;
        Protector[1] = address1;
        Protector[2] = address2;
    }

    function renewTime() public OnlyRecovery{
        Time = block.timestamp + 365 days;
    }

    function ProtectionTime() public view returns(uint){
        return Time;
    }

    function _isProtector(uint InternalIndex) public view returns(address){
        return Protector[InternalIndex];
    }

}