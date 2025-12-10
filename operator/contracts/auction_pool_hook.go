// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contracts

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// AuctionPoolHookBid is an auto generated low-level Go binding around an user-defined struct.
type AuctionPoolHookBid struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}

// HooksPermissions is an auto generated low-level Go binding around an user-defined struct.
type HooksPermissions struct {
	BeforeInitialize                bool
	AfterInitialize                 bool
	BeforeAddLiquidity              bool
	AfterAddLiquidity               bool
	BeforeRemoveLiquidity           bool
	AfterRemoveLiquidity            bool
	BeforeSwap                      bool
	AfterSwap                       bool
	BeforeDonate                    bool
	AfterDonate                     bool
	BeforeSwapReturnDelta           bool
	AfterSwapReturnDelta            bool
	AfterAddLiquidityReturnDelta    bool
	AfterRemoveLiquidityReturnDelta bool
}

// ModifyLiquidityParams is an auto generated low-level Go binding around an user-defined struct.
type ModifyLiquidityParams struct {
	TickLower      *big.Int
	TickUpper      *big.Int
	LiquidityDelta *big.Int
	Salt           [32]byte
}

// PoolKey is an auto generated low-level Go binding around an user-defined struct.
type PoolKey struct {
	Currency0   common.Address
	Currency1   common.Address
	Fee         *big.Int
	TickSpacing *big.Int
	Hooks       common.Address
}

// SwapParams is an auto generated low-level Go binding around an user-defined struct.
type SwapParams struct {
	ZeroForOne        bool
	AmountSpecified   *big.Int
	SqrtPriceLimitX96 *big.Int
}

// AuctionPoolHookMetaData contains all meta data concerning the AuctionPoolHook contract.
var AuctionPoolHookMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_poolManager\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"ACTIVATION_DELAY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_FEE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint24\",\"internalType\":\"uint24\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MIN_BID_INCREMENT\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MIN_DEPOSIT_BLOCKS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"WITHDRAWAL_FEE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint24\",\"internalType\":\"uint24\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"afterAddLiquidity\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structModifyLiquidityParams\",\"components\":[{\"name\":\"tickLower\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"tickUpper\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"liquidityDelta\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"delta\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"},{\"name\":\"feesAccrued\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"afterDonate\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"amount0\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount1\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"afterInitialize\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"sqrtPriceX96\",\"type\":\"uint160\",\"internalType\":\"uint160\"},{\"name\":\"tick\",\"type\":\"int24\",\"internalType\":\"int24\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"afterRemoveLiquidity\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structModifyLiquidityParams\",\"components\":[{\"name\":\"tickLower\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"tickUpper\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"liquidityDelta\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"delta\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"},{\"name\":\"feesAccrued\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"afterSwap\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structSwapParams\",\"components\":[{\"name\":\"zeroForOne\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"amountSpecified\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"sqrtPriceLimitX96\",\"type\":\"uint160\",\"internalType\":\"uint160\"}]},{\"name\":\"delta\",\"type\":\"int256\",\"internalType\":\"BalanceDelta\"},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"\",\"type\":\"int128\",\"internalType\":\"int128\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beforeAddLiquidity\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structModifyLiquidityParams\",\"components\":[{\"name\":\"tickLower\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"tickUpper\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"liquidityDelta\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beforeDonate\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"amount0\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount1\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beforeInitialize\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"sqrtPriceX96\",\"type\":\"uint160\",\"internalType\":\"uint160\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beforeRemoveLiquidity\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structModifyLiquidityParams\",\"components\":[{\"name\":\"tickLower\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"tickUpper\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"liquidityDelta\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"beforeSwap\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"params\",\"type\":\"tuple\",\"internalType\":\"structSwapParams\",\"components\":[{\"name\":\"zeroForOne\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"amountSpecified\",\"type\":\"int256\",\"internalType\":\"int256\"},{\"name\":\"sqrtPriceLimitX96\",\"type\":\"uint160\",\"internalType\":\"uint160\"}]},{\"name\":\"hookData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"\",\"type\":\"int256\",\"internalType\":\"BeforeSwapDelta\"},{\"name\":\"\",\"type\":\"uint24\",\"internalType\":\"uint24\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"bidHistory\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"bidder\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"activationBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"claimRent\",\"inputs\":[{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getBidHistory\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple[]\",\"internalType\":\"structAuctionPoolHook.Bid[]\",\"components\":[{\"name\":\"bidder\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"activationBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getHookPermissions\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structHooks.Permissions\",\"components\":[{\"name\":\"beforeInitialize\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterInitialize\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"beforeAddLiquidity\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterAddLiquidity\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"beforeRemoveLiquidity\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterRemoveLiquidity\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"beforeSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"beforeDonate\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterDonate\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"beforeSwapReturnDelta\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterSwapReturnDelta\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterAddLiquidityReturnDelta\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"afterRemoveLiquidityReturnDelta\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getPendingRent\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"},{\"name\":\"lp\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSwapFee\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"},{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"swapFee\",\"type\":\"uint24\",\"internalType\":\"uint24\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lpShares\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"managerFees\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"nextBid\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"bidder\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"deposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"activationBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"poolAuctions\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"currentManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"managerDeposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"lastRentBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"currentFee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"totalRentPaid\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"poolManager\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIPoolManager\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rentPerShareAccumulated\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"rentPerShareClaimed\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setSwapFee\",\"inputs\":[{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"newFee\",\"type\":\"uint24\",\"internalType\":\"uint24\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"submitBid\",\"inputs\":[{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"totalShares\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"PoolId\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawManagerFees\",\"inputs\":[{\"name\":\"key\",\"type\":\"tuple\",\"internalType\":\"structPoolKey\",\"components\":[{\"name\":\"currency0\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"currency1\",\"type\":\"address\",\"internalType\":\"Currency\"},{\"name\":\"fee\",\"type\":\"uint24\",\"internalType\":\"uint24\"},{\"name\":\"tickSpacing\",\"type\":\"int24\",\"internalType\":\"int24\"},{\"name\":\"hooks\",\"type\":\"address\",\"internalType\":\"contractIHooks\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"BidSubmitted\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"bidder\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"deposit\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeUpdated\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newFee\",\"type\":\"uint24\",\"indexed\":false,\"internalType\":\"uint24\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityUpdated\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"lp\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"isAddition\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagerChanged\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"oldManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"rentPerBlock\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ManagerFeesWithdrawn\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"manager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RentClaimed\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"lp\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RentCollected\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"blockNumber\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"WithdrawalFeeCharged\",\"inputs\":[{\"name\":\"poolId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"PoolId\"},{\"name\":\"lp\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"HookNotImplemented\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotPoolManager\",\"inputs\":[]}]",
}

// AuctionPoolHookABI is the input ABI used to generate the binding from.
// Deprecated: Use AuctionPoolHookMetaData.ABI instead.
var AuctionPoolHookABI = AuctionPoolHookMetaData.ABI

// AuctionPoolHook is an auto generated Go binding around an Ethereum contract.
type AuctionPoolHook struct {
	AuctionPoolHookCaller     // Read-only binding to the contract
	AuctionPoolHookTransactor // Write-only binding to the contract
	AuctionPoolHookFilterer   // Log filterer for contract events
}

// AuctionPoolHookCaller is an auto generated read-only Go binding around an Ethereum contract.
type AuctionPoolHookCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AuctionPoolHookTransactor is an auto generated write-only Go binding around an Ethereum contract.
type AuctionPoolHookTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AuctionPoolHookFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type AuctionPoolHookFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// AuctionPoolHookSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type AuctionPoolHookSession struct {
	Contract     *AuctionPoolHook  // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// AuctionPoolHookCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type AuctionPoolHookCallerSession struct {
	Contract *AuctionPoolHookCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts          // Call options to use throughout this session
}

// AuctionPoolHookTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type AuctionPoolHookTransactorSession struct {
	Contract     *AuctionPoolHookTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts          // Transaction auth options to use throughout this session
}

// AuctionPoolHookRaw is an auto generated low-level Go binding around an Ethereum contract.
type AuctionPoolHookRaw struct {
	Contract *AuctionPoolHook // Generic contract binding to access the raw methods on
}

// AuctionPoolHookCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type AuctionPoolHookCallerRaw struct {
	Contract *AuctionPoolHookCaller // Generic read-only contract binding to access the raw methods on
}

// AuctionPoolHookTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type AuctionPoolHookTransactorRaw struct {
	Contract *AuctionPoolHookTransactor // Generic write-only contract binding to access the raw methods on
}

// NewAuctionPoolHook creates a new instance of AuctionPoolHook, bound to a specific deployed contract.
func NewAuctionPoolHook(address common.Address, backend bind.ContractBackend) (*AuctionPoolHook, error) {
	contract, err := bindAuctionPoolHook(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHook{AuctionPoolHookCaller: AuctionPoolHookCaller{contract: contract}, AuctionPoolHookTransactor: AuctionPoolHookTransactor{contract: contract}, AuctionPoolHookFilterer: AuctionPoolHookFilterer{contract: contract}}, nil
}

// NewAuctionPoolHookCaller creates a new read-only instance of AuctionPoolHook, bound to a specific deployed contract.
func NewAuctionPoolHookCaller(address common.Address, caller bind.ContractCaller) (*AuctionPoolHookCaller, error) {
	contract, err := bindAuctionPoolHook(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookCaller{contract: contract}, nil
}

// NewAuctionPoolHookTransactor creates a new write-only instance of AuctionPoolHook, bound to a specific deployed contract.
func NewAuctionPoolHookTransactor(address common.Address, transactor bind.ContractTransactor) (*AuctionPoolHookTransactor, error) {
	contract, err := bindAuctionPoolHook(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookTransactor{contract: contract}, nil
}

// NewAuctionPoolHookFilterer creates a new log filterer instance of AuctionPoolHook, bound to a specific deployed contract.
func NewAuctionPoolHookFilterer(address common.Address, filterer bind.ContractFilterer) (*AuctionPoolHookFilterer, error) {
	contract, err := bindAuctionPoolHook(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookFilterer{contract: contract}, nil
}

// bindAuctionPoolHook binds a generic wrapper to an already deployed contract.
func bindAuctionPoolHook(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := AuctionPoolHookMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_AuctionPoolHook *AuctionPoolHookRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _AuctionPoolHook.Contract.AuctionPoolHookCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_AuctionPoolHook *AuctionPoolHookRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AuctionPoolHookTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_AuctionPoolHook *AuctionPoolHookRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AuctionPoolHookTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_AuctionPoolHook *AuctionPoolHookCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _AuctionPoolHook.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_AuctionPoolHook *AuctionPoolHookTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_AuctionPoolHook *AuctionPoolHookTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.contract.Transact(opts, method, params...)
}

// ACTIVATIONDELAY is a free data retrieval call binding the contract method 0x05b0356f.
//
// Solidity: function ACTIVATION_DELAY() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) ACTIVATIONDELAY(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "ACTIVATION_DELAY")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ACTIVATIONDELAY is a free data retrieval call binding the contract method 0x05b0356f.
//
// Solidity: function ACTIVATION_DELAY() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) ACTIVATIONDELAY() (*big.Int, error) {
	return _AuctionPoolHook.Contract.ACTIVATIONDELAY(&_AuctionPoolHook.CallOpts)
}

// ACTIVATIONDELAY is a free data retrieval call binding the contract method 0x05b0356f.
//
// Solidity: function ACTIVATION_DELAY() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) ACTIVATIONDELAY() (*big.Int, error) {
	return _AuctionPoolHook.Contract.ACTIVATIONDELAY(&_AuctionPoolHook.CallOpts)
}

// MAXFEE is a free data retrieval call binding the contract method 0xbc063e1a.
//
// Solidity: function MAX_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookCaller) MAXFEE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "MAX_FEE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXFEE is a free data retrieval call binding the contract method 0xbc063e1a.
//
// Solidity: function MAX_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookSession) MAXFEE() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MAXFEE(&_AuctionPoolHook.CallOpts)
}

// MAXFEE is a free data retrieval call binding the contract method 0xbc063e1a.
//
// Solidity: function MAX_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) MAXFEE() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MAXFEE(&_AuctionPoolHook.CallOpts)
}

// MINBIDINCREMENT is a free data retrieval call binding the contract method 0x71943bce.
//
// Solidity: function MIN_BID_INCREMENT() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) MINBIDINCREMENT(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "MIN_BID_INCREMENT")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MINBIDINCREMENT is a free data retrieval call binding the contract method 0x71943bce.
//
// Solidity: function MIN_BID_INCREMENT() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) MINBIDINCREMENT() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MINBIDINCREMENT(&_AuctionPoolHook.CallOpts)
}

// MINBIDINCREMENT is a free data retrieval call binding the contract method 0x71943bce.
//
// Solidity: function MIN_BID_INCREMENT() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) MINBIDINCREMENT() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MINBIDINCREMENT(&_AuctionPoolHook.CallOpts)
}

// MINDEPOSITBLOCKS is a free data retrieval call binding the contract method 0xcaa262f5.
//
// Solidity: function MIN_DEPOSIT_BLOCKS() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) MINDEPOSITBLOCKS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "MIN_DEPOSIT_BLOCKS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MINDEPOSITBLOCKS is a free data retrieval call binding the contract method 0xcaa262f5.
//
// Solidity: function MIN_DEPOSIT_BLOCKS() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) MINDEPOSITBLOCKS() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MINDEPOSITBLOCKS(&_AuctionPoolHook.CallOpts)
}

// MINDEPOSITBLOCKS is a free data retrieval call binding the contract method 0xcaa262f5.
//
// Solidity: function MIN_DEPOSIT_BLOCKS() view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) MINDEPOSITBLOCKS() (*big.Int, error) {
	return _AuctionPoolHook.Contract.MINDEPOSITBLOCKS(&_AuctionPoolHook.CallOpts)
}

// WITHDRAWALFEE is a free data retrieval call binding the contract method 0xa5d33ed5.
//
// Solidity: function WITHDRAWAL_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookCaller) WITHDRAWALFEE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "WITHDRAWAL_FEE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WITHDRAWALFEE is a free data retrieval call binding the contract method 0xa5d33ed5.
//
// Solidity: function WITHDRAWAL_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookSession) WITHDRAWALFEE() (*big.Int, error) {
	return _AuctionPoolHook.Contract.WITHDRAWALFEE(&_AuctionPoolHook.CallOpts)
}

// WITHDRAWALFEE is a free data retrieval call binding the contract method 0xa5d33ed5.
//
// Solidity: function WITHDRAWAL_FEE() view returns(uint24)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) WITHDRAWALFEE() (*big.Int, error) {
	return _AuctionPoolHook.Contract.WITHDRAWALFEE(&_AuctionPoolHook.CallOpts)
}

// BidHistory is a free data retrieval call binding the contract method 0x75165fe6.
//
// Solidity: function bidHistory(bytes32 , uint256 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookCaller) BidHistory(opts *bind.CallOpts, arg0 [32]byte, arg1 *big.Int) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "bidHistory", arg0, arg1)

	outstruct := new(struct {
		Bidder          common.Address
		RentPerBlock    *big.Int
		Deposit         *big.Int
		ActivationBlock *big.Int
		Timestamp       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Bidder = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.RentPerBlock = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Deposit = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.ActivationBlock = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.Timestamp = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// BidHistory is a free data retrieval call binding the contract method 0x75165fe6.
//
// Solidity: function bidHistory(bytes32 , uint256 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookSession) BidHistory(arg0 [32]byte, arg1 *big.Int) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	return _AuctionPoolHook.Contract.BidHistory(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// BidHistory is a free data retrieval call binding the contract method 0x75165fe6.
//
// Solidity: function bidHistory(bytes32 , uint256 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) BidHistory(arg0 [32]byte, arg1 *big.Int) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	return _AuctionPoolHook.Contract.BidHistory(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// GetBidHistory is a free data retrieval call binding the contract method 0x4af680c1.
//
// Solidity: function getBidHistory(bytes32 poolId) view returns((address,uint256,uint256,uint256,uint256)[])
func (_AuctionPoolHook *AuctionPoolHookCaller) GetBidHistory(opts *bind.CallOpts, poolId [32]byte) ([]AuctionPoolHookBid, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "getBidHistory", poolId)

	if err != nil {
		return *new([]AuctionPoolHookBid), err
	}

	out0 := *abi.ConvertType(out[0], new([]AuctionPoolHookBid)).(*[]AuctionPoolHookBid)

	return out0, err

}

// GetBidHistory is a free data retrieval call binding the contract method 0x4af680c1.
//
// Solidity: function getBidHistory(bytes32 poolId) view returns((address,uint256,uint256,uint256,uint256)[])
func (_AuctionPoolHook *AuctionPoolHookSession) GetBidHistory(poolId [32]byte) ([]AuctionPoolHookBid, error) {
	return _AuctionPoolHook.Contract.GetBidHistory(&_AuctionPoolHook.CallOpts, poolId)
}

// GetBidHistory is a free data retrieval call binding the contract method 0x4af680c1.
//
// Solidity: function getBidHistory(bytes32 poolId) view returns((address,uint256,uint256,uint256,uint256)[])
func (_AuctionPoolHook *AuctionPoolHookCallerSession) GetBidHistory(poolId [32]byte) ([]AuctionPoolHookBid, error) {
	return _AuctionPoolHook.Contract.GetBidHistory(&_AuctionPoolHook.CallOpts, poolId)
}

// GetHookPermissions is a free data retrieval call binding the contract method 0xc4e833ce.
//
// Solidity: function getHookPermissions() pure returns((bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool))
func (_AuctionPoolHook *AuctionPoolHookCaller) GetHookPermissions(opts *bind.CallOpts) (HooksPermissions, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "getHookPermissions")

	if err != nil {
		return *new(HooksPermissions), err
	}

	out0 := *abi.ConvertType(out[0], new(HooksPermissions)).(*HooksPermissions)

	return out0, err

}

// GetHookPermissions is a free data retrieval call binding the contract method 0xc4e833ce.
//
// Solidity: function getHookPermissions() pure returns((bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool))
func (_AuctionPoolHook *AuctionPoolHookSession) GetHookPermissions() (HooksPermissions, error) {
	return _AuctionPoolHook.Contract.GetHookPermissions(&_AuctionPoolHook.CallOpts)
}

// GetHookPermissions is a free data retrieval call binding the contract method 0xc4e833ce.
//
// Solidity: function getHookPermissions() pure returns((bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool))
func (_AuctionPoolHook *AuctionPoolHookCallerSession) GetHookPermissions() (HooksPermissions, error) {
	return _AuctionPoolHook.Contract.GetHookPermissions(&_AuctionPoolHook.CallOpts)
}

// GetPendingRent is a free data retrieval call binding the contract method 0xe112e916.
//
// Solidity: function getPendingRent(bytes32 poolId, address lp) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) GetPendingRent(opts *bind.CallOpts, poolId [32]byte, lp common.Address) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "getPendingRent", poolId, lp)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPendingRent is a free data retrieval call binding the contract method 0xe112e916.
//
// Solidity: function getPendingRent(bytes32 poolId, address lp) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) GetPendingRent(poolId [32]byte, lp common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.GetPendingRent(&_AuctionPoolHook.CallOpts, poolId, lp)
}

// GetPendingRent is a free data retrieval call binding the contract method 0xe112e916.
//
// Solidity: function getPendingRent(bytes32 poolId, address lp) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) GetPendingRent(poolId [32]byte, lp common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.GetPendingRent(&_AuctionPoolHook.CallOpts, poolId, lp)
}

// GetSwapFee is a free data retrieval call binding the contract method 0xf619a239.
//
// Solidity: function getSwapFee(bytes32 poolId, address sender) view returns(uint24 swapFee)
func (_AuctionPoolHook *AuctionPoolHookCaller) GetSwapFee(opts *bind.CallOpts, poolId [32]byte, sender common.Address) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "getSwapFee", poolId, sender)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSwapFee is a free data retrieval call binding the contract method 0xf619a239.
//
// Solidity: function getSwapFee(bytes32 poolId, address sender) view returns(uint24 swapFee)
func (_AuctionPoolHook *AuctionPoolHookSession) GetSwapFee(poolId [32]byte, sender common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.GetSwapFee(&_AuctionPoolHook.CallOpts, poolId, sender)
}

// GetSwapFee is a free data retrieval call binding the contract method 0xf619a239.
//
// Solidity: function getSwapFee(bytes32 poolId, address sender) view returns(uint24 swapFee)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) GetSwapFee(poolId [32]byte, sender common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.GetSwapFee(&_AuctionPoolHook.CallOpts, poolId, sender)
}

// LpShares is a free data retrieval call binding the contract method 0xaad8d92e.
//
// Solidity: function lpShares(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) LpShares(opts *bind.CallOpts, arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "lpShares", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LpShares is a free data retrieval call binding the contract method 0xaad8d92e.
//
// Solidity: function lpShares(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) LpShares(arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.LpShares(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// LpShares is a free data retrieval call binding the contract method 0xaad8d92e.
//
// Solidity: function lpShares(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) LpShares(arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.LpShares(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// ManagerFees is a free data retrieval call binding the contract method 0x90f16ec7.
//
// Solidity: function managerFees(address , bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) ManagerFees(opts *bind.CallOpts, arg0 common.Address, arg1 [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "managerFees", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ManagerFees is a free data retrieval call binding the contract method 0x90f16ec7.
//
// Solidity: function managerFees(address , bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) ManagerFees(arg0 common.Address, arg1 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.ManagerFees(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// ManagerFees is a free data retrieval call binding the contract method 0x90f16ec7.
//
// Solidity: function managerFees(address , bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) ManagerFees(arg0 common.Address, arg1 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.ManagerFees(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// NextBid is a free data retrieval call binding the contract method 0x99ef0d9f.
//
// Solidity: function nextBid(bytes32 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookCaller) NextBid(opts *bind.CallOpts, arg0 [32]byte) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "nextBid", arg0)

	outstruct := new(struct {
		Bidder          common.Address
		RentPerBlock    *big.Int
		Deposit         *big.Int
		ActivationBlock *big.Int
		Timestamp       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Bidder = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.RentPerBlock = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Deposit = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.ActivationBlock = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.Timestamp = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// NextBid is a free data retrieval call binding the contract method 0x99ef0d9f.
//
// Solidity: function nextBid(bytes32 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookSession) NextBid(arg0 [32]byte) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	return _AuctionPoolHook.Contract.NextBid(&_AuctionPoolHook.CallOpts, arg0)
}

// NextBid is a free data retrieval call binding the contract method 0x99ef0d9f.
//
// Solidity: function nextBid(bytes32 ) view returns(address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) NextBid(arg0 [32]byte) (struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}, error) {
	return _AuctionPoolHook.Contract.NextBid(&_AuctionPoolHook.CallOpts, arg0)
}

// PoolAuctions is a free data retrieval call binding the contract method 0xbbb6200e.
//
// Solidity: function poolAuctions(bytes32 ) view returns(address currentManager, uint256 rentPerBlock, uint256 managerDeposit, uint256 lastRentBlock, uint24 currentFee, uint256 totalRentPaid)
func (_AuctionPoolHook *AuctionPoolHookCaller) PoolAuctions(opts *bind.CallOpts, arg0 [32]byte) (struct {
	CurrentManager common.Address
	RentPerBlock   *big.Int
	ManagerDeposit *big.Int
	LastRentBlock  *big.Int
	CurrentFee     *big.Int
	TotalRentPaid  *big.Int
}, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "poolAuctions", arg0)

	outstruct := new(struct {
		CurrentManager common.Address
		RentPerBlock   *big.Int
		ManagerDeposit *big.Int
		LastRentBlock  *big.Int
		CurrentFee     *big.Int
		TotalRentPaid  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.CurrentManager = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.RentPerBlock = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.ManagerDeposit = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.LastRentBlock = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.CurrentFee = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.TotalRentPaid = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PoolAuctions is a free data retrieval call binding the contract method 0xbbb6200e.
//
// Solidity: function poolAuctions(bytes32 ) view returns(address currentManager, uint256 rentPerBlock, uint256 managerDeposit, uint256 lastRentBlock, uint24 currentFee, uint256 totalRentPaid)
func (_AuctionPoolHook *AuctionPoolHookSession) PoolAuctions(arg0 [32]byte) (struct {
	CurrentManager common.Address
	RentPerBlock   *big.Int
	ManagerDeposit *big.Int
	LastRentBlock  *big.Int
	CurrentFee     *big.Int
	TotalRentPaid  *big.Int
}, error) {
	return _AuctionPoolHook.Contract.PoolAuctions(&_AuctionPoolHook.CallOpts, arg0)
}

// PoolAuctions is a free data retrieval call binding the contract method 0xbbb6200e.
//
// Solidity: function poolAuctions(bytes32 ) view returns(address currentManager, uint256 rentPerBlock, uint256 managerDeposit, uint256 lastRentBlock, uint24 currentFee, uint256 totalRentPaid)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) PoolAuctions(arg0 [32]byte) (struct {
	CurrentManager common.Address
	RentPerBlock   *big.Int
	ManagerDeposit *big.Int
	LastRentBlock  *big.Int
	CurrentFee     *big.Int
	TotalRentPaid  *big.Int
}, error) {
	return _AuctionPoolHook.Contract.PoolAuctions(&_AuctionPoolHook.CallOpts, arg0)
}

// PoolManager is a free data retrieval call binding the contract method 0xdc4c90d3.
//
// Solidity: function poolManager() view returns(address)
func (_AuctionPoolHook *AuctionPoolHookCaller) PoolManager(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "poolManager")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PoolManager is a free data retrieval call binding the contract method 0xdc4c90d3.
//
// Solidity: function poolManager() view returns(address)
func (_AuctionPoolHook *AuctionPoolHookSession) PoolManager() (common.Address, error) {
	return _AuctionPoolHook.Contract.PoolManager(&_AuctionPoolHook.CallOpts)
}

// PoolManager is a free data retrieval call binding the contract method 0xdc4c90d3.
//
// Solidity: function poolManager() view returns(address)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) PoolManager() (common.Address, error) {
	return _AuctionPoolHook.Contract.PoolManager(&_AuctionPoolHook.CallOpts)
}

// RentPerShareAccumulated is a free data retrieval call binding the contract method 0x33c79ed7.
//
// Solidity: function rentPerShareAccumulated(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) RentPerShareAccumulated(opts *bind.CallOpts, arg0 [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "rentPerShareAccumulated", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RentPerShareAccumulated is a free data retrieval call binding the contract method 0x33c79ed7.
//
// Solidity: function rentPerShareAccumulated(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) RentPerShareAccumulated(arg0 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.RentPerShareAccumulated(&_AuctionPoolHook.CallOpts, arg0)
}

// RentPerShareAccumulated is a free data retrieval call binding the contract method 0x33c79ed7.
//
// Solidity: function rentPerShareAccumulated(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) RentPerShareAccumulated(arg0 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.RentPerShareAccumulated(&_AuctionPoolHook.CallOpts, arg0)
}

// RentPerShareClaimed is a free data retrieval call binding the contract method 0x92bfac27.
//
// Solidity: function rentPerShareClaimed(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) RentPerShareClaimed(opts *bind.CallOpts, arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "rentPerShareClaimed", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// RentPerShareClaimed is a free data retrieval call binding the contract method 0x92bfac27.
//
// Solidity: function rentPerShareClaimed(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) RentPerShareClaimed(arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.RentPerShareClaimed(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// RentPerShareClaimed is a free data retrieval call binding the contract method 0x92bfac27.
//
// Solidity: function rentPerShareClaimed(bytes32 , address ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) RentPerShareClaimed(arg0 [32]byte, arg1 common.Address) (*big.Int, error) {
	return _AuctionPoolHook.Contract.RentPerShareClaimed(&_AuctionPoolHook.CallOpts, arg0, arg1)
}

// TotalShares is a free data retrieval call binding the contract method 0x12e8d594.
//
// Solidity: function totalShares(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCaller) TotalShares(opts *bind.CallOpts, arg0 [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _AuctionPoolHook.contract.Call(opts, &out, "totalShares", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalShares is a free data retrieval call binding the contract method 0x12e8d594.
//
// Solidity: function totalShares(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookSession) TotalShares(arg0 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.TotalShares(&_AuctionPoolHook.CallOpts, arg0)
}

// TotalShares is a free data retrieval call binding the contract method 0x12e8d594.
//
// Solidity: function totalShares(bytes32 ) view returns(uint256)
func (_AuctionPoolHook *AuctionPoolHookCallerSession) TotalShares(arg0 [32]byte) (*big.Int, error) {
	return _AuctionPoolHook.Contract.TotalShares(&_AuctionPoolHook.CallOpts, arg0)
}

// AfterAddLiquidity is a paid mutator transaction binding the contract method 0x9f063efc.
//
// Solidity: function afterAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookTransactor) AfterAddLiquidity(opts *bind.TransactOpts, sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "afterAddLiquidity", sender, key, params, delta, feesAccrued, hookData)
}

// AfterAddLiquidity is a paid mutator transaction binding the contract method 0x9f063efc.
//
// Solidity: function afterAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookSession) AfterAddLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterAddLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, feesAccrued, hookData)
}

// AfterAddLiquidity is a paid mutator transaction binding the contract method 0x9f063efc.
//
// Solidity: function afterAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) AfterAddLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterAddLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, feesAccrued, hookData)
}

// AfterDonate is a paid mutator transaction binding the contract method 0xe1b4af69.
//
// Solidity: function afterDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) AfterDonate(opts *bind.TransactOpts, sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "afterDonate", sender, key, amount0, amount1, hookData)
}

// AfterDonate is a paid mutator transaction binding the contract method 0xe1b4af69.
//
// Solidity: function afterDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) AfterDonate(sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterDonate(&_AuctionPoolHook.TransactOpts, sender, key, amount0, amount1, hookData)
}

// AfterDonate is a paid mutator transaction binding the contract method 0xe1b4af69.
//
// Solidity: function afterDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) AfterDonate(sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterDonate(&_AuctionPoolHook.TransactOpts, sender, key, amount0, amount1, hookData)
}

// AfterInitialize is a paid mutator transaction binding the contract method 0x6fe7e6eb.
//
// Solidity: function afterInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96, int24 tick) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) AfterInitialize(opts *bind.TransactOpts, sender common.Address, key PoolKey, sqrtPriceX96 *big.Int, tick *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "afterInitialize", sender, key, sqrtPriceX96, tick)
}

// AfterInitialize is a paid mutator transaction binding the contract method 0x6fe7e6eb.
//
// Solidity: function afterInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96, int24 tick) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) AfterInitialize(sender common.Address, key PoolKey, sqrtPriceX96 *big.Int, tick *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterInitialize(&_AuctionPoolHook.TransactOpts, sender, key, sqrtPriceX96, tick)
}

// AfterInitialize is a paid mutator transaction binding the contract method 0x6fe7e6eb.
//
// Solidity: function afterInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96, int24 tick) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) AfterInitialize(sender common.Address, key PoolKey, sqrtPriceX96 *big.Int, tick *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterInitialize(&_AuctionPoolHook.TransactOpts, sender, key, sqrtPriceX96, tick)
}

// AfterRemoveLiquidity is a paid mutator transaction binding the contract method 0x6c2bbe7e.
//
// Solidity: function afterRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookTransactor) AfterRemoveLiquidity(opts *bind.TransactOpts, sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "afterRemoveLiquidity", sender, key, params, delta, feesAccrued, hookData)
}

// AfterRemoveLiquidity is a paid mutator transaction binding the contract method 0x6c2bbe7e.
//
// Solidity: function afterRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookSession) AfterRemoveLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterRemoveLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, feesAccrued, hookData)
}

// AfterRemoveLiquidity is a paid mutator transaction binding the contract method 0x6c2bbe7e.
//
// Solidity: function afterRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, int256 delta, int256 feesAccrued, bytes hookData) returns(bytes4, int256)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) AfterRemoveLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, delta *big.Int, feesAccrued *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterRemoveLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, feesAccrued, hookData)
}

// AfterSwap is a paid mutator transaction binding the contract method 0xb47b2fb1.
//
// Solidity: function afterSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, int256 delta, bytes hookData) returns(bytes4, int128)
func (_AuctionPoolHook *AuctionPoolHookTransactor) AfterSwap(opts *bind.TransactOpts, sender common.Address, key PoolKey, params SwapParams, delta *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "afterSwap", sender, key, params, delta, hookData)
}

// AfterSwap is a paid mutator transaction binding the contract method 0xb47b2fb1.
//
// Solidity: function afterSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, int256 delta, bytes hookData) returns(bytes4, int128)
func (_AuctionPoolHook *AuctionPoolHookSession) AfterSwap(sender common.Address, key PoolKey, params SwapParams, delta *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterSwap(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, hookData)
}

// AfterSwap is a paid mutator transaction binding the contract method 0xb47b2fb1.
//
// Solidity: function afterSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, int256 delta, bytes hookData) returns(bytes4, int128)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) AfterSwap(sender common.Address, key PoolKey, params SwapParams, delta *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.AfterSwap(&_AuctionPoolHook.TransactOpts, sender, key, params, delta, hookData)
}

// BeforeAddLiquidity is a paid mutator transaction binding the contract method 0x259982e5.
//
// Solidity: function beforeAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) BeforeAddLiquidity(opts *bind.TransactOpts, sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "beforeAddLiquidity", sender, key, params, hookData)
}

// BeforeAddLiquidity is a paid mutator transaction binding the contract method 0x259982e5.
//
// Solidity: function beforeAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) BeforeAddLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeAddLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// BeforeAddLiquidity is a paid mutator transaction binding the contract method 0x259982e5.
//
// Solidity: function beforeAddLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) BeforeAddLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeAddLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// BeforeDonate is a paid mutator transaction binding the contract method 0xb6a8b0fa.
//
// Solidity: function beforeDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) BeforeDonate(opts *bind.TransactOpts, sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "beforeDonate", sender, key, amount0, amount1, hookData)
}

// BeforeDonate is a paid mutator transaction binding the contract method 0xb6a8b0fa.
//
// Solidity: function beforeDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) BeforeDonate(sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeDonate(&_AuctionPoolHook.TransactOpts, sender, key, amount0, amount1, hookData)
}

// BeforeDonate is a paid mutator transaction binding the contract method 0xb6a8b0fa.
//
// Solidity: function beforeDonate(address sender, (address,address,uint24,int24,address) key, uint256 amount0, uint256 amount1, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) BeforeDonate(sender common.Address, key PoolKey, amount0 *big.Int, amount1 *big.Int, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeDonate(&_AuctionPoolHook.TransactOpts, sender, key, amount0, amount1, hookData)
}

// BeforeInitialize is a paid mutator transaction binding the contract method 0xdc98354e.
//
// Solidity: function beforeInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) BeforeInitialize(opts *bind.TransactOpts, sender common.Address, key PoolKey, sqrtPriceX96 *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "beforeInitialize", sender, key, sqrtPriceX96)
}

// BeforeInitialize is a paid mutator transaction binding the contract method 0xdc98354e.
//
// Solidity: function beforeInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) BeforeInitialize(sender common.Address, key PoolKey, sqrtPriceX96 *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeInitialize(&_AuctionPoolHook.TransactOpts, sender, key, sqrtPriceX96)
}

// BeforeInitialize is a paid mutator transaction binding the contract method 0xdc98354e.
//
// Solidity: function beforeInitialize(address sender, (address,address,uint24,int24,address) key, uint160 sqrtPriceX96) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) BeforeInitialize(sender common.Address, key PoolKey, sqrtPriceX96 *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeInitialize(&_AuctionPoolHook.TransactOpts, sender, key, sqrtPriceX96)
}

// BeforeRemoveLiquidity is a paid mutator transaction binding the contract method 0x21d0ee70.
//
// Solidity: function beforeRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactor) BeforeRemoveLiquidity(opts *bind.TransactOpts, sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "beforeRemoveLiquidity", sender, key, params, hookData)
}

// BeforeRemoveLiquidity is a paid mutator transaction binding the contract method 0x21d0ee70.
//
// Solidity: function beforeRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookSession) BeforeRemoveLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeRemoveLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// BeforeRemoveLiquidity is a paid mutator transaction binding the contract method 0x21d0ee70.
//
// Solidity: function beforeRemoveLiquidity(address sender, (address,address,uint24,int24,address) key, (int24,int24,int256,bytes32) params, bytes hookData) returns(bytes4)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) BeforeRemoveLiquidity(sender common.Address, key PoolKey, params ModifyLiquidityParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeRemoveLiquidity(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// BeforeSwap is a paid mutator transaction binding the contract method 0x575e24b4.
//
// Solidity: function beforeSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, bytes hookData) returns(bytes4, int256, uint24)
func (_AuctionPoolHook *AuctionPoolHookTransactor) BeforeSwap(opts *bind.TransactOpts, sender common.Address, key PoolKey, params SwapParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "beforeSwap", sender, key, params, hookData)
}

// BeforeSwap is a paid mutator transaction binding the contract method 0x575e24b4.
//
// Solidity: function beforeSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, bytes hookData) returns(bytes4, int256, uint24)
func (_AuctionPoolHook *AuctionPoolHookSession) BeforeSwap(sender common.Address, key PoolKey, params SwapParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeSwap(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// BeforeSwap is a paid mutator transaction binding the contract method 0x575e24b4.
//
// Solidity: function beforeSwap(address sender, (address,address,uint24,int24,address) key, (bool,int256,uint160) params, bytes hookData) returns(bytes4, int256, uint24)
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) BeforeSwap(sender common.Address, key PoolKey, params SwapParams, hookData []byte) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.BeforeSwap(&_AuctionPoolHook.TransactOpts, sender, key, params, hookData)
}

// ClaimRent is a paid mutator transaction binding the contract method 0xbf230dbd.
//
// Solidity: function claimRent((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactor) ClaimRent(opts *bind.TransactOpts, key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "claimRent", key)
}

// ClaimRent is a paid mutator transaction binding the contract method 0xbf230dbd.
//
// Solidity: function claimRent((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookSession) ClaimRent(key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.ClaimRent(&_AuctionPoolHook.TransactOpts, key)
}

// ClaimRent is a paid mutator transaction binding the contract method 0xbf230dbd.
//
// Solidity: function claimRent((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) ClaimRent(key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.ClaimRent(&_AuctionPoolHook.TransactOpts, key)
}

// SetSwapFee is a paid mutator transaction binding the contract method 0x5c546426.
//
// Solidity: function setSwapFee((address,address,uint24,int24,address) key, uint24 newFee) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactor) SetSwapFee(opts *bind.TransactOpts, key PoolKey, newFee *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "setSwapFee", key, newFee)
}

// SetSwapFee is a paid mutator transaction binding the contract method 0x5c546426.
//
// Solidity: function setSwapFee((address,address,uint24,int24,address) key, uint24 newFee) returns()
func (_AuctionPoolHook *AuctionPoolHookSession) SetSwapFee(key PoolKey, newFee *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.SetSwapFee(&_AuctionPoolHook.TransactOpts, key, newFee)
}

// SetSwapFee is a paid mutator transaction binding the contract method 0x5c546426.
//
// Solidity: function setSwapFee((address,address,uint24,int24,address) key, uint24 newFee) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) SetSwapFee(key PoolKey, newFee *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.SetSwapFee(&_AuctionPoolHook.TransactOpts, key, newFee)
}

// SubmitBid is a paid mutator transaction binding the contract method 0x5f67edc2.
//
// Solidity: function submitBid((address,address,uint24,int24,address) key, uint256 rentPerBlock) payable returns()
func (_AuctionPoolHook *AuctionPoolHookTransactor) SubmitBid(opts *bind.TransactOpts, key PoolKey, rentPerBlock *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "submitBid", key, rentPerBlock)
}

// SubmitBid is a paid mutator transaction binding the contract method 0x5f67edc2.
//
// Solidity: function submitBid((address,address,uint24,int24,address) key, uint256 rentPerBlock) payable returns()
func (_AuctionPoolHook *AuctionPoolHookSession) SubmitBid(key PoolKey, rentPerBlock *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.SubmitBid(&_AuctionPoolHook.TransactOpts, key, rentPerBlock)
}

// SubmitBid is a paid mutator transaction binding the contract method 0x5f67edc2.
//
// Solidity: function submitBid((address,address,uint24,int24,address) key, uint256 rentPerBlock) payable returns()
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) SubmitBid(key PoolKey, rentPerBlock *big.Int) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.SubmitBid(&_AuctionPoolHook.TransactOpts, key, rentPerBlock)
}

// WithdrawManagerFees is a paid mutator transaction binding the contract method 0xabdf223b.
//
// Solidity: function withdrawManagerFees((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactor) WithdrawManagerFees(opts *bind.TransactOpts, key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.contract.Transact(opts, "withdrawManagerFees", key)
}

// WithdrawManagerFees is a paid mutator transaction binding the contract method 0xabdf223b.
//
// Solidity: function withdrawManagerFees((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookSession) WithdrawManagerFees(key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.WithdrawManagerFees(&_AuctionPoolHook.TransactOpts, key)
}

// WithdrawManagerFees is a paid mutator transaction binding the contract method 0xabdf223b.
//
// Solidity: function withdrawManagerFees((address,address,uint24,int24,address) key) returns()
func (_AuctionPoolHook *AuctionPoolHookTransactorSession) WithdrawManagerFees(key PoolKey) (*types.Transaction, error) {
	return _AuctionPoolHook.Contract.WithdrawManagerFees(&_AuctionPoolHook.TransactOpts, key)
}

// AuctionPoolHookBidSubmittedIterator is returned from FilterBidSubmitted and is used to iterate over the raw logs and unpacked data for BidSubmitted events raised by the AuctionPoolHook contract.
type AuctionPoolHookBidSubmittedIterator struct {
	Event *AuctionPoolHookBidSubmitted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookBidSubmittedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookBidSubmitted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookBidSubmitted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookBidSubmittedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookBidSubmittedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookBidSubmitted represents a BidSubmitted event raised by the AuctionPoolHook contract.
type AuctionPoolHookBidSubmitted struct {
	PoolId       [32]byte
	Bidder       common.Address
	RentPerBlock *big.Int
	Deposit      *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterBidSubmitted is a free log retrieval operation binding the contract event 0xd7065d9f36ddac2c4ac04341301746ec2eb20c41fc3fd7c41c360fc70233d273.
//
// Solidity: event BidSubmitted(bytes32 indexed poolId, address indexed bidder, uint256 rentPerBlock, uint256 deposit)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterBidSubmitted(opts *bind.FilterOpts, poolId [][32]byte, bidder []common.Address) (*AuctionPoolHookBidSubmittedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var bidderRule []interface{}
	for _, bidderItem := range bidder {
		bidderRule = append(bidderRule, bidderItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "BidSubmitted", poolIdRule, bidderRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookBidSubmittedIterator{contract: _AuctionPoolHook.contract, event: "BidSubmitted", logs: logs, sub: sub}, nil
}

// WatchBidSubmitted is a free log subscription operation binding the contract event 0xd7065d9f36ddac2c4ac04341301746ec2eb20c41fc3fd7c41c360fc70233d273.
//
// Solidity: event BidSubmitted(bytes32 indexed poolId, address indexed bidder, uint256 rentPerBlock, uint256 deposit)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchBidSubmitted(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookBidSubmitted, poolId [][32]byte, bidder []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var bidderRule []interface{}
	for _, bidderItem := range bidder {
		bidderRule = append(bidderRule, bidderItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "BidSubmitted", poolIdRule, bidderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookBidSubmitted)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "BidSubmitted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBidSubmitted is a log parse operation binding the contract event 0xd7065d9f36ddac2c4ac04341301746ec2eb20c41fc3fd7c41c360fc70233d273.
//
// Solidity: event BidSubmitted(bytes32 indexed poolId, address indexed bidder, uint256 rentPerBlock, uint256 deposit)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseBidSubmitted(log types.Log) (*AuctionPoolHookBidSubmitted, error) {
	event := new(AuctionPoolHookBidSubmitted)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "BidSubmitted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookFeeUpdatedIterator is returned from FilterFeeUpdated and is used to iterate over the raw logs and unpacked data for FeeUpdated events raised by the AuctionPoolHook contract.
type AuctionPoolHookFeeUpdatedIterator struct {
	Event *AuctionPoolHookFeeUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookFeeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookFeeUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookFeeUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookFeeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookFeeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookFeeUpdated represents a FeeUpdated event raised by the AuctionPoolHook contract.
type AuctionPoolHookFeeUpdated struct {
	PoolId  [32]byte
	Manager common.Address
	NewFee  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterFeeUpdated is a free log retrieval operation binding the contract event 0x01a39dec0f96fee30d31d630e7802d4a7752db694fa69c5cdda0a2f3eae36ba5.
//
// Solidity: event FeeUpdated(bytes32 indexed poolId, address indexed manager, uint24 newFee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterFeeUpdated(opts *bind.FilterOpts, poolId [][32]byte, manager []common.Address) (*AuctionPoolHookFeeUpdatedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "FeeUpdated", poolIdRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookFeeUpdatedIterator{contract: _AuctionPoolHook.contract, event: "FeeUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeUpdated is a free log subscription operation binding the contract event 0x01a39dec0f96fee30d31d630e7802d4a7752db694fa69c5cdda0a2f3eae36ba5.
//
// Solidity: event FeeUpdated(bytes32 indexed poolId, address indexed manager, uint24 newFee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchFeeUpdated(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookFeeUpdated, poolId [][32]byte, manager []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "FeeUpdated", poolIdRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookFeeUpdated)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseFeeUpdated is a log parse operation binding the contract event 0x01a39dec0f96fee30d31d630e7802d4a7752db694fa69c5cdda0a2f3eae36ba5.
//
// Solidity: event FeeUpdated(bytes32 indexed poolId, address indexed manager, uint24 newFee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseFeeUpdated(log types.Log) (*AuctionPoolHookFeeUpdated, error) {
	event := new(AuctionPoolHookFeeUpdated)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "FeeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookLiquidityUpdatedIterator is returned from FilterLiquidityUpdated and is used to iterate over the raw logs and unpacked data for LiquidityUpdated events raised by the AuctionPoolHook contract.
type AuctionPoolHookLiquidityUpdatedIterator struct {
	Event *AuctionPoolHookLiquidityUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookLiquidityUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookLiquidityUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookLiquidityUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookLiquidityUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookLiquidityUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookLiquidityUpdated represents a LiquidityUpdated event raised by the AuctionPoolHook contract.
type AuctionPoolHookLiquidityUpdated struct {
	PoolId     [32]byte
	Lp         common.Address
	Shares     *big.Int
	IsAddition bool
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterLiquidityUpdated is a free log retrieval operation binding the contract event 0x80d9261d7a352274636e935a9078b3f3e97c04fd260b5368c3d6c1f7333a9a24.
//
// Solidity: event LiquidityUpdated(bytes32 indexed poolId, address indexed lp, uint256 shares, bool isAddition)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterLiquidityUpdated(opts *bind.FilterOpts, poolId [][32]byte, lp []common.Address) (*AuctionPoolHookLiquidityUpdatedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "LiquidityUpdated", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookLiquidityUpdatedIterator{contract: _AuctionPoolHook.contract, event: "LiquidityUpdated", logs: logs, sub: sub}, nil
}

// WatchLiquidityUpdated is a free log subscription operation binding the contract event 0x80d9261d7a352274636e935a9078b3f3e97c04fd260b5368c3d6c1f7333a9a24.
//
// Solidity: event LiquidityUpdated(bytes32 indexed poolId, address indexed lp, uint256 shares, bool isAddition)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchLiquidityUpdated(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookLiquidityUpdated, poolId [][32]byte, lp []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "LiquidityUpdated", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookLiquidityUpdated)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "LiquidityUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseLiquidityUpdated is a log parse operation binding the contract event 0x80d9261d7a352274636e935a9078b3f3e97c04fd260b5368c3d6c1f7333a9a24.
//
// Solidity: event LiquidityUpdated(bytes32 indexed poolId, address indexed lp, uint256 shares, bool isAddition)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseLiquidityUpdated(log types.Log) (*AuctionPoolHookLiquidityUpdated, error) {
	event := new(AuctionPoolHookLiquidityUpdated)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "LiquidityUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookManagerChangedIterator is returned from FilterManagerChanged and is used to iterate over the raw logs and unpacked data for ManagerChanged events raised by the AuctionPoolHook contract.
type AuctionPoolHookManagerChangedIterator struct {
	Event *AuctionPoolHookManagerChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookManagerChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookManagerChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookManagerChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookManagerChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookManagerChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookManagerChanged represents a ManagerChanged event raised by the AuctionPoolHook contract.
type AuctionPoolHookManagerChanged struct {
	PoolId       [32]byte
	OldManager   common.Address
	NewManager   common.Address
	RentPerBlock *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterManagerChanged is a free log retrieval operation binding the contract event 0xaee50dd245b2b8a5a63920193e07dedb8d56994206f511f2a5803121dad306cc.
//
// Solidity: event ManagerChanged(bytes32 indexed poolId, address indexed oldManager, address indexed newManager, uint256 rentPerBlock)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterManagerChanged(opts *bind.FilterOpts, poolId [][32]byte, oldManager []common.Address, newManager []common.Address) (*AuctionPoolHookManagerChangedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "ManagerChanged", poolIdRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookManagerChangedIterator{contract: _AuctionPoolHook.contract, event: "ManagerChanged", logs: logs, sub: sub}, nil
}

// WatchManagerChanged is a free log subscription operation binding the contract event 0xaee50dd245b2b8a5a63920193e07dedb8d56994206f511f2a5803121dad306cc.
//
// Solidity: event ManagerChanged(bytes32 indexed poolId, address indexed oldManager, address indexed newManager, uint256 rentPerBlock)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchManagerChanged(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookManagerChanged, poolId [][32]byte, oldManager []common.Address, newManager []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var oldManagerRule []interface{}
	for _, oldManagerItem := range oldManager {
		oldManagerRule = append(oldManagerRule, oldManagerItem)
	}
	var newManagerRule []interface{}
	for _, newManagerItem := range newManager {
		newManagerRule = append(newManagerRule, newManagerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "ManagerChanged", poolIdRule, oldManagerRule, newManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookManagerChanged)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "ManagerChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseManagerChanged is a log parse operation binding the contract event 0xaee50dd245b2b8a5a63920193e07dedb8d56994206f511f2a5803121dad306cc.
//
// Solidity: event ManagerChanged(bytes32 indexed poolId, address indexed oldManager, address indexed newManager, uint256 rentPerBlock)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseManagerChanged(log types.Log) (*AuctionPoolHookManagerChanged, error) {
	event := new(AuctionPoolHookManagerChanged)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "ManagerChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookManagerFeesWithdrawnIterator is returned from FilterManagerFeesWithdrawn and is used to iterate over the raw logs and unpacked data for ManagerFeesWithdrawn events raised by the AuctionPoolHook contract.
type AuctionPoolHookManagerFeesWithdrawnIterator struct {
	Event *AuctionPoolHookManagerFeesWithdrawn // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookManagerFeesWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookManagerFeesWithdrawn)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookManagerFeesWithdrawn)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookManagerFeesWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookManagerFeesWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookManagerFeesWithdrawn represents a ManagerFeesWithdrawn event raised by the AuctionPoolHook contract.
type AuctionPoolHookManagerFeesWithdrawn struct {
	PoolId  [32]byte
	Manager common.Address
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterManagerFeesWithdrawn is a free log retrieval operation binding the contract event 0xb65c762cb8fe316f44c8b4b1a9b41155d19bdd76ff097850253e2bde177f224d.
//
// Solidity: event ManagerFeesWithdrawn(bytes32 indexed poolId, address indexed manager, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterManagerFeesWithdrawn(opts *bind.FilterOpts, poolId [][32]byte, manager []common.Address) (*AuctionPoolHookManagerFeesWithdrawnIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "ManagerFeesWithdrawn", poolIdRule, managerRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookManagerFeesWithdrawnIterator{contract: _AuctionPoolHook.contract, event: "ManagerFeesWithdrawn", logs: logs, sub: sub}, nil
}

// WatchManagerFeesWithdrawn is a free log subscription operation binding the contract event 0xb65c762cb8fe316f44c8b4b1a9b41155d19bdd76ff097850253e2bde177f224d.
//
// Solidity: event ManagerFeesWithdrawn(bytes32 indexed poolId, address indexed manager, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchManagerFeesWithdrawn(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookManagerFeesWithdrawn, poolId [][32]byte, manager []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var managerRule []interface{}
	for _, managerItem := range manager {
		managerRule = append(managerRule, managerItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "ManagerFeesWithdrawn", poolIdRule, managerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookManagerFeesWithdrawn)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "ManagerFeesWithdrawn", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseManagerFeesWithdrawn is a log parse operation binding the contract event 0xb65c762cb8fe316f44c8b4b1a9b41155d19bdd76ff097850253e2bde177f224d.
//
// Solidity: event ManagerFeesWithdrawn(bytes32 indexed poolId, address indexed manager, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseManagerFeesWithdrawn(log types.Log) (*AuctionPoolHookManagerFeesWithdrawn, error) {
	event := new(AuctionPoolHookManagerFeesWithdrawn)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "ManagerFeesWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookRentClaimedIterator is returned from FilterRentClaimed and is used to iterate over the raw logs and unpacked data for RentClaimed events raised by the AuctionPoolHook contract.
type AuctionPoolHookRentClaimedIterator struct {
	Event *AuctionPoolHookRentClaimed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookRentClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookRentClaimed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookRentClaimed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookRentClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookRentClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookRentClaimed represents a RentClaimed event raised by the AuctionPoolHook contract.
type AuctionPoolHookRentClaimed struct {
	PoolId [32]byte
	Lp     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterRentClaimed is a free log retrieval operation binding the contract event 0x874319b1d2e4ca9f5940ea33c2857c1aabbcbc14fa85a7ff824257fcf3de047f.
//
// Solidity: event RentClaimed(bytes32 indexed poolId, address indexed lp, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterRentClaimed(opts *bind.FilterOpts, poolId [][32]byte, lp []common.Address) (*AuctionPoolHookRentClaimedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "RentClaimed", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookRentClaimedIterator{contract: _AuctionPoolHook.contract, event: "RentClaimed", logs: logs, sub: sub}, nil
}

// WatchRentClaimed is a free log subscription operation binding the contract event 0x874319b1d2e4ca9f5940ea33c2857c1aabbcbc14fa85a7ff824257fcf3de047f.
//
// Solidity: event RentClaimed(bytes32 indexed poolId, address indexed lp, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchRentClaimed(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookRentClaimed, poolId [][32]byte, lp []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "RentClaimed", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookRentClaimed)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "RentClaimed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRentClaimed is a log parse operation binding the contract event 0x874319b1d2e4ca9f5940ea33c2857c1aabbcbc14fa85a7ff824257fcf3de047f.
//
// Solidity: event RentClaimed(bytes32 indexed poolId, address indexed lp, uint256 amount)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseRentClaimed(log types.Log) (*AuctionPoolHookRentClaimed, error) {
	event := new(AuctionPoolHookRentClaimed)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "RentClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookRentCollectedIterator is returned from FilterRentCollected and is used to iterate over the raw logs and unpacked data for RentCollected events raised by the AuctionPoolHook contract.
type AuctionPoolHookRentCollectedIterator struct {
	Event *AuctionPoolHookRentCollected // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookRentCollectedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookRentCollected)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookRentCollected)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookRentCollectedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookRentCollectedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookRentCollected represents a RentCollected event raised by the AuctionPoolHook contract.
type AuctionPoolHookRentCollected struct {
	PoolId      [32]byte
	Amount      *big.Int
	BlockNumber *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterRentCollected is a free log retrieval operation binding the contract event 0xc85845fb2432599296644f94432058a5a090e1e1daadffce698ea84912aac669.
//
// Solidity: event RentCollected(bytes32 indexed poolId, uint256 amount, uint256 blockNumber)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterRentCollected(opts *bind.FilterOpts, poolId [][32]byte) (*AuctionPoolHookRentCollectedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "RentCollected", poolIdRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookRentCollectedIterator{contract: _AuctionPoolHook.contract, event: "RentCollected", logs: logs, sub: sub}, nil
}

// WatchRentCollected is a free log subscription operation binding the contract event 0xc85845fb2432599296644f94432058a5a090e1e1daadffce698ea84912aac669.
//
// Solidity: event RentCollected(bytes32 indexed poolId, uint256 amount, uint256 blockNumber)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchRentCollected(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookRentCollected, poolId [][32]byte) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "RentCollected", poolIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookRentCollected)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "RentCollected", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRentCollected is a log parse operation binding the contract event 0xc85845fb2432599296644f94432058a5a090e1e1daadffce698ea84912aac669.
//
// Solidity: event RentCollected(bytes32 indexed poolId, uint256 amount, uint256 blockNumber)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseRentCollected(log types.Log) (*AuctionPoolHookRentCollected, error) {
	event := new(AuctionPoolHookRentCollected)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "RentCollected", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// AuctionPoolHookWithdrawalFeeChargedIterator is returned from FilterWithdrawalFeeCharged and is used to iterate over the raw logs and unpacked data for WithdrawalFeeCharged events raised by the AuctionPoolHook contract.
type AuctionPoolHookWithdrawalFeeChargedIterator struct {
	Event *AuctionPoolHookWithdrawalFeeCharged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *AuctionPoolHookWithdrawalFeeChargedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(AuctionPoolHookWithdrawalFeeCharged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(AuctionPoolHookWithdrawalFeeCharged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *AuctionPoolHookWithdrawalFeeChargedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *AuctionPoolHookWithdrawalFeeChargedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// AuctionPoolHookWithdrawalFeeCharged represents a WithdrawalFeeCharged event raised by the AuctionPoolHook contract.
type AuctionPoolHookWithdrawalFeeCharged struct {
	PoolId [32]byte
	Lp     common.Address
	Fee    *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterWithdrawalFeeCharged is a free log retrieval operation binding the contract event 0xaafde625bf6ad10ae3b4bdb419772ee03aa079dd8b1aa12ed5c34aa89349c4ec.
//
// Solidity: event WithdrawalFeeCharged(bytes32 indexed poolId, address indexed lp, uint256 fee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) FilterWithdrawalFeeCharged(opts *bind.FilterOpts, poolId [][32]byte, lp []common.Address) (*AuctionPoolHookWithdrawalFeeChargedIterator, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.FilterLogs(opts, "WithdrawalFeeCharged", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return &AuctionPoolHookWithdrawalFeeChargedIterator{contract: _AuctionPoolHook.contract, event: "WithdrawalFeeCharged", logs: logs, sub: sub}, nil
}

// WatchWithdrawalFeeCharged is a free log subscription operation binding the contract event 0xaafde625bf6ad10ae3b4bdb419772ee03aa079dd8b1aa12ed5c34aa89349c4ec.
//
// Solidity: event WithdrawalFeeCharged(bytes32 indexed poolId, address indexed lp, uint256 fee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) WatchWithdrawalFeeCharged(opts *bind.WatchOpts, sink chan<- *AuctionPoolHookWithdrawalFeeCharged, poolId [][32]byte, lp []common.Address) (event.Subscription, error) {

	var poolIdRule []interface{}
	for _, poolIdItem := range poolId {
		poolIdRule = append(poolIdRule, poolIdItem)
	}
	var lpRule []interface{}
	for _, lpItem := range lp {
		lpRule = append(lpRule, lpItem)
	}

	logs, sub, err := _AuctionPoolHook.contract.WatchLogs(opts, "WithdrawalFeeCharged", poolIdRule, lpRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(AuctionPoolHookWithdrawalFeeCharged)
				if err := _AuctionPoolHook.contract.UnpackLog(event, "WithdrawalFeeCharged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseWithdrawalFeeCharged is a log parse operation binding the contract event 0xaafde625bf6ad10ae3b4bdb419772ee03aa079dd8b1aa12ed5c34aa89349c4ec.
//
// Solidity: event WithdrawalFeeCharged(bytes32 indexed poolId, address indexed lp, uint256 fee)
func (_AuctionPoolHook *AuctionPoolHookFilterer) ParseWithdrawalFeeCharged(log types.Log) (*AuctionPoolHookWithdrawalFeeCharged, error) {
	event := new(AuctionPoolHookWithdrawalFeeCharged)
	if err := _AuctionPoolHook.contract.UnpackLog(event, "WithdrawalFeeCharged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
