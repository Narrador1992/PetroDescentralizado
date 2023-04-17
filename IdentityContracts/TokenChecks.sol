// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./SmartIDPN.sol";
import "../BridgeContracts/SmartAddress.sol";
import "./SmartChecks.sol";

contract TokenIDChecks{

    function _isChecked (address target, address caller, address to, address _SAddress) public view returns(bool){
        SmartAddress SA = SmartAddress(_SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        SmartID SMART = SmartID(Check.SIDaddress(target));
        if (SMART._isVacation() == true || SMART._isFrozen(caller) == true){
            return false;
        } else if (SMART._isWhitelistActivate() == true && SMART._isWhitelisted(to) == false) {
            return false;
        } else {
            return true;
        }
    }

    function _isCheckedClient(address target, address _SAddress) public view returns (bool){
        SmartAddress SA = SmartAddress(_SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        SmartID SMART = SmartID(Check.SIDaddress(target));
        if(SMART._isClient() != address(0)){
            return true;
        } else {
            return false;
        }
    }
}