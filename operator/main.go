package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Simplified autonomous operator that monitors and bids on AuctionPool
// This demonstrates the core auction mechanism for the hackathon demo

type Operator struct {
	client      *ethclient.Client
	privateKey  *ecdsa.PrivateKey
	address     common.Address
	hookAddress common.Address
	poolId      [32]byte
	poolKey     PoolKey

	// Strategy parameters
	profitMargin float64  // Percentage of expected profit to bid
	minProfit    *big.Int // Minimum profit threshold in wei

	// Contract ABI
	hookABI abi.ABI
}

// PoolKey struct matching Solidity
type PoolKey struct {
	Currency0   common.Address
	Currency1   common.Address
	Fee         *big.Int
	TickSpacing *big.Int
	Hooks       common.Address
}

// AuctionState struct matching Solidity
type AuctionState struct {
	CurrentManager common.Address
	RentPerBlock   *big.Int
	ManagerDeposit *big.Int
	LastRentBlock  *big.Int
	CurrentFee     *big.Int
	TotalRentPaid  *big.Int
}

// Bid struct matching Solidity
type Bid struct {
	Bidder          common.Address
	RentPerBlock    *big.Int
	Deposit         *big.Int
	ActivationBlock *big.Int
	Timestamp       *big.Int
}

const hookABIJSON = `[
	{
		"inputs": [
			{"name": "poolId", "type": "bytes32"}
		],
		"name": "poolAuctions",
		"outputs": [
			{"name": "currentManager", "type": "address"},
			{"name": "rentPerBlock", "type": "uint256"},
			{"name": "managerDeposit", "type": "uint256"},
			{"name": "lastRentBlock", "type": "uint256"},
			{"name": "currentFee", "type": "uint24"},
			{"name": "totalRentPaid", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"name": "poolId", "type": "bytes32"}
		],
		"name": "nextBid",
		"outputs": [
			{"name": "bidder", "type": "address"},
			{"name": "rentPerBlock", "type": "uint256"},
			{"name": "deposit", "type": "uint256"},
			{"name": "activationBlock", "type": "uint256"},
			{"name": "timestamp", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{"name": "currency0", "type": "address"},
					{"name": "currency1", "type": "address"},
					{"name": "fee", "type": "uint24"},
					{"name": "tickSpacing", "type": "int24"},
					{"name": "hooks", "type": "address"}
				],
				"name": "key",
				"type": "tuple"
			},
			{"name": "rentPerBlock", "type": "uint256"}
		],
		"name": "submitBid",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{"name": "currency0", "type": "address"},
					{"name": "currency1", "type": "address"},
					{"name": "fee", "type": "uint24"},
					{"name": "tickSpacing", "type": "int24"},
					{"name": "hooks", "type": "address"}
				],
				"name": "key",
				"type": "tuple"
			},
			{"name": "newFee", "type": "uint24"}
		],
		"name": "setSwapFee",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]`

func main() {
	// Load configuration from environment
	rpcURL := os.Getenv("RPC_URL")
	if rpcURL == "" {
		rpcURL = "http://localhost:8545"
	}

	privateKeyHex := os.Getenv("OPERATOR_PRIVATE_KEY")
	if privateKeyHex == "" {
		log.Fatal("OPERATOR_PRIVATE_KEY environment variable required")
	}

	hookAddress := os.Getenv("HOOK_ADDRESS")
	if hookAddress == "" {
		log.Fatal("HOOK_ADDRESS environment variable required")
	}

	poolIdHex := os.Getenv("POOL_ID")
	if poolIdHex == "" {
		log.Fatal("POOL_ID environment variable required")
	}

	// Connect to Ethereum client
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		log.Fatalf("Failed to connect to Ethereum client: %v", err)
	}

	// Load private key
	privateKeyHex = strings.TrimPrefix(privateKeyHex, "0x")
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		log.Fatalf("Failed to load private key: %v", err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("Error casting public key to ECDSA")
	}

	address := crypto.PubkeyToAddress(*publicKeyECDSA)

	// Parse pool ID
	var poolId [32]byte
	copy(poolId[:], common.FromHex(poolIdHex))

	// Load ABI
	hookABI, err := abi.JSON(strings.NewReader(hookABIJSON))
	if err != nil {
		log.Fatalf("Failed to parse ABI: %v", err)
	}

	// Parse pool key from environment (optional, can be constructed)
	poolKey := PoolKey{
		Currency0:   common.HexToAddress(getEnvOrDefault("CURRENCY0", "0x0000000000000000000000000000000000000000")),
		Currency1:   common.HexToAddress(getEnvOrDefault("CURRENCY1", "0x0000000000000000000000000000000000000000")),
		Fee:         big.NewInt(3000),
		TickSpacing: big.NewInt(60),
		Hooks:       common.HexToAddress(hookAddress),
	}

	operator := &Operator{
		client:       client,
		privateKey:   privateKey,
		address:      address,
		hookAddress:  common.HexToAddress(hookAddress),
		poolId:       poolId,
		poolKey:      poolKey,
		profitMargin: 0.8,              // Bid 80% of expected profit
		minProfit:    big.NewInt(1e15), // 0.001 ETH minimum
		hookABI:      hookABI,
	}

	log.Printf("=== AuctionPool Autonomous Operator ===")
	log.Printf("Operator address: %s", address.Hex())
	log.Printf("Hook address:     %s", hookAddress)
	log.Printf("Pool ID:          %s", common.Bytes2Hex(poolId[:]))
	log.Printf("RPC URL:          %s", rpcURL)
	log.Printf("")
	log.Printf("Strategy:")
	log.Printf("  - Profit margin: %.0f%%", operator.profitMargin*100)
	log.Printf("  - Min profit:    %s wei", operator.minProfit.String())
	log.Printf("")

	// Run operator loop
	operator.run()
}

func (op *Operator) run() {
	ticker := time.NewTicker(12 * time.Second) // Check every block (~12s)
	defer ticker.Stop()

	log.Println("Starting monitoring loop...")
	log.Println("")

	for {
		select {
		case <-ticker.C:
			op.executeStrategy()
		}
	}
}

func (op *Operator) executeStrategy() {
	ctx := context.Background()

	// Get current block number
	blockNumber, err := op.client.BlockNumber(ctx)
	if err != nil {
		log.Printf("Error getting block number: %v", err)
		return
	}

	// Query current pool state
	state, err := op.getPoolState(ctx)
	if err != nil {
		log.Printf("Error getting pool state: %v", err)
		return
	}

	// Query next pending bid
	nextBid, err := op.getNextBid(ctx)
	if err != nil {
		log.Printf("Error getting next bid: %v", err)
		return
	}

	log.Printf("Block %d | Manager: %s | Rent: %s wei/block | Fee: %s",
		blockNumber,
		truncateAddress(state.CurrentManager.Hex()),
		state.RentPerBlock.String(),
		state.CurrentFee.String())

	// Determine highest current rent to beat
	highestRent := state.RentPerBlock
	if nextBid.RentPerBlock.Cmp(highestRent) > 0 {
		highestRent = nextBid.RentPerBlock
		log.Printf("  Next bid pending: %s wei/block by %s (activates at block %s)",
			nextBid.RentPerBlock.String(),
			truncateAddress(nextBid.Bidder.Hex()),
			nextBid.ActivationBlock.String())
	}

	// Calculate expected profit
	expectedProfit := op.estimateProfit()
	profitableRent := new(big.Int).Mul(expectedProfit, big.NewInt(int64(op.profitMargin*100)))
	profitableRent.Div(profitableRent, big.NewInt(100))

	// Check if we should bid
	minBidIncrement := big.NewInt(100) // MIN_BID_INCREMENT from contract
	requiredBid := new(big.Int).Add(highestRent, minBidIncrement)

	if profitableRent.Cmp(requiredBid) >= 0 && expectedProfit.Cmp(op.minProfit) > 0 {
		log.Printf("  \u2705 Profitable opportunity detected!")
		log.Printf("    Expected profit: %s wei/block", expectedProfit.String())
		log.Printf("    Profitable rent: %s wei/block", profitableRent.String())
		log.Printf("    Required bid:    %s wei/block", requiredBid.String())

		// Submit bid
		err := op.submitBid(ctx, profitableRent)
		if err != nil {
			log.Printf("  \u274c Failed to submit bid: %v", err)
		} else {
			log.Printf("  \u2713 Bid submitted successfully!")
		}
	}

	// If we're the current manager, optimize fees
	if state.CurrentManager == op.address {
		optimalFee := op.calculateOptimalFee()
		if shouldUpdateFee(state.CurrentFee, optimalFee) {
			log.Printf("  \ud83d\udee0\ufe0f  Updating fee from %s to %s", state.CurrentFee.String(), optimalFee.String())
			err := op.setSwapFee(ctx, optimalFee)
			if err != nil {
				log.Printf("  \u274c Failed to set fee: %v", err)
			} else {
				log.Printf("  \u2713 Fee updated successfully!")
			}
		}
	}

	log.Println("")
}

func (op *Operator) getPoolState(ctx context.Context) (*AuctionState, error) {
	data, err := op.hookABI.Pack("poolAuctions", op.poolId)
	if err != nil {
		return nil, fmt.Errorf("failed to pack poolAuctions call: %w", err)
	}

	result, err := op.client.CallContract(ctx, ethereum.CallMsg{
		To:   &op.hookAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call poolAuctions: %w", err)
	}

	var state AuctionState
	err = op.hookABI.UnpackIntoInterface(&state, "poolAuctions", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack poolAuctions result: %w", err)
	}

	return &state, nil
}

func (op *Operator) getNextBid(ctx context.Context) (*Bid, error) {
	data, err := op.hookABI.Pack("nextBid", op.poolId)
	if err != nil {
		return nil, fmt.Errorf("failed to pack nextBid call: %w", err)
	}

	result, err := op.client.CallContract(ctx, ethereum.CallMsg{
		To:   &op.hookAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call nextBid: %w", err)
	}

	var bid Bid
	err = op.hookABI.UnpackIntoInterface(&bid, "nextBid", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack nextBid result: %w", err)
	}

	return &bid, nil
}

func (op *Operator) submitBid(ctx context.Context, rentPerBlock *big.Int) error {
	// Calculate deposit (rent * 100 blocks minimum)
	deposit := new(big.Int).Mul(rentPerBlock, big.NewInt(100))

	// Pack the transaction data
	data, err := op.hookABI.Pack("submitBid", op.poolKey, rentPerBlock)
	if err != nil {
		return fmt.Errorf("failed to pack submitBid: %w", err)
	}

	// Get nonce
	nonce, err := op.client.PendingNonceAt(ctx, op.address)
	if err != nil {
		return fmt.Errorf("failed to get nonce: %w", err)
	}

	// Get gas price
	gasPrice, err := op.client.SuggestGasPrice(ctx)
	if err != nil {
		return fmt.Errorf("failed to get gas price: %w", err)
	}

	// Get chain ID
	chainID, err := op.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Estimate gas
	gasLimit, err := op.client.EstimateGas(ctx, ethereum.CallMsg{
		From:  op.address,
		To:    &op.hookAddress,
		Value: deposit,
		Data:  data,
	})
	if err != nil {
		return fmt.Errorf("failed to estimate gas: %w", err)
	}

	// Create transaction
	tx := types.NewTransaction(nonce, op.hookAddress, deposit, gasLimit, gasPrice, data)

	// Sign transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), op.privateKey)
	if err != nil {
		return fmt.Errorf("failed to sign transaction: %w", err)
	}

	// Send transaction
	err = op.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return fmt.Errorf("failed to send transaction: %w", err)
	}

	log.Printf("  Transaction hash: %s", signedTx.Hash().Hex())

	// Wait for confirmation
	receipt, err := bind.WaitMined(ctx, op.client, signedTx)
	if err != nil {
		return fmt.Errorf("failed to wait for transaction: %w", err)
	}

	if receipt.Status != types.ReceiptStatusSuccessful {
		return fmt.Errorf("transaction failed with status %d", receipt.Status)
	}

	return nil
}

func (op *Operator) setSwapFee(ctx context.Context, newFee *big.Int) error {
	// Pack the transaction data
	data, err := op.hookABI.Pack("setSwapFee", op.poolKey, newFee)
	if err != nil {
		return fmt.Errorf("failed to pack setSwapFee: %w", err)
	}

	// Get nonce
	nonce, err := op.client.PendingNonceAt(ctx, op.address)
	if err != nil {
		return fmt.Errorf("failed to get nonce: %w", err)
	}

	// Get gas price
	gasPrice, err := op.client.SuggestGasPrice(ctx)
	if err != nil {
		return fmt.Errorf("failed to get gas price: %w", err)
	}

	// Get chain ID
	chainID, err := op.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Estimate gas
	gasLimit, err := op.client.EstimateGas(ctx, ethereum.CallMsg{
		From: op.address,
		To:   &op.hookAddress,
		Data: data,
	})
	if err != nil {
		return fmt.Errorf("failed to estimate gas: %w", err)
	}

	// Create transaction
	tx := types.NewTransaction(nonce, op.hookAddress, big.NewInt(0), gasLimit, gasPrice, data)

	// Sign transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), op.privateKey)
	if err != nil {
		return fmt.Errorf("failed to sign transaction: %w", err)
	}

	// Send transaction
	err = op.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return fmt.Errorf("failed to send transaction: %w", err)
	}

	log.Printf("  Transaction hash: %s", signedTx.Hash().Hex())

	return nil
}

// Helper: Estimate expected profit from pool management
func (op *Operator) estimateProfit() *big.Int {
	// TODO: Implement actual profit estimation
	// This would:
	// - Query recent swap volume
	// - Analyze price volatility
	// - Calculate expected swap fees
	// - Estimate arbitrage opportunities
	// - Return total expected profit per block

	// Placeholder: return 0.002 ETH per block
	return big.NewInt(2e15)
}

// Helper: Calculate optimal swap fee based on market conditions
func (op *Operator) calculateOptimalFee() *big.Int {
	// TODO: Implement actual fee calculation
	// Higher volatility = higher fee
	// Higher volume = lower fee

	// Placeholder: return 0.3% (3000 in hundredths of bps)
	return big.NewInt(3000)
}

func shouldUpdateFee(currentFee, optimalFee *big.Int) bool {
	// Update if difference is > 0.1% (100 in hundredths of bps)
	threshold := big.NewInt(100)

	diff := new(big.Int).Sub(currentFee, optimalFee)
	diff.Abs(diff)

	return diff.Cmp(threshold) > 0
}

func truncateAddress(addr string) string {
	if len(addr) > 10 {
		return addr[:6] + "..." + addr[len(addr)-4:]
	}
	return addr
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
