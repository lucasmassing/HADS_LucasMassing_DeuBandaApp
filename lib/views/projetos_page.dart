import 'package:deubanda_app/viewmodels/matching_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/projeto_viewmodel.dart';
import '../models/projeto.dart';
import 'projeto_detalhes_page.dart';
import 'notificacoes_page.dart';
import '../viewmodels/notificacao_viewmodel.dart';

class ProjetosPage extends StatefulWidget {
  const ProjetosPage({super.key});

  @override
  _ProjetosPageState createState() => _ProjetosPageState();
}

class _ProjetosPageState extends State<ProjetosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ProjetoViewModel>();
      viewModel.carregarProjetos();
      viewModel.carregarMinhasInscricoes();
    });
  }

  void _mostrarModalCriarProjeto(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();

    context.read<ProjetoViewModel>().limparFormularioCriacao();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Consumer<ProjetoViewModel>(
            builder: (context, viewModel, child) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Criar Nova Vaga/Banda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Projeto (Ex: Banda de Rock)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),

                    // campo de funções desejadas (instrumentos)
                    const Text(
                      'Funções Desejadas (Instrumentos)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: viewModel.funcoesSelecionadas.map((funcao) {
                        return Chip(
                          label: Text(funcao),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => viewModel.removerFuncao(funcao),
                          backgroundColor: Colors.deepPurple.shade50,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Adicionar função...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                      items: viewModel.todosInstrumentos.map((inst) {
                        return DropdownMenuItem(
                          value: inst.instrumentoNome,
                          child: Text(inst.instrumentoNome),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          viewModel.adicionarFuncao(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),

                    // campo de cidade com autocomplete
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.length < 2)
                          return const Iterable<String>.empty();
                        return viewModel.todasCidades.where((cidade) {
                          return cidade.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      onSelected: (String selection) =>
                          viewModel.setCidadeProjeto(selection),
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: viewModel.todasCidades.isEmpty
                                    ? 'Carregando cidades...'
                                    : 'Localização (Ex: São Paulo - SP)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                              onChanged: (val) =>
                                  viewModel.setCidadeProjeto(val),
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
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final userId =
                              Supabase.instance.client.auth.currentUser?.id;
                          if (userId == null) return;

                          final novoProjeto = Projeto(
                            criadorId: userId,
                            projetoTitulo: tituloController.text.trim(),
                            projetoDescricao: descricaoController.text.trim(),
                            projetoFuncaoDesejada: viewModel.funcoesSelecionadas
                                .join(', '),
                            projetoLocalizacao: viewModel.cidadeSelecionada,
                          );

                          final sucesso = await viewModel.criarProjeto(
                            novoProjeto,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  sucesso
                                      ? 'Projeto criado com sucesso!'
                                      : viewModel.errorMessage ?? 'Erro',
                                ),
                                backgroundColor: sucesso
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Publicar Vaga'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjetoViewModel>();
    final matchViewModel = context.watch<MatchingViewModel>();

    // Extrai os IDs das vagas em que me inscrevi para não mostrar no mural
    final idsInscritos = viewModel.minhasInscricoes
        .map((e) => e['projetos']['projeto_id'])
        .toSet();
    final muralFiltrado = viewModel.projetosAtivos
        .where((p) => !idsInscritos.contains(p.projetoId))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mural de Vagas'),
          actions: [
            Consumer<NotificacaoViewModel>(
              builder: (context, notifViewModel, child) {
                final totalAvisos =
                    notifViewModel.notificacoesNaoLidas +
                    matchViewModel.pedidosRecebidos.length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificacoesPage(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            notifViewModel.carregarNotificacoes();
                            matchViewModel.carregarPedidosRecebidos();
                          }
                        });
                      },
                    ),
                    if (totalAvisos > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$totalAvisos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                viewModel.carregarProjetos();
                viewModel.carregarMinhasInscricoes();
                context.read<NotificacaoViewModel>().carregarNotificacoes();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Todas as Vagas'),
              Tab(
                icon: Icon(Icons.playlist_add_check),
                text: 'Minhas Inscrições',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: TODAS AS VAGAS (Mural Filtrado)
            muralFiltrado.isEmpty
                ? const Center(child: Text('Nenhuma vaga nova no momento.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: muralFiltrado.length,
                    itemBuilder: (context, index) {
                      final projeto = muralFiltrado[index];
                      return _buildCardProjeto(
                        projeto,
                        context,
                      ); // <- Extrapole o código do seu Card para um widget
                    },
                  ),

            // ABA 2: MINHAS INSCRIÇÕES
            viewModel.minhasInscricoes.isEmpty
                ? const Center(
                    child: Text('Você ainda não se inscreveu em nenhuma vaga.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.minhasInscricoes.length,
                    itemBuilder: (context, index) {
                      final inscricao = viewModel.minhasInscricoes[index];
                      final projetoData = inscricao['projetos'];
                      final status = inscricao['candidatura_status'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            projetoData['projeto_titulo'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Status: $status',
                            style: TextStyle(
                              color: status == 'ACEITO'
                                  ? Colors.green
                                  : (status == 'RECUSADO'
                                        ? Colors.red
                                        : Colors.orange),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: status == 'ACEITO'
                              ? const Icon(
                                  Icons.celebration,
                                  color: Colors.green,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarModalCriarProjeto(context),
          icon: const Icon(Icons.add),
          label: const Text('Nova Vaga'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCardProjeto(Projeto projeto, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projeto.projetoTitulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (projeto.projetoFuncaoDesejada != null &&
                projeto.projetoFuncaoDesejada!.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.person_search,
                    size: 16,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Busca: ${projeto.projetoFuncaoDesejada}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            if (projeto.projetoLocalizacao != null &&
                projeto.projetoLocalizacao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      projeto.projetoLocalizacao!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              projeto.projetoDescricao ?? 'Sem descrição.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProjetoDetalhesPage(projeto: projeto),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      final vm = context.read<ProjetoViewModel>();
                      vm.carregarProjetos();
                      vm.carregarMinhasInscricoes();
                    }
                  });
                },
                child: const Text('Ver Detalhes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
