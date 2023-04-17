// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract SmartAddress{

    address DAO;
    mapping(uint => address) SACC;
    mapping(uint => address) SACT;
    mapping(uint => mapping(uint => bool)) _immutable;

    event smartaddress(uint IndexInternal, uint modality, address target);

    constructor(address target){
        DAO = target;
    }

    function setSmartAddress(uint IndexInternal, address target, uint modality) public{
        require(_immutable[IndexInternal][modality] == false, "Address is Immutable");
        require(msg.sender == DAO, "You are not the DAO");
        require(modality == 1 || modality == 2);
        if(modality == 1){
            SACC[IndexInternal] = target;
        }else{
            SACT[IndexInternal] = target;
        }
        emit smartaddress(IndexInternal, modality, target);
    }

    function _setImmutable(uint IndexInternal, uint modality) public{
        require(msg.sender == DAO, "You are not the DAO");
        require(_immutable[IndexInternal][modality] == false, "Address already Immutable");
        _immutable[IndexInternal][modality] = true;
    }

    function checkAddress(uint IndexInternal, uint modality) public view returns(address){
        require(modality == 1 || modality == 2, "Please choose between 1 or 2");
        if(modality ==1){
            return SACC[IndexInternal];
        } else{
            return SACT[IndexInternal];
        }
    }
}

