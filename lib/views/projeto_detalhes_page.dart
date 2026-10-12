import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/projeto.dart';
import '../viewmodels/projeto_viewmodel.dart';
import 'projeto_candidatos_page.dart';

class ProjetoDetalhesPage extends StatelessWidget {
  final Projeto projeto;

  const ProjetoDetalhesPage({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isDonoDoProjeto = currentUserId == projeto.criadorId;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Vaga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projeto.projetoTitulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (projeto.projetoFuncaoDesejada != null &&
                projeto.projetoFuncaoDesejada!.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.person_search,
                  color: Colors.deepPurple,
                ),
                title: const Text('Função Desejada'),
                subtitle: Text(
                  projeto.projetoFuncaoDesejada!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            if (projeto.projetoLocalizacao != null &&
                projeto.projetoLocalizacao!.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.deepPurple,
                ),
                title: const Text('Localização'),
                subtitle: Text(
                  projeto.projetoLocalizacao!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            const Divider(height: 32, thickness: 1),
            const Text(
              'Descrição do Projeto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              projeto.projetoDescricao ?? 'Nenhuma descrição fornecida.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDonoDoProjeto
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProjetoCandidatosPage(projeto: projeto),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Candidatos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Finalizar Vaga?'),
                              content: const Text(
                                'Esta vaga será fechada e não receberá mais candidatos.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Finalizar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            final sucesso = await context
                                .read<ProjetoViewModel>()
                                .finalizarProjeto(projeto.projetoId!);
                            if (sucesso && context.mounted) {
                              Navigator.pop(context); // Volta pro mural
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vaga finalizada com sucesso!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalizar'),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () async {
                    final viewModel = context.read<ProjetoViewModel>();
                    final sucesso = await viewModel.candidatarSe(
                      projeto.projetoId!,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sucesso
                                ? 'Candidatura enviada com sucesso!'
                                : viewModel.errorMessage ?? 'Erro',
                          ),
                          backgroundColor: sucesso ? Colors.green : Colors.red,
                        ),
                      );
                      if (sucesso)
                        Navigator.pop(context); // Volta pro mural se der certo
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Quero me candidatar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ),
    );
  }
}
