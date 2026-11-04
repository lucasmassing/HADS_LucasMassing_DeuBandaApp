import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estudio_model.dart';
import '../models/sala_model.dart';
import '../models/reserva_model.dart';

class EstudioViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  EstudioModel? meuEstudio;
  List<SalaModel> minhasSalas = [];
  List<ReservaModel> reservas = [];

  bool isLoading = false;
  String? errorMessage;

  // Carregar dados completos do Estúdio do usuário logado
  Future<void> carregarPainelEstudio(String donoId) async {
    _setLoading(true);
    try {
      final estudioData = await _supabase
          .from('estudios')
          .select()
          .eq('dono_id', donoId)
          .maybeSingle();

      if (estudioData != null) {
        meuEstudio = EstudioModel.fromJson(estudioData);
        await carregarSalas(meuEstudio!.id);
        await carregarReservas(meuEstudio!.id);
      }
    } catch (e) {
      errorMessage = 'Erro ao carregar estúdio: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Salvar ou Atualizar Estúdio
  Future<bool> salvarEstudio(EstudioModel estudio) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('estudios')
          .upsert(estudio.toJson())
          .select()
          .single();

      meuEstudio = EstudioModel.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Erro ao salvar estúdio: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Carregar e Adicionar Salas
  Future<void> carregarSalas(String estudioId) async {
    final salasData = await _supabase
        .from('salas')
        .select()
        .eq('estudio_id', estudioId)
        .eq('is_ativo', true);

    minhasSalas = salasData.map((s) => SalaModel.fromJson(s)).toList();
    notifyListeners();
  }

  Future<bool> salvarSala(SalaModel sala) async {
    try {
      await _supabase.from('salas').upsert(sala.toJson());
      await carregarSalas(sala.estudioId);
      return true;
    } catch (e) {
      errorMessage = 'Erro ao salvar sala: $e';
      return false;
    }
  }

  //Inativar Sala e Cancelar Reservas Pendentes
  Future<bool> inativarSala(String salaId) async {
    try {
      // Atualiza a sala para inativa
      await _supabase
          .from('salas')
          .update({'is_ativo': false})
          .eq('sala_id', salaId);

      await _supabase
          .from('reservas')
          .update({'status': 'CANCELADO'})
          .eq('sala_id', salaId)
          .eq('status', 'PENDENTE');

      if (meuEstudio != null) {
        await carregarSalas(meuEstudio!.id);
        await carregarReservas(meuEstudio!.id);
      }
      return true;
    } catch (e) {
      errorMessage = 'Erro ao inativar sala: $e';
      return false;
    }
  }

  // Carregar Reservas e Responder
  Future<void> carregarReservas(String estudioId) async {
    final salasIds = minhasSalas.map((s) => s.id).toList();
    if (salasIds.isEmpty) return;

    final reservasData = await _supabase
        .from('reservas')
        .select()
        .inFilter('sala_id', salasIds)
        .order('data_reserva', ascending: true);

    reservas = reservasData.map((r) => ReservaModel.fromJson(r)).toList();
    notifyListeners();
  }

  Future<bool> responderReserva(String reservaId, String novoStatus) async {
    try {
      await _supabase
          .from('reservas')
          .update({'status': novoStatus})
          .eq('reserva_id', reservaId);

      final reservaData = await _supabase
          .from('reservas')
          .select('musico_id')
          .eq('reserva_id', reservaId)
          .maybeSingle();

      if (reservaData != null && reservaData['musico_id'] != null) {
        final musicoId = reservaData['musico_id'];
        final mensagem = novoStatus == 'ACEITO'
            ? 'Sua reserva no estúdio ${meuEstudio!.nome} foi APROVADA!'
            : 'Sua reserva no estúdio ${meuEstudio!.nome} foi RECUSADA.';

        final telefone = novoStatus == 'ACEITO' ? meuEstudio!.telefone : null;

        await _supabase.from('notificacoes').insert({
          'perfil_id': musicoId,
          'mensagem': mensagem,
          'telefone_contato': telefone,
        });
      }

      if (meuEstudio != null) await carregarReservas(meuEstudio!.id);
      return true;
    } catch (e) {
      errorMessage = 'Erro ao responder reserva: $e';
      return false;
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
