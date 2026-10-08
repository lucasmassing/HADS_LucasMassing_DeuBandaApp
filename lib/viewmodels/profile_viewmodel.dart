import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/perfil_musico.dart';
import '../models/instrumento.dart';

class ProfileViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  PerfilMusico? _perfil;
  PerfilMusico? get perfil => _perfil;

  List<Instrumento> _todosInstrumentos = [];
  List<Instrumento> get todosInstrumentos => _todosInstrumentos;

  List<MusicoInstrumento> _meusInstrumentos = [];
  List<MusicoInstrumento> get meusInstrumentos => _meusInstrumentos;

  List<Map<String, dynamic>> _meusGeneros = [];
  List<Map<String, dynamic>> get meusGeneros => _meusGeneros;

  List<String> _horariosDisponiveis = [];
  List<String> get horariosDisponiveis => _horariosDisponiveis;

  List<Map<String, dynamic>> _todosGeneros = [];
  List<Map<String, dynamic>> get todosGeneros => _todosGeneros;

  // --- NOVAS VARIÁVEIS PARA OBJETIVOS ---
  List<String> _objetivosSelecionados = [];
  List<String> get objetivosSelecionados => _objetivosSelecionados;

  final List<String> todosObjetivos = [
    'Hobby e Diversão',
    'Banda Cover / Tributo',
    'Trabalho Profissional',
    'Somente Gravação',
    'Composição Original',
  ];
  // ----------------------------------------

  bool _isFetching = true;
  bool get isFetching => _isFetching;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _cidadeEstado;
  String? get cidadeEstado => _cidadeEstado;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProfileViewModel() {
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await carregarInstrumentosDisponiveis();
    await carregarGenerosDisponiveis();
    await carregarPerfil();
  }

  // --- NOVO MÉTODO PARA ALTERNAR OBJETIVOS ---
  void alternarObjetivo(String objetivo) {
    if (_objetivosSelecionados.contains(objetivo)) {
      _objetivosSelecionados.remove(objetivo);
    } else {
      _objetivosSelecionados.add(objetivo);
    }
    notifyListeners();
  }
  // ------------------------------------------

  Future<void> carregarInstrumentosDisponiveis() async {
    try {
      final data = await _supabase
          .from('instrumentos')
          .select()
          .order('instrumento_nome');
      _todosInstrumentos = (data as List)
          .map((json) => Instrumento.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar lista de instrumentos: $e');
    }
  }

  Future<void> carregarPerfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _isFetching = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _supabase
          .from('perfis_musicos')
          .select()
          .eq('perfil_id', user.id)
          .maybeSingle();

      if (data != null) {
        _perfil = PerfilMusico.fromJson(data);

        // --- TRANSFORMAÇÃO DO TEXTO DO BANCO EM LISTA DE OBJETIVOS ---
        final objTexto = data['perfil_objetivo'] ?? '';
        if (objTexto.isNotEmpty) {
          _objetivosSelecionados = objTexto.split(', ');
        } else {
          _objetivosSelecionados = [];
        }
        // -----------------------------------------------------------

        if (_perfil!.perfilCidade != null &&
            _perfil!.perfilCidade!.isNotEmpty) {
          _cidadeEstado = _perfil!.perfilCidade;
        } else if (_perfil!.perfilCep != null &&
            _perfil!.perfilCep!.isNotEmpty) {
          await buscarCep(_perfil!.perfilCep!);
        }

        await carregarMeusInstrumentos(user.id);
        await carregarDadosExtras();
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar dados do perfil.';
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> carregarMeusInstrumentos(String userId) async {
    try {
      final data = await _supabase
          .from('musico_instrumentos')
          .select(
            'musico_id, instrumento_id, instrumento_nivel, instrumentos(instrumento_nome)',
          )
          .eq('musico_id', userId);

      _meusInstrumentos = (data as List)
          .map((json) => MusicoInstrumento.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar meus instrumentos: $e');
    }
  }

  Future<bool> adicionarInstrumento(int instrumentoId, String nivel) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final novoVinculo = MusicoInstrumento(
        musicoId: userId,
        instrumentoId: instrumentoId,
        instrumentoNivel: nivel,
      );

      await _supabase.from('musico_instrumentos').upsert(novoVinculo.toJson());
      await carregarMeusInstrumentos(userId);
      return true;
    } catch (e) {
      _errorMessage =
          'Erro ao adicionar instrumento. Você já pode tê-lo adicionado.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removerInstrumento(int instrumentoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('musico_instrumentos')
          .delete()
          .eq('musico_id', userId)
          .eq('instrumento_id', instrumentoId);

      await carregarMeusInstrumentos(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> salvarPerfil(PerfilMusico perfilAtualizado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --- TRANSFORMA A LISTA DE VOLTA EM TEXTO PARA SALVAR ---
      final jsonParaSalvar = perfilAtualizado.toJson();
      jsonParaSalvar['perfil_objetivo'] = _objetivosSelecionados.join(', ');

      await _supabase.from('perfis_musicos').upsert(jsonParaSalvar);
      _perfil = perfilAtualizado;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar o perfil.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) {
      _cidadeEstado = null;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          _cidadeEstado = '${data['localidade']} - ${data['uf']}';
        } else {
          _cidadeEstado = 'CEP não encontrado';
        }
      }
    } catch (e) {
      _cidadeEstado = 'Erro ao buscar localização';
    }
    notifyListeners();
  }

  void limparDados() {
    _perfil = null;
    _meusInstrumentos = [];
    _cidadeEstado = null;
    _errorMessage = null;
    _objetivosSelecionados = []; // --- LIMPA A LISTA AO SAIR ---
    notifyListeners();
  }

  Future<void> fazerLogout() async {
    limparDados();
    await _supabase.auth.signOut();
  }

  final List<String> _diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  final List<String> _turnos = ['Manhã', 'Tarde', 'Noite'];

  List<String> get diasSemana => _diasSemana;
  List<String> get turnos => _turnos;

  Future<void> carregarDadosExtras() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final generosData = await _supabase
          .from('musico_generos')
          .select('genero_id, is_prioritario, generos_musicais(genero_nome)')
          .eq('perfil_id', userId);
      _meusGeneros = List<Map<String, dynamic>>.from(generosData);

      final dispData = await _supabase
          .from('disponibilidade_semanal')
          .select()
          .eq('perfil_id', userId);
      _horariosDisponiveis = (dispData as List)
          .map((d) => '${d['dia_semana']}-${d['turno']}')
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados extras: $e');
    }
  }

  Future<void> alternarHorario(String dia, String turno) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final chave = '$dia-$turno';
    final existe = _horariosDisponiveis.contains(chave);

    try {
      if (existe) {
        await _supabase.from('disponibilidade_semanal').delete().match({
          'perfil_id': userId,
          'dia_semana': dia,
          'turno': turno,
        });
        _horariosDisponiveis.remove(chave);
      } else {
        await _supabase.from('disponibilidade_semanal').insert({
          'perfil_id': userId,
          'dia_semana': dia,
          'turno': turno,
        });
        _horariosDisponiveis.add(chave);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar horário: $e');
    }
  }

  Future<void> salvarGenero(int generoId, bool isPrioritario) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('musico_generos').insert({
        'perfil_id': userId,
        'genero_id': generoId,
        'is_prioritario': isPrioritario,
      });
      await carregarDadosExtras();
    } catch (e) {
      debugPrint('Erro ao salvar gênero: $e');
    }
  }

  Future<void> carregarGenerosDisponiveis() async {
    try {
      final data = await _supabase
          .from('generos_musicais')
          .select()
          .order('genero_nome');
      _todosGeneros = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao carregar lista de gêneros: $e');
    }
  }

  Future<bool> removerGenero(int generoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _supabase
          .from('musico_generos')
          .delete()
          .eq('perfil_id', userId)
          .eq('genero_id', generoId);
      await carregarDadosExtras();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- BUSCA DE ARTISTAS NA API DO ITUNES COM FOTO (CORRIGIDO) ---
  Future<List<Map<String, String>>> buscarArtistasNoiTunes(String query) async {
    if (query.trim().length < 3) return [];

    try {
      // entity=album (para ter a foto) e attribute=artistTerm (obrigatório bater com o nome da banda)
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$query&entity=album&attribute=artistTerm&limit=15',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        final Map<String, Map<String, String>> artistasUnicos = {};

        for (var r in results) {
          final artistName = r['artistName']?.toString() ?? '';
          final artworkUrl = r['artworkUrl100']?.toString() ?? '';

          // Confirma dupla para evitar qualquer lixo da API
          if (artistName.isNotEmpty &&
              artistName.toLowerCase().contains(query.toLowerCase()) &&
              !artistasUnicos.containsKey(artistName)) {
            artistasUnicos[artistName] = {
              'name': artistName,
              'image': artworkUrl,
            };
          }

          if (artistasUnicos.length >= 5) break;
        }

        return artistasUnicos.values.toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar artista com foto: $e');
    }
    return [];
  }
}
