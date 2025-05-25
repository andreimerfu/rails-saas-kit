#!/bin/bash

echo "🚀 Starting Rails 8 SaaS Starter Demo"
echo "======================================"
echo ""
echo "📦 Installing dependencies..."
bundle install

echo ""
echo "🗄️  Setting up database..."
bin/rails db:prepare

echo ""
echo "🌱 Seeding database..."
bin/rails db:seed

echo ""
echo "🎨 Precompiling assets..."
bin/rails assets:precompile

echo ""
echo "🏃‍♂️ Starting development server..."
echo "Visit: http://localhost:3000"
echo "Press Ctrl+C to stop"
echo ""

bin/dev