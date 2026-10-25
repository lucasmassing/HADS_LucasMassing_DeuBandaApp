import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/perfil_musico.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _bioController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _telefoneController = TextEditingController();

  bool _dadosIniciaisPreenchidos = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileViewModel>();
      if (viewModel.perfil != null && !viewModel.isFetching) {
        viewModel.carregarPerfil();
      }
    });
  }

  void _mostrarMensagemSalvo() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _autoSalvar({bool mostrarAviso = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final viewModel = context.read<ProfileViewModel>();
    final perfil = PerfilMusico(
      perfilId: userId,
      perfilNome: _nomeController.text.trim().isEmpty
          ? 'Sem Nome'
          : _nomeController.text.trim(),
      perfilBio: _bioController.text.trim(),
      perfilCoordenadas: null,
      perfilCidade: viewModel.cidadeEstado,
      perfilObjetivo: viewModel.objetivosSelecionados.join(', '),
      perfilArtistaReferencia: null,
    );

    final sucesso = await viewModel.salvarPerfil(
      perfil,
      _telefoneController.text.trim(),
    );

    if (mostrarAviso && sucesso) {
      _mostrarMensagemSalvo();
    }
  }

  void _aoDigitar(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _autoSalvar(
        mostrarAviso: true,
      ); // Salva em silêncio 1 segundo após parar de digitar
    });
  }

  Future<void> _sair() async {
    await context.read<ProfileViewModel>().fazerLogout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _mostrarModalAdicionarInstrumento(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    int? instrumentoSelecionado;
    String nivelSelecionado = 'Iniciante';
    final niveis = ['Iniciante', 'Intermediário', 'Avançado', 'Profissional'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Instrumento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Instrumento',
                      border: OutlineInputBorder(),
                    ),
                    value: instrumentoSelecionado,
                    items: viewModel.todosInstrumentos.map((inst) {
                      return DropdownMenuItem(
                        value: inst.instrumentoId,
                        child: Text(inst.instrumentoNome),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => instrumentoSelecionado = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Nível de Proficiência',
                      border: OutlineInputBorder(),
                    ),
                    value: nivelSelecionado,
                    items: niveis.map((nivel) {
                      return DropdownMenuItem(value: nivel, child: Text(nivel));
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => nivelSelecionado = val!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (instrumentoSelecionado != null) {
                          Navigator.pop(context);
                          final sucesso = await viewModel.adicionarInstrumento(
                            instrumentoSelecionado!,
                            nivelSelecionado,
                          );
                          if (!sucesso && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage ?? 'Erro'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarModalAdicionarGenero(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    int? generoSelecionado;
    bool isPrioritario = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Gênero Musical',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Gênero',
                      border: OutlineInputBorder(),
                    ),
                    value: generoSelecionado,
                    items: viewModel.todosGeneros.map((g) {
                      return DropdownMenuItem<int>(
                        value: g['genero_id'],
                        child: Text(g['genero_nome']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => generoSelecionado = val),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Gênero Prioritário?'),
                    subtitle: const Text(
                      'Marque se este for o seu estilo principal.',
                    ),
                    value: isPrioritario,
                    onChanged: (val) =>
                        setModalState(() => isPrioritario = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (generoSelecionado != null) {
                          Navigator.pop(context);
                          await viewModel.salvarGenero(
                            generoSelecionado!,
                            isPrioritario,
                          );
                          _mostrarMensagemSalvo();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    if (viewModel.isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_dadosIniciaisPreenchidos && viewModel.perfil != null) {
      _nomeController.text = viewModel.perfil!.perfilNome;
      _bioController.text = viewModel.perfil!.perfilBio ?? '';
      _telefoneController.text = viewModel.telefone ?? '';
      _dadosIniciaisPreenchidos = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _sair,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome ou Nome Artístico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: _aoDigitar,
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                          _autoSalvar(mostrarAviso: true);
                        },
                        validator: (v) =>
                            v!.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Biografia',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _aoDigitar,
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                          _autoSalvar();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp / Telefone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        onChanged: _aoDigitar,
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                          _autoSalvar();
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de CEP
                      Autocomplete<String>(
                        initialValue: TextEditingValue(
                          text: viewModel.cidadeEstado ?? '',
                        ),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.length < 2) {
                            return const Iterable<String>.empty();
                          }
                          return viewModel.todasCidades.where((cidade) {
                            final busca = textEditingValue.text.toLowerCase();
                            return cidade.toLowerCase().contains(busca);
                          });
                        },
                        onSelected: (String selection) {
                          viewModel.setCidadeEstado(selection);
                          _autoSalvar(mostrarAviso: true);
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                onChanged: (val) {
                                  viewModel.setCidadeEstado(val);
                                },
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                  maxWidth: 300,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final String option = options.elementAt(
                                          index,
                                        );
                                        return ListTile(
                                          title: Text(option),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Objetivos na Música',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: viewModel.todosObjetivos.map((objetivo) {
                            final isSelected = viewModel.objetivosSelecionados
                                .contains(objetivo);
                            return CheckboxListTile(
                              title: Text(objetivo),
                              value: isSelected,
                              activeColor: Colors.deepPurple,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              onChanged: (bool? selected) {
                                viewModel.alternarObjetivo(objetivo);
                                _autoSalvar(mostrarAviso: true);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(thickness: 2),
                ),

                // --- SEÇÃO SEPARADA: ARTISTAS E REFERÊNCIAS ---
                const Text(
                  'Artistas de Referência (Máx. 5)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (viewModel.artistasSelecionados.isEmpty)
                  const Text(
                    'Nenhuma referência adicionada.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.artistasSelecionados.length,
                      itemBuilder: (context, index) {
                        final artista = viewModel.artistasSelecionados[index];
                        final image = artista['image'] ?? '';
                        final name = artista['name'] ?? '';

                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _iconeFallback(),
                                          )
                                        : _iconeFallback(),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: () {
                                        viewModel.removerArtista(name);
                                        _mostrarMensagemSalvo();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                if (viewModel.artistasSelecionados.length < 5)
                  Autocomplete<Map<String, String>>(
                    displayStringForOption: (option) => option['name'] ?? '',
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.length < 3)
                        return const Iterable<Map<String, String>>.empty();
                      return await viewModel.buscarArtistasNoiTunes(
                        textEditingValue.text,
                      );
                    },
                    onSelected: (Map<String, String> selection) {
                      viewModel.adicionarArtista(selection);
                      _referenciaController.clear();
                      _mostrarMensagemSalvo();
                    },
                    fieldViewBuilder:
                        (
                          context,
                          fieldTextEditingController,
                          fieldFocusNode,
                          onFieldSubmitted,
                        ) {
                          if (fieldTextEditingController.text !=
                              _referenciaController.text) {
                            fieldTextEditingController.text =
                                _referenciaController.text;
                          }
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Buscar banda/artista...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (val) =>
                                _referenciaController.text = val,
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6.0,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 250,
                              maxWidth: 300,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                final imageUrl = option['image'] ?? '';
                                final name = option['name'] ?? '';

                                return ListTile(
                                  leading: imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.music_note,
                                                      color: Colors.deepPurple,
                                                    ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note,
                                          color: Colors.deepPurple,
                                        ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(thickness: 2),
                ),

                // --- INSTRUMENTOS E GÊNEROS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Meus Instrumentos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.deepPurple,
                        size: 32,
                      ),
                      onPressed: () =>
                          _mostrarModalAdicionarInstrumento(context, viewModel),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (viewModel.meusInstrumentos.isEmpty)
                  const Text(
                    'Nenhum instrumento adicionado. Clique no "+" para adicionar.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.meusInstrumentos.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.meusInstrumentos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            item.instrumentoNome ?? 'Desconhecido',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Nível: ${item.instrumentoNivel ?? "Não informado"}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final sucesso = await viewModel
                                  .removerInstrumento(item.instrumentoId);
                              if (sucesso && context.mounted) {
                                _mostrarMensagemSalvo();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dados salvos com sucesso!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(thickness: 2),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Meus Gêneros Musicais',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.deepPurple,
                        size: 32,
                      ),
                      onPressed: () =>
                          _mostrarModalAdicionarGenero(context, viewModel),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (viewModel.meusGeneros.isEmpty)
                  const Text(
                    'Nenhum gênero adicionado. Clique no "+" para adicionar.',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.meusGeneros.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.meusGeneros[index];
                      final nomeGenero =
                          item['generos_musicais']?['genero_nome'] ??
                          'Desconhecido';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            item['is_prioritario']
                                ? Icons.star
                                : Icons.music_video,
                            color: item['is_prioritario']
                                ? Colors.amber
                                : Colors.deepPurple,
                          ),
                          title: Text(
                            nomeGenero,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item['is_prioritario']
                                ? 'Gênero Prioritário'
                                : 'Gênero Secundário',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final sucesso = await viewModel.removerGenero(
                                item['genero_id'],
                              );
                              if (sucesso) {
                                _mostrarMensagemSalvo();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                _buildGradeHoraria(context, viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconeFallback() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.deepPurple.shade50,
      child: const Icon(Icons.music_note, color: Colors.deepPurple, size: 30),
    );
  }

  Widget _buildGradeHoraria(BuildContext context, ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Disponibilidade (Dimensão Logística)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione os turnos em que tem disponibilidade para ensaios:',
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.deepPurple.shade50),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Dia',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...viewModel.turnos.map(
                  (t) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      t,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            ...viewModel.diasSemana.map((dia) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      dia,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ...viewModel.turnos.map((turno) {
                    final isSelecionado = viewModel.horariosDisponiveis
                        .contains('$dia-$turno');
                    return InkWell(
                      onTap: () async {
                        await viewModel.alternarHorario(dia, turno);
                        _mostrarMensagemSalvo();
                      },
                      child: Container(
                        color: isSelecionado
                            ? Colors.deepPurple
                            : Colors.transparent,
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isSelecionado ? Icons.check : Icons.add,
                          color: isSelecionado
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
