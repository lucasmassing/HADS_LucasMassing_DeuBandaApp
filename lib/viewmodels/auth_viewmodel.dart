import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase;

  AuthViewModel({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Avisa a View para reconstruir a tela
  }

  // Retorna true se o login for bem-sucedido
  Future<bool> fazerLogin(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao fazer login.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> realizarCadastro(
    String name,
    String email,
    String password,
    String tipoPerfil,
  ) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'tipo_perfil': tipoPerfil},
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao cadastrar.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verifica se o usuário logado já possui um perfil salvo no banco
  Future<bool> verificarPerfilExistente() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('perfis_musicos')
          .select('perfil_id')
          .eq('perfil_id', user.id)
          .maybeSingle();

      return data != null; // Se for diferente de null, o perfil já existe
    } catch (e) {
      return false;
    }
  }
}
