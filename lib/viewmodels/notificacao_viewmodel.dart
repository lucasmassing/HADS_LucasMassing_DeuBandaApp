import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacaoViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _notificacoes = [];
  List<Map<String, dynamic>> get notificacoes => _notificacoes;

  int get notificacoesNaoLidas =>
      _notificacoes.where((n) => n['lida'] == false).length;

  NotificacaoViewModel() {
    carregarNotificacoes();
  }

  Future<void> carregarNotificacoes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('notificacoes')
          .select()
          .eq('perfil_id', userId)
          .order('data_criacao', ascending: false);

      _notificacoes = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    }
  }

  Future<void> marcarNotificacaoComoLida(String id) async {
    try {
      await _supabase.from('notificacoes').update({'lida': true}).eq('id', id);
      await carregarNotificacoes();
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }

  Future<void> enviarNotificacao({
    required String perfilId,
    required String mensagem,
    String? telefoneContato,
  }) async {
    try {
      await _supabase.from('notificacoes').insert({
        'perfil_id': perfilId,
        'mensagem': mensagem,
        'telefone_contato': telefoneContato,
      });
      if (perfilId == _supabase.auth.currentUser?.id) {
        carregarNotificacoes();
      }
    } catch (e) {
      debugPrint('Erro ao criar notificação global: $e');
    }
  }
}
