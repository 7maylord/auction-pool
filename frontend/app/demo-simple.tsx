'use client';
import { useState, useEffect } from 'react';

export default function DemoSimple() {
  const [rent, setRent] = useState(0.087);
  const [earnings, setEarnings] = useState(0.045);
  const [blocks, setBlocks] = useState(3);
  
  useEffect(() => {
    const t = setInterval(() => {
      setEarnings(p => p + 0.00001);
      if (blocks > 0) setBlocks(p => p - 1);
    }, 1000);
    return () => clearInterval(t);
  }, [blocks]);

  return (
    <div className="min-h-screen bg-slate-900 p-8">
      <h1 className="text-4xl font-bold text-white mb-8">🏆 AuctionPool Live Demo</h1>
      <div className="grid gap-6">
        <div className="bg-slate-800 rounded-lg p-6">
          <h2 className="text-2xl text-white mb-4">🎯 Auction Competition</h2>
          <div className="space-y-3">
            <div className="bg-yellow-900/30 p-4 rounded">
              <div className="flex justify-between">
                <span className="text-white font-bold">Operator B - Next Manager</span>
                <span className="text-white">0.095 ETH/block</span>
              </div>
              <div className="mt-2 text-yellow-400 text-sm">
                Activates in {blocks} blocks
              </div>
            </div>
            <div className="bg-green-900/30 p-4 rounded">
              <div className="flex justify-between">
                <span className="text-white font-bold">Operator A - Current</span>
                <span className="text-white">{rent.toFixed(3)} ETH/block</span>
              </div>
            </div>
          </div>
        </div>
        <div className="bg-slate-800 rounded-lg p-6">
          <h2 className="text-2xl text-white mb-4">💎 Your LP Position</h2>
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-slate-700 p-4 rounded">
              <div className="text-slate-400 text-sm">Claimable Rent</div>
              <div className="text-2xl text-green-400 font-bold">{earnings.toFixed(5)} ETH</div>
              <button className="mt-2 w-full bg-green-600 text-white py-2 rounded">Claim</button>
            </div>
            <div className="bg-slate-700 p-4 rounded">
              <div className="text-slate-400 text-sm">Total Earned</div>
              <div className="text-2xl text-white font-bold">2.34 ETH</div>
              <div className="text-green-400 text-sm">+60% vs Fixed Fee</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
