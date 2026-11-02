import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _aceitouTermosLGPD = false;
  String _tipoPerfilSelecionado = 'Músico';

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira uma senha.';
    }
    if (value.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }
    if (!value.contains(RegExp(r'[A-Za-z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return 'A senha deve conter letras e números.';
    }
    return null;
  }

  Future<void> _processarCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceitouTermosLGPD) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você precisa aceitar os termos da LGPD para continuar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final sucesso = await authViewModel.realizarCadastro(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _tipoPerfilSelecionado,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastro realizado com sucesso! Faça login para continuar.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Erro ao cadastrar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                        Icons.person_add,
                        size: 64,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Junte-se ao DeuBanda',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe seu nome completo'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Informe um e-mail válido'
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
                          helperText:
                              'Mínimo de 8 caracteres (letras e números)',
                        ),
                        validator: _validarSenha,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _tipoPerfilSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Conta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_box),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Músico',
                            child: Text('Sou Músico (Buscar Bandas/Estúdios)'),
                          ),
                          DropdownMenuItem(
                            value: 'Dono de Estúdio',
                            child: Text('Sou Dono de Estúdio (Alugar Salas)'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tipoPerfilSelecionado = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _aceitouTermosLGPD,
                        onChanged: (val) =>
                            setState(() => _aceitouTermosLGPD = val ?? false),
                        title: const Text(
                          'Li e aceito os termos de privacidade conforme a LGPD.',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.deepPurple,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _processarCadastro,
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
                                  'Cadastrar',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
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
