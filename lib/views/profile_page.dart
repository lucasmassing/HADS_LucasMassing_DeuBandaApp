import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/perfil_musico.dart';
import 'login_page.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _bioController = TextEditingController();
  final _cepController = TextEditingController();
  final _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProfileViewModel>();
      if (viewModel.perfil != null) {
        _nomeController.text = viewModel.perfil!.perfilNome;
        _bioController.text = viewModel.perfil!.perfilBio ?? '';
        _cepController.text = viewModel.perfil!.perfilCep ?? '';
        _referenciaController.text =
            viewModel.perfil!.perfilArtistaReferencia ?? '';
      }
    });
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final viewModel = context.read<ProfileViewModel>();

    final perfil = PerfilMusico(
      perfilId: userId,
      perfilNome: _nomeController.text.trim(),
      perfilBio: _bioController.text.trim(),
      perfilCep: _cepController.text.trim(),
      perfilCoordenadas: null,
      perfilCidade: viewModel.cidadeEstado,
      perfilObjetivo: viewModel.objetivosSelecionados.join(', '),
      perfilArtistaReferencia: _referenciaController.text.trim(),
    );

    final sucesso = await viewModel.salvarPerfil(perfil);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Erro ao salvar o perfil.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome ou Nome Artístico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cepController,
                        decoration: const InputDecoration(
                          labelText: 'CEP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        onChanged: (value) {
                          if (value.length == 8) viewModel.buscarCep(value);
                        },
                      ),
                      if (viewModel.cidadeEstado != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            viewModel.cidadeEstado!,
                            style: TextStyle(
                              color: viewModel.cidadeEstado!.contains('Erro')
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CAMPO DE BUSCA COM AUTOCOMPLETE DO ITUNES (COM FOTOS)
                      Autocomplete<Map<String, String>>(
                        displayStringForOption: (option) =>
                            option['name'] ?? '',
                        optionsBuilder:
                            (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.length < 3) {
                                return const Iterable<
                                  Map<String, String>
                                >.empty();
                              }
                              return await viewModel.buscarArtistasNoiTunes(
                                textEditingValue.text,
                              );
                            },
                        onSelected: (Map<String, String> selection) {
                          _referenciaController.text = selection['name'] ?? '';
                        },
                        fieldViewBuilder:
                            (
                              context,
                              fieldTextEditingController,
                              fieldFocusNode,
                              onFieldSubmitted,
                            ) {
                              if (fieldTextEditingController.text.isEmpty &&
                                  _referenciaController.text.isNotEmpty) {
                                fieldTextEditingController.text =
                                    _referenciaController.text;
                              }

                              return TextFormField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Artista de Referência principal',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.star),
                                  hintText: 'Digite o nome da banda...',
                                ),
                                onChanged: (val) {
                                  _referenciaController.text = val;
                                },
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                imageUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
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

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : _salvarDados,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Salvar Dados Básicos',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(thickness: 2),
                ),

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
                            onPressed: () => viewModel.removerInstrumento(
                              item.instrumentoId,
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
                            onPressed: () =>
                                viewModel.removerGenero(item['genero_id']),
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
                      onTap: () => viewModel.alternarHorario(dia, turno),
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
