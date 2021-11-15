// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBEP20.sol";
import "./interfaces/IBEP20Metadata.sol";
import "./abstracts/Context.sol";
import "./abstracts/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract Bricks is Context, IBEP20, IBEP20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isIncluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "BRICKS";
    string private constant _symbol = "BRICKS";
    uint8 private constant _decimals = 9;


    uint256 public taxFeeDev = 2;
    uint256 private previousDevTaxFee = taxFeeDev;
    uint256 public taxFeeTeam = 2;
    uint256 private previousTeamTaxFee = taxFeeTeam;
    uint public walletType;
    address public teamWallet;
    address public devWallet;
    
    uint256 public taxFee = 2;
    uint256 private previousTaxFee = taxFee;

    bool public enableFee;

    bool public enableAntiwale;
 
    uint256 private _amount_burnt;

    event FeeEnable(bool enableFee);
    event SetMaxTxPercent(uint256 maxPercent);
    event SetTaxFeePercent(uint256 taxFeePercent);
    event ExternalTokenTransfered(address externalAddress,address toAddress, uint amount);
    event enableAntiWale(bool enableAntiwale);

    constructor (address wallet1, address wallet2) {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);  
         teamWallet = wallet1;
         devWallet = wallet2;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _tTotal - _amount_burnt;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already included");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    
    function setTaxFeePercent(uint256 fee) external onlyOwner {
        taxFee = fee;
        emit SetTaxFeePercent(taxFee);
    }

    function setEnableFee(bool enableTax) external onlyOwner {
        enableFee = enableTax;
        emit FeeEnable(enableTax);
    }

     function setAntiwale(bool enableWale) external onlyOwner {
        enableAntiwale = enableWale;
        emit enableAntiWale(enableWale);
    }

    function takeReflectionFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function getTValues(uint256 amount) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 tAmount = amount;
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tFeeDev = calculateDevTaxFee(tAmount);
        uint256 tFeeTeam = calculateTeamTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFeeDev).sub(tFeeTeam);
        return (tTransferAmount, tFee, tFeeDev, tFeeTeam);
    }

    function getRValues(uint256 amount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate = getRate();
        uint256 tAmount = amount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFeeDev = tFeeDev.mul(currentRate);
        uint256 rFeeTeam = tFeeTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFeeDev).sub(rFeeTeam);
        return (rAmount, rTransferAmount, rFee, rFeeDev, rFeeTeam);
    }

    function getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function calculateTaxFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(taxFee).div(
            10**2
        );
    }

     function calculateDevTaxFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(taxFeeDev).div(
            10**2
        );
    }

    function calculateTeamTaxFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(taxFeeTeam).div(
            10**2
        );
    }
    
     /**
       remove tax fee and set it to previous tax fee
     */
    function removeAllFee() internal {
        if(taxFee == 0) return;
        
        previousTaxFee = taxFee;
        
        taxFee = 0;
    }

     /**
       remove dev fee and set it to previous dev tax fee
     */
    function removeDevFee() internal {
         if(taxFeeDev == 0) return;
        
        previousDevTaxFee = taxFeeDev;
        
        taxFeeDev = 0;
    }

    /**
       remove team fee and set it to previous team tax fee
     */
    function removeTeamFee() internal {
       if(taxFeeTeam == 0) return;
        
        previousTeamTaxFee = taxFeeTeam;
        
        taxFeeTeam = 0;
    }

    /**
        restore all fee (i.e) taxfee,devfee,teamfee
     */
    function restoreAllFee() internal {
        taxFee = previousTaxFee;
        taxFeeDev = previousDevTaxFee;
        taxFeeTeam = previousTeamTaxFee;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
         if(enableAntiwale){
             require(amount < 20000000 , "Transfer amount should not be greater than 20000000");
         }
        
        _beforeTokenTransfer(from, to);
        
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isIncludedInFee account then take fee
        //else remove fee
        if(!enableFee){
            takeFee = false;
        }
         
         //transfer amount, it will take tax, burn and charity amount
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee){
            removeAllFee();
            removeDevFee();
            removeTeamFee();
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }
  
    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeReflectionFee(rFee, tFee);
        takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        takeReflectionFee(rFee, tFee);
         takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        takeReflectionFee(rFee, tFee);
         takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
         (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        takeReflectionFee(rFee, tFee);
         takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
        IBEP20 tokenContract = IBEP20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit ExternalTokenTransfered(_tokenContract, msg.sender, _amount);
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to) internal virtual { 
    }

    /**
       update dev wallet as per redistribution status
     */
    function takeFeeDev(uint256 tFeeDev) internal {
        if(walletType == 1){
            _rOwned[devWallet] = _rOwned[devWallet].add(tFeeDev); 
        }else{
            _tOwned[devWallet] = _tOwned[devWallet].add(tFeeDev);
            _rOwned[devWallet] = _rOwned[devWallet].add(tFeeDev); 
        }
        
    }

    /**
       update team wallet as per redistribution status
     */
    function takeFeeTeam(uint256 tFeeTeam) internal {

        if(walletType == 1){
            _rOwned[teamWallet] = _rOwned[teamWallet].add(tFeeTeam); 
        }else{
            _tOwned[teamWallet] = _tOwned[teamWallet].add(tFeeTeam);
            _rOwned[teamWallet] = _rOwned[teamWallet].add(tFeeTeam); 
        }
    }

    /**
       Take dev fee and team fee if dev and team address participate in redistribution
       update balance in _rOwned orelse update in _tOwned
     */
    function takeFeeDevTeam(uint256 tFeeDev,uint256 rFeeDev,uint256 tFeeTeam,uint256 rFeeTeam) internal {

        // Update in DevWallet
        if(!_isExcluded[devWallet]){
            // wallet present in re-distribution update in rOwned
             walletType = 1;
             takeFeeDev(rFeeDev);
        }else{
            // update in tOwned
            walletType = 2;
            takeFeeDev(tFeeDev);
            // update in rOwned
            walletType = 1;
            takeFeeDev(rFeeDev);
        }
         // Update in TeamWallet
        if(!_isExcluded[teamWallet]){
            walletType = 1;
            takeFeeTeam(rFeeTeam);
        }else{
            walletType = 2;
            takeFeeTeam(tFeeTeam);
            walletType = 1;
            takeFeeTeam(rFeeTeam);
        }

    }

}