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
                final matchScore = musico['match_score'] ?? 0;
                final bool isSuperMatch = musico['is_super_match'] == true;

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
                    side: isSuperMatch
                        ? const BorderSide(color: Colors.amber, width: 2)
                        : BorderSide.none,
                  ),
                  elevation: isSuperMatch ? 6 : 4,
                  shadowColor: isSuperMatch
                      ? Colors.amber.withOpacity(0.4)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  if (isSuperMatch)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Super Match',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
