import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _musicosFeed = [];
  List<Map<String, dynamic>> get musicosFeed => _musicosFeed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MatchingViewModel() {
    carregarFeed();
  }

  // Função auxiliar para converter o texto do nível em número (1 a 4)
  double _calcularMediaNivel(List instrumentos) {
    if (instrumentos.isEmpty) return 0;
    const mapaNiveis = {
      'Iniciante': 1,
      'Intermediário': 2,
      'Avançado': 3,
      'Profissional': 4,
    };
    int soma = 0;
    for (var inst in instrumentos) {
      soma += mapaNiveis[inst['instrumento_nivel']] ?? 1;
    }
    return soma / instrumentos.length;
  }

  Future<void> carregarFeed() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Busca os dados COMPLETOS do utilizador logado
      final meuPerfilReq = await _supabase
          .from('perfis_musicos')
          .select('''
            perfil_cidade,
            perfil_objetivo,
            musico_instrumentos (instrumento_nivel),
            musico_generos (genero_id),
            disponibilidade_semanal (dia_semana, turno)
          ''')
          .eq('perfil_id', userId)
          .maybeSingle();

      if (meuPerfilReq == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final minhaCidade = meuPerfilReq['perfil_cidade'];
      final meuObjetivo = meuPerfilReq['perfil_objetivo'];
      final minhaMediaTecnica = _calcularMediaNivel(
        meuPerfilReq['musico_instrumentos'] ?? [],
      );

      Set<int> meusGeneros = (meuPerfilReq['musico_generos'] as List)
          .map<int>((g) => g['genero_id'] as int)
          .toSet();

      Set<String> minhaDisp = (meuPerfilReq['disponibilidade_semanal'] as List)
          .map<String>((d) => '${d['dia_semana']}-${d['turno']}')
          .toSet();

      // 2. Busca todos os outros músicos
      final data = await _supabase
          .from('perfis_musicos')
          .select('''
            perfil_id, 
            perfil_nome, 
            perfil_cidade, 
            perfil_bio, 
            perfil_objetivo,
            musico_instrumentos (
              instrumento_nivel, 
              instrumentos(instrumento_nome)
            ),
            musico_generos (genero_id),
            disponibilidade_semanal (dia_semana, turno)
          ''')
          .neq('perfil_id', userId);

      List<Map<String, dynamic>> listaMusicos = List<Map<String, dynamic>>.from(
        data,
      );

      // 3. Motor de Cálculo de Afinidade (4 Dimensões)
      for (var musico in listaMusicos) {
        int scoreArtistico = 0;
        int scoreLogistico = 0;
        int scoreComportamental = 0;
        int scoreTecnico = 0;

        // Dimensão 1: Artística (Máx 30%) - Gêneros em comum
        List generosOutro = musico['musico_generos'] ?? [];
        Set<int> idsOutro = generosOutro
            .map<int>((g) => g['genero_id'] as int)
            .toSet();
        if (meusGeneros.isNotEmpty && idsOutro.isNotEmpty) {
          int emComum = meusGeneros.intersection(idsOutro).length;
          scoreArtistico = ((emComum / meusGeneros.length) * 30)
              .clamp(0, 30)
              .toInt();
        }

        // Dimensão 2: Logística (Máx 30%) - 15% Horários + 15% Cidade
        List dispOutro = musico['disponibilidade_semanal'] ?? [];
        Set<String> turnosOutro = dispOutro
            .map<String>((d) => '${d['dia_semana']}-${d['turno']}')
            .toSet();
        if (minhaDisp.isNotEmpty && turnosOutro.isNotEmpty) {
          int emComum = minhaDisp.intersection(turnosOutro).length;
          scoreLogistico += ((emComum / minhaDisp.length) * 15)
              .clamp(0, 15)
              .toInt();
        }
        if (minhaCidade != null &&
            musico['perfil_cidade'] != null &&
            minhaCidade.toString().trim().toLowerCase() ==
                musico['perfil_cidade'].toString().trim().toLowerCase()) {
          scoreLogistico += 15;
        }

        // Dimensão 3: Comportamental (Máx 20%) - Objetivo igual
        if (meuObjetivo != null &&
            musico['perfil_objetivo'] != null &&
            meuObjetivo.toString().isNotEmpty) {
          if (meuObjetivo.toString().trim().toLowerCase() ==
              musico['perfil_objetivo'].toString().trim().toLowerCase()) {
            scoreComportamental = 20;
          }
        }

        // Dimensão 4: Técnica (Máx 20%) - Proximidade do nível de proficiência
        double mediaTecnicaOutro = _calcularMediaNivel(
          musico['musico_instrumentos'] ?? [],
        );
        if (minhaMediaTecnica > 0 && mediaTecnicaOutro > 0) {
          double diferenca = (minhaMediaTecnica - mediaTecnicaOutro).abs();
          if (diferenca <= 0.5) {
            scoreTecnico = 20; // Níveis iguais ou quase iguais
          } else if (diferenca <= 1.5) {
            scoreTecnico = 10; // Diferença aceitável de 1 nível
          } else {
            scoreTecnico =
                0; // Diferença muito grande (ex: Iniciante vs Profissional)
          }
        }

        // Soma e guarda o score final (Máx 100)
        musico['match_score'] =
            scoreArtistico +
            scoreLogistico +
            scoreComportamental +
            scoreTecnico;
      }

      // 4. Ordena do maior match para o menor
      listaMusicos.sort(
        (a, b) => (b['match_score'] as int).compareTo(a['match_score'] as int),
      );

      _musicosFeed = listaMusicos;
    } catch (e) {
      debugPrint('Erro ao carregar feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enviarMatch(String musicoDestinoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final existente = await _supabase
          .from('matchings')
          .select()
          .eq('musico_origem_id', userId)
          .eq('musico_destino_id', musicoDestinoId)
          .maybeSingle();

      if (existente != null) return false;

      await _supabase.from('matchings').insert({
        'musico_origem_id': userId,
        'musico_destino_id': musicoDestinoId,
        'match_status': 'PENDENTE',
      });

      _musicosFeed.removeWhere((m) => m['perfil_id'] == musicoDestinoId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erro ao enviar match: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _pedidosRecebidos = [];
  List<Map<String, dynamic>> get pedidosRecebidos => _pedidosRecebidos;

  Future<void> carregarPedidosRecebidos() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('matchings')
          .select('''
            match_id,
            match_status,
            perfis_musicos!matchings_musico_origem_id_fkey (
              perfil_nome,
              perfil_cidade,
              perfil_bio
            )
          ''')
          .eq('musico_destino_id', userId)
          .eq('match_status', 'PENDENTE');

      _pedidosRecebidos = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar pedidos de conexão: $e');
    }
  }

  Future<bool> responderPedido(String matchId, String novoStatus) async {
    try {
      await _supabase
          .from('matchings')
          .update({'match_status': novoStatus})
          .eq('match_id', matchId);

      _pedidosRecebidos.removeWhere((p) => p['match_id'] == matchId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao responder pedido: $e');
      return false;
    }
  }
}
