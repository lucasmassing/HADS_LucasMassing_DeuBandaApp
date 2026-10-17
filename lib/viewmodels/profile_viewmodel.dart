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

  List<String> _objetivosSelecionados = [];
  List<String> get objetivosSelecionados => _objetivosSelecionados;

  // --- NOVA ESTRUTURA PARA ARTISTAS COM FOTO ---
  List<Map<String, String>> _artistasSelecionados = [];
  List<Map<String, String>> get artistasSelecionados => _artistasSelecionados;

  // variaveis para API do IBGE
  List<String> _todasCidades = [];
  List<String> get todasCidades => _todasCidades;

  final List<String> todosObjetivos = [
    'Hobby e Diversão',
    'Banda Cover / Tributo',
    'Trabalho Profissional',
    'Somente Gravação',
    'Composição Original',
  ];

  bool _isFetching = true;
  bool get isFetching => _isFetching;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _cidadeEstado;
  String? get cidadeEstado => _cidadeEstado;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _telefone;
  String? get telefone => _telefone;

  ProfileViewModel() {
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await carregarInstrumentosDisponiveis();
    await carregarGenerosDisponiveis();
    await carregarCidadesIbge();
    await carregarPerfil();
  }

  void alternarObjetivo(String objetivo) {
    if (_objetivosSelecionados.contains(objetivo)) {
      _objetivosSelecionados.remove(objetivo);
    } else {
      _objetivosSelecionados.add(objetivo);
    }
    notifyListeners();
  }

  // --- SALVAMENTO AUTOMÁTICO DE REFERÊNCIAS ---
  Future<void> _salvarReferenciasNoBanco() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final jsonString = json.encode(_artistasSelecionados);
    try {
      await _supabase
          .from('perfis_musicos')
          .update({'perfil_artista_referencia': jsonString})
          .eq('perfil_id', userId);
    } catch (e) {
      debugPrint('Erro ao salvar referência: $e');
    }
  }

  void adicionarArtista(Map<String, String> artista) async {
    if (_artistasSelecionados.length < 5 &&
        !_artistasSelecionados.any((a) => a['name'] == artista['name'])) {
      _artistasSelecionados.add(artista);
      notifyListeners();
      await _salvarReferenciasNoBanco();
    }
  }

  void removerArtista(String nomeArtista) async {
    _artistasSelecionados.removeWhere((a) => a['name'] == nomeArtista);
    notifyListeners();
    await _salvarReferenciasNoBanco();
  }

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
        _telefone = data['perfil_telefone'];
        _cidadeEstado = _perfil!.perfilCidade;

        final objTexto = data['perfil_objetivo'] ?? '';
        if (objTexto.isNotEmpty) {
          _objetivosSelecionados = objTexto.split(', ');
        } else {
          _objetivosSelecionados = [];
        }

        // --- CONVERSÃO DA REFERÊNCIA (JSON COM FOTOS) ---
        final refTexto = data['perfil_artista_referencia'] ?? '';
        if (refTexto.isNotEmpty) {
          try {
            final List decoded = json.decode(refTexto);
            _artistasSelecionados = decoded
                .map((e) => Map<String, String>.from(e))
                .toList();
          } catch (e) {
            final nomes = refTexto.split(', ');
            _artistasSelecionados = nomes
                .map((n) => {'name': n, 'image': ''})
                .toList();
          }
        } else {
          _artistasSelecionados = [];
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

  Future<bool> salvarPerfil(
    PerfilMusico perfilAtualizado,
    String telefone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final jsonParaSalvar = perfilAtualizado.toJson();
      jsonParaSalvar['perfil_objetivo'] = _objetivosSelecionados.join(', ');

      jsonParaSalvar['perfil_telefone'] = telefone;

      jsonParaSalvar.remove('perfil_artista_referencia');

      await _supabase.from('perfis_musicos').upsert(jsonParaSalvar);
      _perfil = perfilAtualizado;
      _telefone = telefone;
      return true;
    } catch (e) {
      // ...
      _errorMessage = 'Erro ao salvar o perfil.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparDados() {
    _perfil = null;
    _meusInstrumentos = [];
    _cidadeEstado = null;
    _errorMessage = null;
    _objetivosSelecionados = [];
    _artistasSelecionados = [];
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

  Future<List<Map<String, String>>> buscarArtistasNoiTunes(String query) async {
    if (query.trim().length < 3) return [];
    try {
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

  // API do IBGE para buscar todas as cidades de um estado
  void setCidadeEstado(String cidade) {
    _cidadeEstado = cidade;
    notifyListeners();
  }

  Future<void> carregarCidadesIbge() async {
    if (_todasCidades.isNotEmpty) return; // Evita carregar duas vezes

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
      debugPrint('Erro ao carregar cidades do IBGE: $e');
    }
  }
}
