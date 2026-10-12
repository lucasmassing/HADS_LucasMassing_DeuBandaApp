import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/projeto_viewmodel.dart';
import '../models/projeto.dart';

class ProjetoCandidatosPage extends StatefulWidget {
  final Projeto projeto;

  const ProjetoCandidatosPage({super.key, required this.projeto});

  @override
  State<ProjetoCandidatosPage> createState() => _ProjetoCandidatosPageState();
}

class _ProjetoCandidatosPageState extends State<ProjetoCandidatosPage> {
  late Future<List<Map<String, dynamic>>> _futureCandidatos;

  @override
  void initState() {
    super.initState();
    _carregarCandidatos();
  }

  void _carregarCandidatos() {
    setState(() {
      _futureCandidatos = context
          .read<ProjetoViewModel>()
          .buscarCandidatosDoProjeto(widget.projeto.projetoId!);
    });
  }

  void _mostrarModalAvaliacao(
    BuildContext context,
    Map<String, dynamic> candidatoData,
  ) {
    final perfil = candidatoData['perfis_musicos'];
    final candidaturaId = candidatoData['candidatura_id'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perfil['perfil_nome'] ?? 'Músico',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    perfil['perfil_cidade'] ?? 'Localização não informada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1),
              const Text(
                'Biografia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                perfil['perfil_bio'] ?? 'O músico não forneceu uma biografia.',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final viewModel = context.read<ProjetoViewModel>();
                        final sucesso = await viewModel.atualizarStatusCandidatura(
                          candidaturaId,
                          'RECUSADO',
                          candidatoData['candidato_id'],
                          widget.projeto.projetoTitulo,
                        );

                        if (context.mounted) {
                          if (sucesso) {
                            Navigator.pop(context); // Fecha o modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Candidatura recusada.'),
                                backgroundColor: Colors
                                    .orange,
                              ),
                            );
                            _carregarCandidatos(); // Atualiza a lista na tela
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ??
                                      'Erro ao recusar candidato.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final viewModel = context.read<ProjetoViewModel>();
                        final sucesso = await viewModel
                            .atualizarStatusCandidatura(
                              candidaturaId,
                              'ACEITO',
                              candidatoData['candidato_id'],
                              widget.projeto.projetoTitulo,
                            );

                        if (context.mounted) {
                          if (sucesso) {
                            Navigator.pop(
                              context,
                            ); // Fecha o modal de avaliação
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Candidato ACEITO com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _carregarCandidatos(); // Atualiza a lista da tela
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ?? 'Erro ao aprovar.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos da Vaga')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCandidatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar candidatos.'));
          }

          final candidatos = snapshot.data!;
          if (candidatos.isEmpty) {
            return const Center(child: Text('Ninguém se candidatou ainda.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: candidatos.length,
            itemBuilder: (context, index) {
              final item = candidatos[index];
              final perfil = item['perfis_musicos'];
              final status = item['candidatura_status'];

              Color statusColor;
              if (status == 'ACEITO') {
                statusColor = Colors.green;
              } else if (status == 'RECUSADO') {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    perfil['perfil_nome'] ?? 'Músico',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil['perfil_cidade'] ?? 'Localização não informada',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: status == 'PENDENTE'
                      ? OutlinedButton(
                          onPressed: () =>
                              _mostrarModalAvaliacao(context, item),
                          child: const Text('Avaliar'),
                        )
                      : const Icon(Icons.fact_check, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
