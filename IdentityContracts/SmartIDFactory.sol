// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./SmartIDPN.sol";
import "./SmartChecks.sol";
import "../BridgeContracts/SmartAddress.sol";

contract SmartIDFactory{

    mapping(bytes32 => bool) repeateable;
    mapping(address => bool) compliancemanager;

    address _SAddress;

    constructor(address SAddress){
        _SAddress = SAddress;
    }

    function createSmartIDPN(string memory _pseudonim, string memory _birthplace, uint _birthday, string memory _occupation, uint _experience, address _recovery) public{
        SmartAddress SA = SmartAddress(_SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        require(repeateable[keccak256(abi.encodePacked(_pseudonim))] == false, "Existing Pseudonim, please choose another one");
        require(Check.SIDaddress(msg.sender) == address(0));
        SmartID SID = new SmartID(_pseudonim, _birthplace, _birthday, _occupation, _experience, _recovery);
        Check.setSIDs(msg.sender, address(SID));
        Check.setSDIS(address(SID),msg.sender);
        Check.setSIDsStatus(address(SID));
        repeateable[keccak256(abi.encodePacked(_pseudonim))] == true;
    }

    function ComplianceManager(address target, bool status) public{
        SmartAddress SA = SmartAddress(_SAddress);
        require(msg.sender == SA.checkAddress(0,1));
        compliancemanager[target] = status;
    }

    function isComplianceManager(address target) public view returns(bool){
        return compliancemanager[target];
    }
}

