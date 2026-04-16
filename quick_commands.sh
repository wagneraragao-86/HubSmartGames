#!/bin/bash

# Hub Smart Games - Quick Commands
# Execute os comandos abaixo conforme necessário

# ============================================
# SETUP INICIAL
# ============================================

# Instalar dependências
flutter pub get

# Verificar environment
flutter doctor

# ============================================
# DEVELOPMENT
# ============================================

# Debug (hot reload)
flutter run -v

# Release
flutter run --release

# Analisar código
flutter analyze

# Limpar cache
flutter clean

# ============================================
# BUILD & DISTRIBUTION
# ============================================

# Build APK (Android)
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build IPA (iOS)
flutter build ios --release

# ============================================
# TESTES
# ============================================

# Rodar testes unitários
flutter test

# Com coverage
flutter test --coverage

# ============================================
# DEBUGGING
# ============================================

# Ativar DevTools
flutter pub global activate devtools
devtools

# Ver logs em tempo real
flutter logs

# App logs específico
adb logcat | grep flutter

# ============================================
# GERENCIAMENTO
# ============================================

# Atualizar dependências
flutter pub upgrade

# Verificar dependências desatualizadas
flutter pub outdated

# ============================================
# DEVICE MANAGEMENT
# ============================================

# Listar dispositivos
flutter devices

# Executar em dispositivo específico
flutter run -d <device_id>

# ============================================
# VARIAÇÕES
# ============================================

# Debug com prints de performance
flutter run --profile

# Desabilitar certificado SSL (desenvolvimento)
flutter run --dart-define=DART_SSL_CERT_INSECURE=true

# ============================================
# TROUBLESHOOTING
# ============================================

# Reiniciar o Flutter system
flutter channel stable
flutter upgrade

# Resetar completo
flutter clean && flutter pub get && flutter run

# ============================================
# DICAS RÁPIDAS
# ============================================

# No emulador/device durante flutter run:
# r         - Hot reload
# R         - Hot restart
# q         - Quit
# w         - Toggle widget inspector
# o         - Toggle overlay
# p         - Toggle performance overlay
# u         - Toggle WidgetBuilder info
# i         - Toggle WidgetBuilder locations
# L         - Dump layer tree
# S         - Dump semantics
# M         - Write SkSL shaders to file
# Z         - Dump SkSL shader info
# t         - Trace widget builds
# P         - Toggle platform channel performance
# a         - Take screenshot
# H         - Show help for hot commands

echo "✅ Hub Smart Games - Development Environment Ready!"
echo "📚 Veja PROJECT_SUMMARY.md para mais detalhes"
