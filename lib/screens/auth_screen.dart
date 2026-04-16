import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title
              Icon(
                Icons.games,
                size: 80,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(height: 24),
              const Text(
                'Hub Smart Games',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Jogue Snake e Torre de Hanói\nSalve seu progresso na nuvem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Login Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final success = await authProvider.signInWithGoogle();
                              if (success && mounted) {
                                // Navegação será feita automaticamente pelo HomeScreen
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao fazer login. Tente novamente.'),
                                  ),
                                );
                              }
                            },
                      icon: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        authProvider.isLoading ? 'Entrando...' : 'Entrar com Google',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: AppTheme.accentCyan.withAlpha(89),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Features
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withAlpha(20),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.cloud_upload,
                      'Progresso na nuvem',
                      'Seus scores e progresso são salvos automaticamente',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.leaderboard,
                      'Rankings globais',
                      'Compare seu desempenho com jogadores do mundo todo',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.games,
                      'Dois jogos clássicos',
                      'Snake e Torre de Hanói com mecânicas únicas',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentPurple, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
