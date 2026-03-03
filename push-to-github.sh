#!/bin/bash
set -e
cd /tmp/kilocode.nvim

echo "🔧 Configurando git..."
git config user.email "daddydiaz2@gmail.com"
git config user.name "Daniel Diaz"

if ! git remote get-url origin 2>/dev/null; then
    git remote add origin git@github.com:daddydiaz2/kilocode.nvim.git
fi

echo "📤 Subiendo main..."
git checkout main
git push -u origin main

echo "📤 Subiendo dev..."
git checkout dev
git push -u origin dev

echo "✅ ¡Listo! Verifica en: https://github.com/daddydiaz2/kilocode.nvim"
