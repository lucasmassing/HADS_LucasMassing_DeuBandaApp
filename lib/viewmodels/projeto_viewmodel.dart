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
          .order('projeto_titulo');

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

  // fluxo de candidaturas
  Future<bool> candidatarSe(String projetoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verifica se já existe uma candidatura deste usuário para esta vaga
      final existente = await _supabase
          .from('candidaturas')
          .select()
          .eq('candidato_id', userId)
          .eq('projeto_id', projetoId)
          .maybeSingle();

      if (existente != null) {
        _errorMessage = 'Você já se candidatou a esta vaga!';
        return false;
      }

      // 2. Insere a nova candidatura
      await _supabase.from('candidaturas').insert({
        'candidato_id': userId,
        'projeto_id': projetoId,
      });

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
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('candidaturas')
          .update({'candidatura_status': novoStatus})
          .eq('candidatura_id', candidaturaId);

      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar o status da candidatura.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
