import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/projeto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/instrumento.dart';

class ProjetoViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Projeto> _projetosAtivos = [];
  List<Projeto> get projetosAtivos => _projetosAtivos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProjetoViewModel() {
    carregarProjetos();
    carregarMinhasInscricoes();
    carregarCidadesIbge();
    carregarInstrumentos();
  }

  // API do IBGE
  List<String> _todasCidades = [];
  List<String> get todasCidades => _todasCidades;

  String? _cidadeSelecionada;
  String? get cidadeSelecionada => _cidadeSelecionada;

  void setCidadeProjeto(String cidade) {
    _cidadeSelecionada = cidade;
    notifyListeners();
  }

  Future<void> carregarCidadesIbge() async {
    if (_todasCidades.isNotEmpty) return;
    try {
      final response = await http.get(
        Uri.parse(
          'https://servicodados.ibge.gov.br/api/v1/localidades/municipios',
        ),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _todasCidades = data.map<String>((cidade) {
          final nome = cidade['nome'] ?? '';
          final uf =
              cidade['microrregiao']?['mesorregiao']?['UF']?['sigla'] ?? '';
          return '$nome - $uf';
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro IBGE: $e');
    }
  }

  // controle de instrumentos
  List<String> _funcoesSelecionadas = [];
  List<String> get funcoesSelecionadas => _funcoesSelecionadas;

  List<Instrumento> _todosInstrumentos = [];
  List<Instrumento> get todosInstrumentos => _todosInstrumentos;

  Future<void> carregarInstrumentos() async {
    if (_todosInstrumentos.isNotEmpty) return;
    try {
      final data = await _supabase
          .from('instrumentos')
          .select()
          .order('instrumento_nome');
      _todosInstrumentos = (data as List)
          .map((json) => Instrumento.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar instrumentos no projeto: $e');
    }
  }

  // fluxo de inscrições
  List<Map<String, dynamic>> _minhasInscricoes = [];
  List<Map<String, dynamic>> get minhasInscricoes => _minhasInscricoes;

  Future<void> carregarMinhasInscricoes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('candidaturas')
          .select('candidatura_status, projetos(*)')
          .eq('candidato_id', userId)
          .order('candidatura_data', ascending: false);
      _minhasInscricoes = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar inscrições: $e');
    }
  }

  void adicionarFuncao(String funcao) {
    if (!_funcoesSelecionadas.contains(funcao)) {
      _funcoesSelecionadas.add(funcao);
      notifyListeners();
    }
  }

  void removerFuncao(String funcao) {
    _funcoesSelecionadas.remove(funcao);
    notifyListeners();
  }

  void limparFormularioCriacao() {
    _cidadeSelecionada = null;
    _funcoesSelecionadas = [];
    notifyListeners();
  }

  Future<void> carregarProjetos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('projetos')
          .select()
          .eq('projeto_status', 'ATIVO')
          .order('projeto_data', ascending: false);

      _projetosAtivos = (data as List)
          .map((json) => Projeto.fromJson(json))
          .toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar projetos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarProjeto(Projeto projeto) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('projetos').insert(projeto.toJson());
      await carregarProjetos(); // Recarrega a lista após criar
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar projeto.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finalizarProjeto(String projetoId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('projetos')
          .update({'projeto_status': 'FINALIZADO'})
          .eq('projeto_id', projetoId);

      _projetosAtivos.removeWhere((p) => p.projetoId == projetoId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao finalizar a vaga.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // fluxo de candidaturas
  // fluxo de candidaturas
  Future<bool> candidatarSe(Projeto projeto) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final existente = await _supabase
          .from('candidaturas')
          .select()
          .eq('candidato_id', userId)
          .eq('projeto_id', projeto.projetoId!)
          .maybeSingle();

      if (existente != null) {
        _errorMessage = 'Você já se candidatou a esta vaga!';
        return false;
      }

      // Insere a nova candidatura
      await _supabase.from('candidaturas').insert({
        'candidato_id': userId,
        'projeto_id': projeto.projetoId!,
      });

      // Busca o nome de quem está se candidatando
      final meuPerfil = await _supabase
          .from('perfis_musicos')
          .select('perfil_nome')
          .eq('perfil_id', userId)
          .maybeSingle();

      final meuNome = meuPerfil?['perfil_nome'] ?? 'Um músico';

      //Cria a notificação para o DONO da vaga
      await _supabase.from('notificacoes').insert({
        'perfil_id': projeto.criadorId, // Envia para o criador
        'mensagem':
            '$meuNome acabou de se candidatar para a sua vaga "${projeto.projetoTitulo}"!',
      });

      await carregarMinhasInscricoes();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar candidatura.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> buscarCandidatosDoProjeto(
    String projetoId,
  ) async {
    try {
      final data = await _supabase
          .from('candidaturas')
          .select('''
            candidatura_id,
            candidato_id,
            candidatura_status,
            candidatura_data,
            perfis_musicos (
              perfil_nome,
              perfil_cidade,
              perfil_bio
            )
          ''')
          .eq('projeto_id', projetoId)
          .order('candidatura_data', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao buscar candidatos: $e');
      return [];
    }
  }

  Future<bool> atualizarStatusCandidatura(
    String candidaturaId,
    String novoStatus,
    String candidatoId,
    String tituloVaga,
  ) async {
    _isLoading = true;
    notifyListeners();
    final meuId = _supabase.auth.currentUser?.id;

    try {
      await _supabase
          .from('candidaturas')
          .update({'candidatura_status': novoStatus})
          .eq('candidatura_id', candidaturaId);

      // Busca o telefone para enviar ao candidato (caso ACEITO)
      String? meuTelefone;
      if (novoStatus == 'ACEITO' && meuId != null) {
        final meuPerfil = await _supabase
            .from('perfis_musicos')
            .select('perfil_telefone')
            .eq('perfil_id', meuId)
            .maybeSingle();
        meuTelefone = meuPerfil?['perfil_telefone'];
      }

      final mensagem = novoStatus == 'ACEITO'
          ? 'Você foi ACEITO na vaga "$tituloVaga"! Entre em contato.'
          : 'Sua candidatura para "$tituloVaga" foi RECUSADA.';

      await _supabase.from('notificacoes').insert({
        'perfil_id': candidatoId,
        'mensagem': mensagem,
        'telefone_contato': meuTelefone,
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erro ao avaliar candidato.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
