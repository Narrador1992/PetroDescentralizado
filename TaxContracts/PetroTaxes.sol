// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "../BridgeContracts/SmartAddress.sol";

contract Taxes{

    address SAddress;
    
    mapping (address => mapping(uint => bool)) _isExempted;
    mapping (uint256 => uint256) maxTax;
    mapping (uint256 => uint256) minTax;
    mapping (uint256 => uint256) taxrate;
    mapping (uint256 => uint256) Maxmin;
    mapping (uint256 => uint256) Minmin;
    mapping (uint256 => uint256) MaxExempted;
    mapping (uint256 => uint256) indexExempted;
    mapping (uint256 => bool) BaseOver;
    mapping (uint256 => address) rector;

    event ChangemaxTax(uint256 value);
    event Changemintax(uint256 value);
    event Exempted(address account);

    constructor(address target){
        SAddress = target;
    }

    function setTax(uint benchmarkinternal, uint numTokens) public view returns (uint256){
        uint taxation = numTokens / taxrate[benchmarkinternal];
        if (taxation < minTax[benchmarkinternal] && BaseOver[benchmarkinternal] == false){
            taxation = minTax[benchmarkinternal];
        }
        if (maxTax[benchmarkinternal] > 0 && taxation > maxTax[benchmarkinternal] && BaseOver[benchmarkinternal] == false){
            taxation = maxTax[benchmarkinternal];
        }
        return (taxation);
    }

    function setTaxVariables(uint benchmarkinternal, uint basis, bool base, uint maxmin, uint minmin, uint MaxEx, uint MT, uint mT, address governor) public{
        SmartAddress SA = SmartAddress(SAddress);
        require(msg.sender == SA.checkAddress(0,1), "You are not the DAO");
        require(taxrate[benchmarkinternal] == 0, "variables has already been set");
        taxrate[benchmarkinternal] = basis;
        BaseOver[benchmarkinternal] = base;
        Maxmin[benchmarkinternal] = maxmin;
        Minmin[benchmarkinternal] = minmin;
        MaxExempted[benchmarkinternal] = MaxEx;
        maxTax[benchmarkinternal] = MT;
        minTax[benchmarkinternal] = mT;
        rector[benchmarkinternal] = governor;
    }

    function isExempted(address account, uint benchmarkinternal, bool status) public{
        require(msg.sender == rector[benchmarkinternal], "You are not the rector");
        require(_isExempted[account][benchmarkinternal] != status, "The status you chose is equivalent to the current one");
        if(indexExempted[benchmarkinternal]==0){
            indexExempted[benchmarkinternal]+=1;
        }
        require(indexExempted[benchmarkinternal] <= MaxExempted[benchmarkinternal] || status == false, "You have reached the maximum exempted accounts");
        status == true ? indexExempted[benchmarkinternal] += 1 : indexExempted[benchmarkinternal] -= 1;
        _isExempted[account][benchmarkinternal] = status;
        emit Exempted(account);
    }

    function exemption(address account, uint benchmarkinternal) public view returns(bool){
        return _isExempted[account][benchmarkinternal];
    }

    function changeTax(uint benchmarkinternal, uint amount, uint variant) public{
        require(msg.sender == rector[benchmarkinternal], "You are not the rector");
        require (variant == 1 || variant == 2, "set variant to 1 or 2");
        require (BaseOver[benchmarkinternal] != true, "This token has immutable tax features");
        if(variant == 1){
            require (amount > minTax[benchmarkinternal] || amount == 0, "Maximum Tax must be higher than Minimum Tax or set to zero");
            maxTax[benchmarkinternal] = amount; 
            emit ChangemaxTax(maxTax[benchmarkinternal]);
        } else {
            require (amount < maxTax[benchmarkinternal] || maxTax[benchmarkinternal] == 0, "Minimum Tax must be smaller than Maximum Tax");
            require (amount >= Minmin[benchmarkinternal], "Minimum Tax cant be lower than the Absolute Minimum");
            require (amount <= Maxmin[benchmarkinternal], "Minimum Tax cant exceed 1 CUNA for security purposes");
            minTax[benchmarkinternal] = amount;
            emit Changemintax(minTax[benchmarkinternal]);
        } 
    }
}