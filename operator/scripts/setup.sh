#!/bin/bash

# AVS Operator Setup Script

echo "=================================="
echo "AuctionPool AVS Operator Setup"
echo "=================================="
echo ""

# Check Node.js version
echo "Checking Node.js version..."
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)

if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Error: Node.js 18 or higher is required"
    echo "   Current version: $(node -v)"
    echo "   Please upgrade: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"
echo ""

# Install dependencies
echo "Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file with your configuration:"
    echo "   - RPC_URL"
    echo "   - OPERATOR_PRIVATE_KEY"
    echo "   - POOL_MANAGER_ADDRESS"
    echo "   - HOOK_ADDRESS"
    echo ""
else
    echo "✅ .env file already exists"
    echo ""
fi

# Create logs directory
mkdir -p logs
echo "✅ Logs directory created"
echo ""

# Build project
echo "Building TypeScript project..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

# Summary
echo "=================================="
echo "Setup Complete! 🎉"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Fund operator address with ETH"
echo "3. Run in development mode:"
echo "   npm run dev"
echo ""
echo "Or run in production mode:"
echo "   npm start"
echo ""
echo "View logs:"
echo "   tail -f logs/operator.log"
echo ""
echo "For more information, see README.md"
echo ""
