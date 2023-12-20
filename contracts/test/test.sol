// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import '../access/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract TREE is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _tTotalMaxDestroy;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    address private _owner;
    uint8 private _decimals;

    

    uint256 public _destroyFee = 35;
    address private _destroyAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public _inviterFee = 85;
    address public inviterAddress = 0x8B12e98c4698C333a75d802b219A80F2432B7a85;
    mapping(address => address) public inviter;
    mapping(address => uint256) public lastSellTime;

    address public uniswapV2Pair;
    
    address public receiveReward1Token = 0xe21E8641C8c74440556D905D01de4156595199a9;
    uint256 public minimumTokenBalanceForDividends;

    address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955;
    address public routerAddress = 0x3183384179BbA62BEEd7e699916073e633eF37B9;

    constructor(address initialOwner) payable Ownable(initialOwner){
        _name = "molatree";
        _symbol = "TREE";
        _decimals = 3;
        address tokenOwner = initialOwner;
        _tTotal = 16000000 * 10**_decimals;
        uint256 leftAmount = 1600000 * 10**_decimals;
        _tTotalMaxDestroy = _tTotal.sub(leftAmount);
        _rTotal = (MAX - (MAX % _tTotal));
        minimumTokenBalanceForDividends = 100*10**_decimals;
        _rOwned[tokenOwner] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), usdtAddress);
        _owner = msg.sender;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        uint256 _destroyAmount = balanceOf(_destroyAddress);
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || _destroyAmount >= _tTotalMaxDestroy) {
            takeFee = false;
        }

        if(to == uniswapV2Pair && _isLiquidity()){
              takeFee = false;
        }

       
        bool shouldSetInviter = balanceOf(to) == 0 &&
            inviter[to] == address(0) &&
            from != uniswapV2Pair;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        if (shouldSetInviter) {
            inviter[to] = from;
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 rate;
        if (takeFee) {
            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.div(1000).mul(_destroyFee),
                currentRate
            );
            _takeInviterFee(sender, recipient, tAmount, currentRate);
            
            rate = _destroyFee + _inviterFee;
        }
        uint256 recipientRate = 1000 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(1000).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(1000).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        address cur;
        
        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }
        for (int256 i = 0; i < 15; i++) {
            uint256 rate;
            if(i <= 1) {
                rate = 10;
            } else {
                rate = 5;
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                uint256 curTAmount = tAmount.div(1000).mul(rate);
                uint256 curRAmount = curTAmount.mul(currentRate);
                _rOwned[receiveReward1Token] = _rOwned[receiveReward1Token].add(curRAmount);
                
                emit Transfer(sender, receiveReward1Token, curTAmount);
                
            }else{
                uint256 curTAmount = tAmount.div(1000).mul(rate);
                uint256 curRAmount = curTAmount.mul(currentRate);
                uint256 addressCount = balanceOf(cur);
                if(addressCount>=minimumTokenBalanceForDividends){
                    _rOwned[cur] = _rOwned[cur].add(curRAmount);
                    emit Transfer(sender, cur, curTAmount);
                }else{
                    _rOwned[receiveReward1Token] = _rOwned[receiveReward1Token].add(curRAmount);
                    emit Transfer(sender, receiveReward1Token, curTAmount);
                }
            }
            
        }
    }

    

    function _isLiquidity()internal view returns(bool){
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0,uint r1,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        if(token0 == address(usdtAddress)){
            if(  bal0 > r0 ){
                return true;
        }
        }
        if(token1 == address(usdtAddress)){
            if(  bal1 > r1 ){
                
                return true;
        }
    }
        
        return false;
    }
}