// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./deps/npm/@openzeppelin/contracts@4.8.2/token/ERC20/ERC20.sol";
import "./deps/npm/@openzeppelin/contracts@4.8.2/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./deps/npm/@openzeppelin/contracts@4.8.2/token/ERC20/extensions/ERC20Votes.sol";
import "./deps/npm/@openzeppelin/contracts@4.8.2/token/ERC20/extensions/ERC20Snapshot.sol";

contract PetroDescentralizado is ERC20, ERC20Permit, ERC20Votes, ERC20Snapshot{
    
    mapping(uint => uint) augmented;
    mapping(address => uint) indexmining;
    
    constructor()
        ERC20("Petro Descentralizado", "PTD")
        ERC20Permit("Petro Descentralizado")
    {
        _mint(msg.sender, 20000000 * 10 ** decimals());
        _issuance(80000000 * 10 ** decimals());
    }

    function PTDDistribution() public returns (bool){
        require(Timeissue + _seconds < block.timestamp, "Its not time yet");
        Timeissue = block.timestamp;
        _snapshot();
        uint previoustaxbalance = _taxbalance;
        _taxbalance = 0;
        augmented[_getCurrentSnapshotId()] = previoustaxbalance;
        return true;
    }

    function PTDMining() public returns (uint){
        address owner = _msgSender();
        uint indexdifference = _getCurrentSnapshotId() - indexmining[owner];
        uint amount;
        require(indexdifference > 0);
        uint i;
        if(owner != Promoters){
            for(i = indexmining[owner] + 1 ; i <= indexmining[owner] + indexdifference; i++){
                if (i <= 1000){
                    indexmining[owner] += 1;
                    uint percentage = balanceOfAt(owner, indexmining[owner]) / totalSupplyAt(indexmining[owner]);
                    amount += augmented[indexmining[owner]] * percentage;
                    if(indexmining[owner] == _getCurrentSnapshotId()){
                        _transfer(address(0), owner, amount, 1);
                        break;
                    } 
                } else {
                        _transfer(address(0), owner, amount, 1);
                }
            }
        }
        return (amount);
    }

    function MyPendingDistribution(address target) public view returns (uint){
        require(_getCurrentSnapshotId() - indexmining[target] <= 100, "You have to many pending distributions");
        uint indexdifference = _getCurrentSnapshotId() - indexmining[target];
        uint amount;
        require(indexdifference > 0);
        uint i;
        for(i = indexmining[target] + 1 ; i <= indexmining[target] + indexdifference; i++){
            amount += augmented[i] * (balanceOfAt(target, i) / totalSupplyAt(i));
        }
        return (amount);
    }

    function getindexmining(address target) public view returns (uint){
        return indexmining[target];
    } 

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
