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

 interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


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

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    uint256 public taxFeeDev = 2;
    uint256 private previousDevTaxFee = taxFeeDev;

    uint256 public taxFeeTeam = 2;
    uint256 private previousTeamTaxFee = taxFeeTeam;

    uint public walletType;
    address public teamWallet;
    address public devWallet;

    uint256 public liquidityFee = 2;
    uint256 private previousLiquidityFee = liquidityFee;
    
    uint256 public taxFee = 2;
    uint256 private previousTaxFee = taxFee;

    uint256 public maxContractWalletAmount = 1000 * 10 ** 9;

    bool public enableFee;

    bool public enableAntiwale;

    bool public taxDisableInLiquidity;
 
    uint256 private _amount_burnt;

    event FeeEnable(bool enableFee);
    event SetMaxTxPercent(uint256 maxPercent);
    event SetTaxFeePercent(uint256 taxFeePercent);
    event ExternalTokenTransfered(address externalAddress,address toAddress, uint amount);
    event enableAntiWale(bool enableAntiwale);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);

    constructor (address wallet1, address wallet2) {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

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

    function getTValues(uint256 amount) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tAmount = amount;
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tFeeDev = calculateDevTaxFee(tAmount);
        uint256 tFeeTeam = calculateTeamTaxFee(tAmount);
        uint256 tFeeLiquidity = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFeeDev).sub(tFeeTeam).sub(tFeeLiquidity);
        return (tTransferAmount, tFee, tFeeDev, tFeeTeam, tFeeLiquidity);
    }

    function getRValues(uint256 amount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam, uint256 tFeeLiquidity) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate = getRate();
        uint256 tAmount = amount;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFeeDev = tFeeDev.mul(currentRate);
        uint256 rFeeTeam = tFeeTeam.mul(currentRate);
        uint256 rFeeLiquidity = tFeeLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFeeDev).sub(rFeeTeam).sub(rFeeLiquidity);
        return (rAmount, rTransferAmount, rFee, rFeeDev, rFeeTeam, rFeeLiquidity);
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
       remove tax fee,dev tax fee,team tax fee & liquidity fee and set it to previous tax fee's
     */
    function removeAllFee() internal {
        if((taxFee == 0) && (taxFeeDev == 0) && (taxFeeTeam == 0) && (liquidityFee == 0)) return;
        
        previousTaxFee = taxFee;
        taxFee = 0;

        previousDevTaxFee = taxFeeDev;
        taxFeeDev = 0;

        previousTeamTaxFee = taxFeeTeam;
        taxFeeTeam = 0;

        previousLiquidityFee = liquidityFee;
        liquidityFee = 0;
    }

    /**
        restore all fee (i.e) taxfee,devfee,teamfee & liquidity fee
     */
    function restoreAllFee() internal {
        taxFee = previousTaxFee;
        taxFeeDev = previousDevTaxFee;
        taxFeeTeam = previousTeamTaxFee;
        liquidityFee = previousLiquidityFee;
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
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
         if(enableAntiwale){
             require(amount < 20000000 * 10 ** 9 , "Transfer amount should not be greater than 20000000");
         }
        
        _beforeTokenTransfer(from, to);
        
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isIncludedInFee account then take fee
        //else remove fee
        if(!enableFee){
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMaxTokenBalance = contractTokenBalance >= maxContractWalletAmount;

        if(overMaxTokenBalance && from != uniswapV2Pair){
            if(enableFee){
                enableFee = false;
                taxDisableInLiquidity = true;
            }
            swapAndLiquify(contractTokenBalance, owner());
            if(taxDisableInLiquidity){
                enableFee = true;
            }
        }
         
         //transfer amount, it will take tax, burn and charity amount
        _tokenTransfer(from,to,amount,takeFee);
    }


    function swapAndLiquify(uint256 contractTokenBalance, address account) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance, account);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address account) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            account,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee){
            removeAllFee();
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
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam, uint256 tFeeLiquidity) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam, uint256 rFeeLiquidity) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam, tFeeLiquidity);
        {
            address from = sender;
            _rOwned[from] = _rOwned[from].sub(rAmount);
        }
        {
            address to = recipient;
            _rOwned[to] = _rOwned[to].add(rTransferAmount);

        }
        takeReflectionFee(rFee, tFee);
        takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        takeLiquidityFee(tFeeLiquidity,rFeeLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam, uint256 tFeeLiquidity) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam, uint256 rFeeLiquidity) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam, tFeeLiquidity);
        {
             address from = sender;
             _tOwned[from] = _tOwned[from].sub(tAmount);
             _rOwned[from] = _rOwned[from].sub(rAmount);
        }
        {
            address to = recipient;
            _tOwned[to] = _tOwned[to].add(tTransferAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);    
        }    
        takeReflectionFee(rFee, tFee);
        takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        takeLiquidityFee(tFeeLiquidity,rFeeLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam, uint256 tFeeLiquidity) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam, uint256 rFeeLiquidity) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam, tFeeLiquidity);
        {
            address from = sender;
            _rOwned[from] = _rOwned[from].sub(rAmount);
        }
        {
            address to = recipient;
            _tOwned[to] = _tOwned[to].add(tTransferAmount);
            _rOwned[to] = _rOwned[to].add(rTransferAmount);  
        }         
        takeReflectionFee(rFee, tFee);
        takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        takeLiquidityFee(tFeeLiquidity,rFeeLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
         (uint256 tTransferAmount, uint256 tFee, uint256 tFeeDev, uint256 tFeeTeam, uint256 tFeeLiquidity) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rFeeDev, uint256 rFeeTeam, uint256 rFeeLiquidity) = getRValues(tAmount, tFee, tFeeDev, tFeeTeam, tFeeLiquidity);
        {
             address from = sender;
             _tOwned[from] = _tOwned[from].sub(tAmount);
             _rOwned[from] = _rOwned[from].sub(rAmount);
        }
        {
            address to = recipient;
            _rOwned[to] = _rOwned[to].add(rTransferAmount);  
        } 
        takeReflectionFee(rFee, tFee);
        takeFeeDevTeam(tFeeDev,rFeeDev,tFeeTeam,rFeeTeam);
        takeLiquidityFee(tFeeLiquidity,rFeeLiquidity);
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
         take liquidity percent to contract address
     */
    function takeLiquidityFee(uint256 tFeeLiquidity, uint256 rFeeLiquidity) internal {

        if(!_isExcluded[address(this)]){
            _rOwned[address(this)] = _rOwned[address(this)].add(rFeeLiquidity); 
        }else{
            _tOwned[address(this)] = _tOwned[address(this)].add(tFeeLiquidity);
            _rOwned[address(this)] = _rOwned[address(this)].add(rFeeLiquidity); 
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