// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../BridgeContracts/SmartAddress.sol";

contract SmartIDCheck{

    address SAddress;

    mapping(address => address) SIDs;
    mapping(address => address) sDIS;
    mapping(address => bool) _SIDsStatus;
    mapping(address => bool) _Authorized;

    constructor(address target){
        SAddress = target;
    }

    modifier Auth(){
        require(_Authorized[msg.sender] = true, "You are not authorized");
        _;
    }

    function isAuthorized (address target, bool status) public {
        SmartAddress SA = SmartAddress(SAddress);
        require(msg.sender == SA.checkAddress(0,1), "You are not the DAO Address");
        require(_Authorized[target] != status, "status must differ from current state");
        _Authorized[target] = status;
    }
    
    function setSIDs(address owner, address target) public Auth{
        SIDs[owner] = target;
    }

    function setSDIS(address target, address owner) public Auth{
        sDIS[target] = owner;
    }

    function setSIDsStatus(address target) public Auth{
        _SIDsStatus[target] = true;
    }
    
    function _isSID(address target) public view returns(bool){
        if(SIDs[target] != address(0)){
            return true;
        } else {
            return false;
        }
    }

    function SIDaddress(address target) public view returns(address){
        return SIDs[target];
    }

    function SIDstatus(address target) public view returns(bool){
        return _SIDsStatus[target];
    }

    function ChangeSID(address _SMID, address Owner) public {
        require(msg.sender == _SMID);
        SIDs[sDIS[_SMID]] = address(0);
        SIDs[Owner] = _SMID;
        sDIS[_SMID] = Owner;
    }
}

