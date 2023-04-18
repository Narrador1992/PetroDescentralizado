// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "../../../../../../TaxContracts/PetroTaxes.sol";
import "../../../../../../IdentityContracts/SmartIDPN.sol";
import "../../../../../../BridgeContracts/SmartAddress.sol";
import "../../../../../../IdentityContracts/SmartChecks.sol";
import "../../../../../../IdentityContracts/TokenChecks.sol";
import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";


contract ERC20 is Context, IERC20, IERC20Metadata{

    string public _name;
    string public _symbol;

    uint _totalSupply;
    uint benchmark = 0;
    uint Timeissue;
    uint _seconds = 600;
    uint _taxbalance;
    uint _issuancebalance;

    address SAddress;
    address Promoters;

    mapping (address => uint) private _balances;
    mapping (address => mapping(address => uint)) private _allowances;
    mapping (address => uint) locked;
    mapping (address => uint) locktime;

    constructor (string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        Timeissue = block.timestamp;
    }

    function setAddress(address target, address _target) public{
        require(SAddress == address(0));
        SAddress = target;
        Promoters = _target;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function Donate(uint amount) public{
        SmartAddress SA = SmartAddress(SAddress);
        TokenIDChecks TC = TokenIDChecks(SA.checkAddress(4,1));
        require(amount <=_balances[msg.sender]);
        require(TC._isChecked(msg.sender, address(this), address(this), SAddress) == true, "Your SmartID does not permit the transfer");
        _balances[msg.sender] -= amount;
        _taxbalance += amount;
        _balances[address(0)] += amount;
    }

    function totalSupply() public view virtual override returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256){
        return _balances[account];
    }
    
    function lockup(uint amount, uint t) public override returns (bool){
        require(amount <= _balances[msg.sender] - locked[msg.sender]);
        locktime[msg.sender] = t;
        locked[msg.sender] = amount;
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _issuance(uint amount) internal virtual {
        unchecked {
            _issuancebalance += amount;
        }       
    }

    function sendToBuyer(address target, uint amount) public {
        require(amount <= _issuancebalance);
        SmartAddress SA = SmartAddress(SAddress);
        require(msg.sender == SA.checkAddress(0,1));
        _issuancebalance -= amount;
        _mint(target, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount, 1);
        return true;
    }

    function transferR(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount, 2);
        return true;
    }

    function safeTransfer(address to, string memory _pseudonim, uint amount, uint modality)public override returns (bool){
        require(modality == 1 || modality == 2, "Please choose between 1 or 2 mode");
        address owner = _msgSender();
        SmartAddress SA = SmartAddress(SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        require(Check._isSID(to) == true);
        SmartID SMART = SmartID(Check.SIDaddress(msg.sender));
        require (SMART.proofOfID(_pseudonim) == true);
        _transfer(owner, to, amount, modality);
        return true;
    }

    function _transfer(address from, address to, uint256 amount, uint256 modality) internal virtual{ 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[from] - locked[from]);
        SmartAddress SA = SmartAddress(SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        Taxes taxes = Taxes(SA.checkAddress(1,1));
        TokenIDChecks TC = TokenIDChecks(SA.checkAddress(4,1));
        bool _marketed = false;
        if (Check._isSID(from) == true){
           require(TC._isChecked(from, address(this), to, SAddress) == true, "Your SmartID does not permit the transfer");
           _marketed = TC._isCheckedClient(from, SAddress);
        }
        uint taxation = taxes.setTax(benchmark, amount);
        if(modality == 1){
            if(taxes.exemption(from,benchmark) == true){
            taxation = 0;
            }
        } else{
            if(taxes.exemption(to,benchmark) == true){
            require(modality == 1, "TransferR is not available for this transaction. Please use the transfer function");
            }
        }
        balanceexpenditure(amount, taxation, modality, from, to);
        if(taxation != 0){
        taxexpenditure(taxation, _marketed, from);
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");       
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount, 1);
        return true;
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual{
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    } 

    function Protection(address target) public {
        SmartAddress SA = SmartAddress(SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        require(Check._isSID(target) == true);
        SmartID SMART = SmartID(Check.SIDaddress(target));
        require(SMART._isProtector(1) == msg.sender || SMART._isProtector(2) == msg.sender || SA.checkAddress(0,1) == msg.sender, "You are not allowed");
        uint previousbalance = _balances[target];
        if(SMART._isProtector(1) == msg.sender){
            require(block.timestamp > SMART.ProtectionTime(), "Not enough time has passed");
            balanceexpenditure(previousbalance, 0, 3, target, msg.sender);
        } else if(SMART._isProtector(2) == msg.sender){
            require(block.timestamp > SMART.ProtectionTime() + 180 days, "Not enough time has passed");
            balanceexpenditure(previousbalance, 0, 3, target, msg.sender);
        } else{
            require(block.timestamp > SMART.ProtectionTime() + 365 days);
            balanceexpenditure(previousbalance, 0, 3, target, msg.sender);
        }     
    }

     function balanceexpenditure(uint amount, uint taxing, uint InternalIndex, address from, address to) private {
        if(InternalIndex == 1){
            require(amount + taxing <= _balances[from], "You dont have enough balance to cover the transfer and the tax");
            _beforeTokenTransfer(from, to, amount);            
            _balances[from] -= amount + taxing;
            _balances[to] += amount;
            emit Transfer(from,to,amount);
            _afterTokenTransfer(from, to, amount);
        } else if(InternalIndex == 2){
            require(amount <= _balances[from], "You dont have enough balance");
            _beforeTokenTransfer(from, to, amount);
            _balances[from] -= amount;
            _balances[to] += amount - taxing;
            emit Transfer(from, to, amount - taxing);
            _afterTokenTransfer(from, to, amount - taxing);
        } else {
            _beforeTokenTransfer(from, to, amount);
            _balances[from] = 0;           
            _balances[to] += amount;
            _afterTokenTransfer(from, to, amount);
            emit Transfer(from, to, amount);
        }
    }

    function taxexpenditure(uint taxation, bool _marketed, address from) private{
        SmartAddress SA = SmartAddress(SAddress);
        SmartIDCheck Check = SmartIDCheck(SA.checkAddress(3,1));
        uint units = taxation / 16;
        uint unitremainder = taxation - (16 * units);
        if(_marketed == true){
            SmartID SMART = SmartID(Check.SIDaddress(from));
            _balances[SMART._isClient()] += 4 * units;
            _balances[SA.checkAddress(0,1)] += 3 * units + unitremainder;
            _balances[address(0)] += 9 * units;
            _taxbalance += 9 * units;
            _afterTokenTransfer(from, SMART._isClient(), 4 * units);
            _afterTokenTransfer(from, SA.checkAddress(0,1), 4 * units + unitremainder);
            _afterTokenTransfer(SA.checkAddress(0,1), address(0), units);
            _afterTokenTransfer(from, address(0), 8 * units);
            emit Transfer(from, SMART._isClient(), 4 * units);
            emit Transfer(from, SA.checkAddress(0,1), 4 * units + unitremainder);
            emit Transfer(SA.checkAddress(0,1), address(0), units);
            emit Transfer(from, address(0), 8 * units);
        } else{
            _balances[SA.checkAddress(0,1)] += (6 * units) + unitremainder;
            _balances[address(0)] += 10 * units;
            _taxbalance += 10 * units;
            _afterTokenTransfer(from, SA.checkAddress(0,1), (8 * units) + unitremainder);
            _afterTokenTransfer(SA.checkAddress(0,1), address(0), 2* units);
            _afterTokenTransfer(from, address(0), 8 * units);
            emit Transfer(from, SA.checkAddress(0,1), (8 * units) + unitremainder);
            emit Transfer(SA.checkAddress(0,1), address(0), 2* units);
            emit Transfer(from, address(0), 8 * units);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

