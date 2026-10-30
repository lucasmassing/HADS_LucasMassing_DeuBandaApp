import 'dart:convert';
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

  void _formatarDadosParaVisita(Map<String, dynamic> musico) {
    final refTexto = musico['perfil_artista_referencia'] ?? '';
    List decodedArtistas = [];
    if (refTexto.isNotEmpty) {
      try {
        decodedArtistas = json.decode(refTexto);
      } catch (e) {
        debugPrint('Erro ao decodificar artistas: $e');
      }
    }
    musico['artistas_referencia'] = decodedArtistas;

    // Converte disponibilidade para o formato que a tela espera
    final disp = musico['disponibilidade_semanal'] as List? ?? [];
    musico['musico_horarios'] = disp.map((d) {
      return {'dia_turno': '${d['dia_semana']} - ${d['turno']}'};
    }).toList();
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
            perfil_artista_referencia,
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

      final meusProjetosReq = await _supabase
          .from('projetos')
          .select('projeto_funcao_desejada')
          .eq('criador_id', userId)
          .eq('projeto_status', 'ATIVO');

      Set<String> instrumentosBuscados = {};
      for (var p in (meusProjetosReq as List)) {
        final funcoes = p['projeto_funcao_desejada']?.toString() ?? '';
        if (funcoes.isNotEmpty) {
          final lista = funcoes.split(',').map((e) => e.trim().toLowerCase());
          instrumentosBuscados.addAll(lista);
        }
      }

      final minhaCidade = meuPerfilReq['perfil_cidade'];
      final meuObjetivo = meuPerfilReq['perfil_objetivo'];
      final minhaMediaTecnica = _calcularMediaNivel(
        meuPerfilReq['musico_instrumentos'] ?? [],
      );

      Set<int> meusGeneros = (meuPerfilReq['musico_generos'] as List)
          .map<int>((g) => g['genero_id'] as int)
          .toSet();

      Set<String> minhasBandas = {};
      final refTexto = meuPerfilReq['perfil_artista_referencia'] ?? '';
      if (refTexto.isNotEmpty) {
        try {
          final List decoded = json.decode(refTexto);
          minhasBandas = decoded
              .map<String>((e) => e['name'].toString().toLowerCase().trim())
              .toSet();
        } catch (e) {}
      }

      Set<String> minhaDisp = (meuPerfilReq['disponibilidade_semanal'] as List)
          .map<String>((d) => '${d['dia_semana']}-${d['turno']}')
          .toSet();

      // Busca as conexões já existentes para ocultá-las do feed ---
      final matchingsData = await _supabase
          .from('matchings')
          .select('musico_origem_id, musico_destino_id')
          .or('musico_origem_id.eq.$userId,musico_destino_id.eq.$userId');

      Set<String> idsExcluidos = {};
      for (var match in matchingsData as List) {
        if (match['musico_origem_id'] != userId) {
          idsExcluidos.add(match['musico_origem_id']);
        }
        if (match['musico_destino_id'] != userId) {
          idsExcluidos.add(match['musico_destino_id']);
        }
      }

      // 2. Busca todos os outros músicos
      final data = await _supabase
          .from('perfis_musicos')
          .select('''
            perfil_id, 
            perfil_nome, 
            perfil_cidade, 
            perfil_bio, 
            perfil_telefone,
            perfil_artista_referencia,
            perfil_objetivo,
            musico_instrumentos (
              instrumento_nivel, 
              instrumentos(instrumento_nome)
            ),
            musico_generos (
              genero_id,
              is_prioritario,
              generos_musicais(genero_nome)
            ),
            disponibilidade_semanal (dia_semana, turno)
          ''')
          .neq('perfil_id', userId);

      List<Map<String, dynamic>> listaMusicos = List<Map<String, dynamic>>.from(
        data,
      ).where((musico) => !idsExcluidos.contains(musico['perfil_id'])).toList();

      // 3. Motor de Cálculo de Afinidade (4 Dimensões)
      for (var musico in listaMusicos) {
        _formatarDadosParaVisita(musico);
        int scoreArtistico = 0;
        int scoreLogistico = 0;
        int scoreComportamental = 0;
        int scoreTecnico = 0;

        // Dimensão 1: Artística (Máx 30%) - 15% Gêneros + 15% Bandas
        List generosOutro = musico['musico_generos'] ?? [];
        Set<int> idsOutro = generosOutro
            .map<int>((g) => g['genero_id'] as int)
            .toSet();

        if (meusGeneros.isNotEmpty || idsOutro.isNotEmpty) {
          int generosEmComum = meusGeneros.intersection(idsOutro).length;
          int maxGen = meusGeneros.length > idsOutro.length
              ? meusGeneros.length
              : idsOutro.length;
          if (maxGen > 0)
            scoreArtistico += ((generosEmComum / maxGen) * 15).round();
        }

        Set<String> bandasOutro = {};
        final refOutroTexto = musico['perfil_artista_referencia'] ?? '';
        if (refOutroTexto.isNotEmpty) {
          try {
            final List decoded = json.decode(refOutroTexto);
            bandasOutro = decoded
                .map<String>((e) => e['name'].toString().toLowerCase().trim())
                .toSet();
          } catch (e) {}
        }

        if (minhasBandas.isNotEmpty || bandasOutro.isNotEmpty) {
          int bandasEmComum = minhasBandas.intersection(bandasOutro).length;
          int maxBan = minhasBandas.length > bandasOutro.length
              ? minhasBandas.length
              : bandasOutro.length;
          if (maxBan > 0)
            scoreArtistico += ((bandasEmComum / maxBan) * 15).round();
        }

        // Dimensão 2: Logística (Máx 30%) - 15% Horários + 15% Cidade
        List dispOutro = musico['disponibilidade_semanal'] ?? [];
        Set<String> turnosOutro = dispOutro
            .map<String>((d) => '${d['dia_semana']}-${d['turno']}')
            .toSet();

        if (minhaDisp.isNotEmpty || turnosOutro.isNotEmpty) {
          int turnosEmComum = minhaDisp.intersection(turnosOutro).length;
          int maxDisp = minhaDisp.length > turnosOutro.length
              ? minhaDisp.length
              : turnosOutro.length;
          if (maxDisp > 0)
            scoreLogistico += ((turnosEmComum / maxDisp) * 15).round();
        }

        if (minhaCidade != null &&
            musico['perfil_cidade'] != null &&
            minhaCidade.toString().trim().toLowerCase() ==
                musico['perfil_cidade'].toString().trim().toLowerCase()) {
          scoreLogistico += 15;
        }

        // Dimensão 3: Comportamental (Máx 20%) - Objetivos em comum
        Set<String> meusObjs = (meuObjetivo ?? '')
            .toString()
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .toSet();
        Set<String> outrosObjs = (musico['perfil_objetivo'] ?? '')
            .toString()
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .toSet();

        meusObjs.removeWhere((e) => e.isEmpty);
        outrosObjs.removeWhere((e) => e.isEmpty);

        if (meusObjs.isNotEmpty || outrosObjs.isNotEmpty) {
          int objsEmComum = meusObjs.intersection(outrosObjs).length;
          int maxObjs = meusObjs.length > outrosObjs.length
              ? meusObjs.length
              : outrosObjs.length;
          if (maxObjs > 0)
            scoreComportamental = ((objsEmComum / maxObjs) * 20).round();
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

        // Soma e guarda o score final (Máx 100)
        musico['match_score'] =
            scoreArtistico +
            scoreLogistico +
            scoreComportamental +
            scoreTecnico;

        // --- NOVA LÓGICA: Verifica se é Super Match ---
        bool isSuperMatch = false;
        if (musico['match_score'] >= 80 && instrumentosBuscados.isNotEmpty) {
          final instOutro = musico['musico_instrumentos'] as List? ?? [];
          for (var inst in instOutro) {
            final nomeInst =
                inst['instrumentos']?['instrumento_nome']
                    ?.toString()
                    .toLowerCase()
                    .trim() ??
                '';
            if (instrumentosBuscados.contains(nomeInst)) {
              isSuperMatch = true;
              break;
            }
          }
        }
        musico['is_super_match'] = isSuperMatch;
      }

      // 4. Ordena: Primeiro os Super Matches, depois do maior match para o menor
      listaMusicos.sort((a, b) {
        if (a['is_super_match'] == true && b['is_super_match'] != true)
          return -1;
        if (b['is_super_match'] == true && a['is_super_match'] != true)
          return 1;
        return (b['match_score'] as int).compareTo(a['match_score'] as int);
      });

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

      final responsePerfil = await _supabase
          .from('perfis_musicos')
          .select('perfil_nome')
          .eq('perfil_id', userId)
          .maybeSingle();

      final meuPerfil = responsePerfil as Map<String, dynamic>?;

      final String meuNome =
          (meuPerfil?['perfil_nome'] as String?) ?? 'Um músico';

      await _supabase.from('notificacoes').insert({
        'perfil_id': musicoDestinoId,
        'mensagem':
            '$meuNome acabou de enviar um pedido de conexão! Verifique a aba de Notificações.',
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

  List<Map<String, dynamic>> _minhasConexoes = [];
  List<Map<String, dynamic>> get minhasConexoes => _minhasConexoes;

  int get quantidadeConvitesPendentes {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    return _minhasConexoes
        .where(
          (c) =>
              c['match_status'] == 'PENDENTE' &&
              c['musico_destino_id'] == userId,
        )
        .length;
  }

  Future<void> carregarMinhasConexoes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('matchings')
          .select('''
            match_id,
            match_status,
            musico_origem_id,
            musico_destino_id,
            origem:perfis_musicos!matchings_musico_origem_id_fkey(
              perfil_id, perfil_nome, perfil_cidade, perfil_bio, perfil_objetivo, perfil_telefone, perfil_artista_referencia,
              musico_instrumentos(instrumento_nivel, instrumentos(instrumento_nome)),
              musico_generos(genero_id, is_prioritario, generos_musicais(genero_nome)),
              disponibilidade_semanal(dia_semana, turno)
            ),
            destino:perfis_musicos!matchings_musico_destino_id_fkey(
              perfil_id, perfil_nome, perfil_cidade, perfil_bio, perfil_objetivo, perfil_telefone, perfil_artista_referencia,
              musico_instrumentos(instrumento_nivel, instrumentos(instrumento_nome)),
              musico_generos(genero_id, is_prioritario, generos_musicais(genero_nome)),
              disponibilidade_semanal(dia_semana, turno)
            )
          ''')
          .or('musico_origem_id.eq.$userId,musico_destino_id.eq.$userId');

      final listConexoes = List<Map<String, dynamic>>.from(data);
      
      for (var conexao in listConexoes) {
        if (conexao['origem'] != null) {
          _formatarDadosParaVisita(conexao['origem'] as Map<String, dynamic>);
        }
        if (conexao['destino'] != null) {
          _formatarDadosParaVisita(conexao['destino'] as Map<String, dynamic>);
        }
      }

      _minhasConexoes = listConexoes;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar minhas conexões: $e');
    }
  }

  Future<bool> responderPedido(
    String matchId,
    String novoStatus,
    String musicoOrigemId,
  ) async {
    final meuId = _supabase.auth.currentUser?.id;
    try {
      await _supabase
          .from('matchings')
          .update({'match_status': novoStatus})
          .eq('match_id', matchId);

      if (meuId != null) {
        final responsePerfil = await _supabase
            .from('perfis_musicos')
            .select('perfil_nome, perfil_telefone')
            .eq('perfil_id', meuId)
            .maybeSingle();

        final meuPerfil = responsePerfil as Map<String, dynamic>?;

        final String meuNome =
            (meuPerfil?['perfil_nome'] as String?) ?? 'Um músico';

        final String? meuTelefone = (novoStatus == 'ACEITO')
            ? (meuPerfil?['perfil_telefone'] as String?)
            : null;

        final String mensagem = (novoStatus == 'ACEITO')
            ? '$meuNome ACEITOU o seu pedido de conexão musical! Entre em contato.'
            : '$meuNome RECUSOU o seu pedido de conexão.';

        await _supabase.from('notificacoes').insert({
          'perfil_id': musicoOrigemId,
          'mensagem': mensagem,
          'telefone_contato': meuTelefone,
        });
      }

      notifyListeners();
      carregarMinhasConexoes();
      return true;
    } catch (e) {
      debugPrint('Erro ao responder pedido: $e');
      return false;
    }
  }
}
