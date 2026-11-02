import 'package:deubanda_app/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'register_page.dart';
import 'profile_page.dart';
import 'home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'estudio_form_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _processarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final sucesso = await authViewModel.fazerLogin(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (sucesso) {
      final user = Supabase.instance.client.auth.currentUser;
      final tipoPerfil = user?.userMetadata?['tipo_perfil'] ?? 'Músico';

      if (tipoPerfil == 'Dono de Estúdio') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EstudioFormView(donoId: user!.id),
          ),
        );
      } else {
        await Provider.of<ProfileViewModel>(
          context,
          listen: false,
        ).carregarPerfil();
        final temPerfil = await authViewModel.verificarPerfilExistente();

        if (!mounted) return;

        if (temPerfil) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bem-vindo! Por favor, complete seu perfil para continuar.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Erro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o estado de carregamento do ViewModel
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'DeuBanda',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Conectando músicos independentes'),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Insira seu e-mail'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Insira sua senha'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _processarLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        ),
                        child: const Text('Ainda não tem conta? Cadastre-se'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
