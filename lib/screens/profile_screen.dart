import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.userName ?? '');
    _emailController = TextEditingController(text: authProvider.userEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                tooltip: 'Sair',
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: AppTheme.textPrimary)
                      : null,
                  backgroundColor: AppTheme.accentCyan,
                ),
                const SizedBox(height: 24),

                // Informações do usuário
                Card(
                  color: AppTheme.cardBackground,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Pessoais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nome
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome de Exibição',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nome é obrigatório';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email (somente leitura)
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          // UID (somente leitura)
                          TextFormField(
                            initialValue: user?.uid ?? '',
                            decoration: const InputDecoration(
                              labelText: 'ID do Usuário',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.fingerprint),
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                          const SizedBox(height: 24),

                          // Botão Salvar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentCyan,
                                foregroundColor: AppTheme.textPrimary,
                                elevation: 6,
                                shadowColor: AppTheme.accentCyan.withAlpha(89),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Salvar Alterações'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Informações da conta
                Card(
                  color: AppTheme.cardBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações da Conta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Provedor', 'Google'),
                        _buildInfoRow(
                            'Conta criada em',
                            user?.metadata.creationTime != null
                                ? _formatDate(user!.metadata.creationTime!)
                                : 'N/A'),
                        _buildInfoRow(
                            'Último login',
                            user?.metadata.lastSignInTime != null
                                ? _formatDate(user!.metadata.lastSignInTime!)
                                : 'N/A'),
                        _buildInfoRow(
                            'Email verificado', user?.emailVerified == true ? 'Sim' : 'Não'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão de sincronização
                Card(
                  color: AppTheme.cardBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sincronização',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seus dados são automaticamente sincronizados com a nuvem quando você joga.',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _syncData,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sincronizar Agora'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.accentCyan, width: 1.5),
                              foregroundColor: AppTheme.accentCyan,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      } else {
        throw Exception('Falha ao atualizar perfil');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncData() async {
    // Aqui você pode implementar a sincronização manual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronização concluída!'),
        backgroundColor: AppTheme.accentCyan,
      ),
    );
  }
}
