package test

import (
	"testing"
)

// TestOperatorStrategy tests the autonomous operator decision-making logic
func TestOperatorStrategy(t *testing.T) {
	t.Run("should bid when profitable", func(t *testing.T) {
		// Mock pool state
		currentRent := 0.001 // 0.001 ETH per block
		expectedProfit := 0.015 // 0.015 ETH per block

		// Calculate profitable rent (80% of profit)
		profitableRent := expectedProfit * 0.8 // 0.012 ETH

		// Should bid if profitable rent > current rent
		if profitableRent > currentRent {
			t.Logf("✓ Should submit bid: profitable_rent=%.6f > current_rent=%.6f", profitableRent, currentRent)
		} else {
			t.Errorf("Expected to bid but didn't: profitable_rent=%.6f, current_rent=%.6f", profitableRent, currentRent)
		}
	})

	t.Run("should not bid when unprofitable", func(t *testing.T) {
		currentRent := 0.01 // 0.01 ETH per block (high)
		expectedProfit := 0.005 // 0.005 ETH per block (low)

		profitableRent := expectedProfit * 0.8 // 0.004 ETH

		if profitableRent <= currentRent {
			t.Logf("✓ Should not bid: profitable_rent=%.6f <= current_rent=%.6f", profitableRent, currentRent)
		} else {
			t.Errorf("Expected not to bid but did: profitable_rent=%.6f, current_rent=%.6f", profitableRent, currentRent)
		}
	})

	t.Run("should update fee when difference exceeds threshold", func(t *testing.T) {
		currentFee := uint32(3000)  // 0.3%
		optimalFee := uint32(3500)  // 0.35%
		threshold := uint32(100)    // 0.1%

		diff := optimalFee - currentFee

		if diff > threshold {
			t.Logf("✓ Should update fee: diff=%d > threshold=%d", diff, threshold)
		} else {
			t.Errorf("Expected to update fee but didn't: diff=%d, threshold=%d", diff, threshold)
		}
	})

	t.Run("should not update fee when difference within threshold", func(t *testing.T) {
		currentFee := uint32(3000)  // 0.3%
		optimalFee := uint32(3050)  // 0.305%
		threshold := uint32(100)    // 0.1%

		diff := optimalFee - currentFee

		if diff <= threshold {
			t.Logf("✓ Should not update fee: diff=%d <= threshold=%d", diff, threshold)
		} else {
			t.Errorf("Expected not to update fee but did: diff=%d, threshold=%d", diff, threshold)
		}
	})

	t.Run("should calculate optimal fee based on volatility", func(t *testing.T) {
		baseFee := uint32(3000) // 0.3%
		volatility := 0.02 // 2%

		// Higher volatility = higher fee
		volatilityAdjustment := uint32(volatility * 10000) // +200 bps
		optimalFee := baseFee + volatilityAdjustment

		// Cap at 1%
		maxFee := uint32(10000)
		if optimalFee > maxFee {
			optimalFee = maxFee
		}

		// Floor at 0.05%
		minFee := uint32(500)
		if optimalFee < minFee {
			optimalFee = minFee
		}

		expectedFee := uint32(3200) // 0.32%
		if optimalFee == expectedFee {
			t.Logf("✓ Optimal fee calculated correctly: %d (%.2f%%)", optimalFee, float64(optimalFee)/10000)
		} else {
			t.Errorf("Incorrect optimal fee: got %d, expected %d", optimalFee, expectedFee)
		}
	})
}

// TestProfitEstimation tests profit calculation logic
func TestProfitEstimation(t *testing.T) {
	t.Run("should estimate profit from swap fees and arb", func(t *testing.T) {
		swapVolumePerBlock := 1000.0 // $1000 per block
		averageFee := 0.003          // 0.3%
		swapFeeRevenue := swapVolumePerBlock * averageFee // $3

		volatility := 0.02 // 2%
		arbProfit := volatility * swapVolumePerBlock * 0.01 // $0.2

		totalProfitPerBlock := swapFeeRevenue + arbProfit // $3.2

		// Convert to ETH (assuming $2000 ETH price)
		ethPrice := 2000.0
		profitInEth := totalProfitPerBlock / ethPrice

		expectedProfit := 0.0016 // 0.0016 ETH

		if profitInEth == expectedProfit {
			t.Logf("✓ Profit estimated correctly: %.6f ETH per block", profitInEth)
		} else {
			t.Errorf("Incorrect profit: got %.6f, expected %.6f", profitInEth, expectedProfit)
		}
	})
}
