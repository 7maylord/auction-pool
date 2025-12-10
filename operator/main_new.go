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

	"auction-pool/operator/contracts"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Improved autonomous operator using generated contract bindings
type Operator struct {
	client      *ethclient.Client
	privateKey  *ecdsa.PrivateKey
	address     common.Address
	hookAddress common.Address
	poolId      [32]byte
	poolKey     contracts.PoolKey

	// Contract bindings
	hook *contracts.AuctionPoolHook

	// Strategy parameters
	profitMargin float64  // Percentage of expected profit to bid
	minProfit    *big.Int // Minimum profit threshold in wei
}

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

	// Create contract instance
	hookAddr := common.HexToAddress(hookAddress)
	hook, err := contracts.NewAuctionPoolHook(hookAddr, client)
	if err != nil {
		log.Fatalf("Failed to create hook binding: %v", err)
	}

	// Parse pool key from environment
	poolKey := contracts.PoolKey{
		Currency0:   common.HexToAddress(getEnvOrDefault("TOKEN0", "0x0000000000000000000000000000000000000000")),
		Currency1:   common.HexToAddress(getEnvOrDefault("TOKEN1", "0x0000000000000000000000000000000000000000")),
		Fee:         big.NewInt(3000),
		TickSpacing: big.NewInt(60),
		Hooks:       hookAddr,
	}

	operator := &Operator{
		client:       client,
		privateKey:   privateKey,
		address:      address,
		hookAddress:  hookAddr,
		poolId:       poolId,
		poolKey:      poolKey,
		hook:         hook,
		profitMargin: 0.8,              // Bid 80% of expected profit
		minProfit:    big.NewInt(1e15), // 0.001 ETH minimum
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

	// Query current pool state using generated bindings
	state, err := op.hook.PoolAuctions(&bind.CallOpts{Context: ctx}, op.poolId)
	if err != nil {
		log.Printf("Error getting pool state: %v", err)
		return
	}

	// Query next pending bid using generated bindings
	nextBid, err := op.hook.NextBid(&bind.CallOpts{Context: ctx}, op.poolId)
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
		log.Printf("  ✅ Profitable opportunity detected!")
		log.Printf("    Expected profit: %s wei/block", expectedProfit.String())
		log.Printf("    Profitable rent: %s wei/block", profitableRent.String())
		log.Printf("    Required bid:    %s wei/block", requiredBid.String())

		// Submit bid
		err := op.submitBid(ctx, profitableRent)
		if err != nil {
			log.Printf("  ❌ Failed to submit bid: %v", err)
		} else {
			log.Printf("  ✓ Bid submitted successfully!")
		}
	}

	// If we're the current manager, optimize fees
	if state.CurrentManager == op.address {
		optimalFee := op.calculateOptimalFee()
		if shouldUpdateFee(state.CurrentFee, optimalFee) {
			log.Printf("  🛠️  Updating fee from %s to %s", state.CurrentFee.String(), optimalFee.String())
			err := op.setSwapFee(ctx, optimalFee)
			if err != nil {
				log.Printf("  ❌ Failed to set fee: %v", err)
			} else {
				log.Printf("  ✓ Fee updated successfully!")
			}
		}
	}

	log.Println("")
}

func (op *Operator) submitBid(ctx context.Context, rentPerBlock *big.Int) error {
	// Calculate deposit (rent * 100 blocks minimum)
	deposit := new(big.Int).Mul(rentPerBlock, big.NewInt(100))

	// Get chain ID
	chainID, err := op.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Create transactor
	auth, err := bind.NewKeyedTransactorWithChainID(op.privateKey, chainID)
	if err != nil {
		return fmt.Errorf("failed to create transactor: %w", err)
	}

	// Set transaction value (deposit)
	auth.Value = deposit
	auth.Context = ctx

	// Submit bid using generated binding
	tx, err := op.hook.SubmitBid(auth, op.poolKey, rentPerBlock)
	if err != nil {
		return fmt.Errorf("failed to submit bid: %w", err)
	}

	log.Printf("  Transaction hash: %s", tx.Hash().Hex())

	// Wait for confirmation
	receipt, err := bind.WaitMined(ctx, op.client, tx)
	if err != nil {
		return fmt.Errorf("failed to wait for transaction: %w", err)
	}

	if receipt.Status != types.ReceiptStatusSuccessful {
		return fmt.Errorf("transaction failed with status %d", receipt.Status)
	}

	return nil
}

func (op *Operator) setSwapFee(ctx context.Context, newFee *big.Int) error {
	// Get chain ID
	chainID, err := op.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Create transactor
	auth, err := bind.NewKeyedTransactorWithChainID(op.privateKey, chainID)
	if err != nil {
		return fmt.Errorf("failed to create transactor: %w", err)
	}

	auth.Context = ctx

	// Set swap fee using generated binding
	tx, err := op.hook.SetSwapFee(auth, op.poolKey, newFee)
	if err != nil {
		return fmt.Errorf("failed to set swap fee: %w", err)
	}

	log.Printf("  Transaction hash: %s", tx.Hash().Hex())

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
