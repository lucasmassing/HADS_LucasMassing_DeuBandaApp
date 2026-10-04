import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/matching_viewmodel.dart';
import 'pedidos_conexao_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MatchingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Músicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PedidosConexaoPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.carregarFeed,
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.musicosFeed.isEmpty
          ? const Center(child: Text('Nenhum novo músico encontrado.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.musicosFeed.length,
              itemBuilder: (context, index) {
                final musico = viewModel.musicosFeed[index];
                final instrumentosMap =
                    musico['musico_instrumentos'] as List<dynamic>? ?? [];

                // Resgata o score calculado no ViewModel
                final matchScore = musico['match_score'] ?? 0;

                // Define a cor baseada na percentagem
                Color corMatch;
                if (matchScore >= 70)
                  corMatch = Colors.green;
                else if (matchScore >= 40)
                  corMatch = Colors.orange;
                else
                  corMatch = Colors.grey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.deepPurple,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    musico['perfil_nome'] ?? 'Desconhecido',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (musico['perfil_cidade'] != null)
                                    Text(
                                      musico['perfil_cidade'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Indicador de Afinidade (Match Score)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: corMatch.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: corMatch),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: corMatch,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$matchScore%',
                                    style: TextStyle(
                                      color: corMatch,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (musico['perfil_objetivo'] != null &&
                            musico['perfil_objetivo'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Objetivo: ${musico['perfil_objetivo']}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Text(
                          musico['perfil_bio'] ??
                              'Nenhuma biografia fornecida.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (instrumentosMap.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'Instrumentos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: instrumentosMap.map((inst) {
                              final nomeInst =
                                  inst['instrumentos']['instrumento_nome'];
                              final nivel = inst['instrumento_nivel'];
                              return Chip(
                                label: Text(
                                  '$nomeInst ($nivel)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.deepPurple.shade50,
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final sucesso = await viewModel.enviarMatch(
                                musico['perfil_id'],
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      sucesso
                                          ? 'Convite enviado!'
                                          : 'Erro ao conectar.',
                                    ),
                                    backgroundColor: sucesso
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.handshake),
                            label: const Text('Conectar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
