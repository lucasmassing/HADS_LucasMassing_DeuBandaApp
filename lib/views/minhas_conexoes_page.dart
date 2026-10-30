import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/matching_viewmodel.dart';
import 'perfil_visita_page.dart';

class MinhasConexoesPage extends StatefulWidget {
  const MinhasConexoesPage({super.key});

  @override
  State<MinhasConexoesPage> createState() => _MinhasConexoesPageState();
}

class _MinhasConexoesPageState extends State<MinhasConexoesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchingViewModel>().carregarMinhasConexoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MatchingViewModel>();
    final conexoes = viewModel.minhasConexoes;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final pendentes = conexoes
        .where((c) => c['match_status'] == 'PENDENTE')
        .toList();
    final aceitas = conexoes
        .where((c) => c['match_status'] == 'ACEITO')
        .toList();
    final recusadas = conexoes
        .where((c) => c['match_status'] == 'RECUSADO')
        .toList();

    Widget buildLista(List<Map<String, dynamic>> lista) {
      if (lista.isEmpty)
        return const Center(child: Text('Nenhuma conexão aqui.'));
      return ListView.builder(
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final conexao = lista[index];
          final bool fuiEuQueEnviei = conexao['musico_origem_id'] == userId;

          final outroPerfil = fuiEuQueEnviei
              ? conexao['destino']
              : conexao['origem'];
          final status = conexao['match_status'];

          Color corStatus;
          if (status == 'PENDENTE') {
            corStatus = Colors.orange;
          } else if (status == 'ACEITO') {
            corStatus = Colors.green;
          } else {
            corStatus = Colors.red;
          }

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PerfilVisitaPage(musico: outroPerfil),
                ),
              );
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              outroPerfil['perfil_nome'] ?? 'Músico',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              fuiEuQueEnviei ? 'Convite enviado por você' : 'Convite recebido',
            ),
            trailing: (status == 'PENDENTE' && !fuiEuQueEnviei)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => viewModel.responderPedido(
                          conexao['match_id'],
                          'RECUSADO',
                          conexao['musico_origem_id'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => viewModel.responderPedido(
                          conexao['match_id'],
                          'ACEITO',
                          conexao['musico_origem_id'],
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: corStatus.withOpacity(0.5)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: corStatus,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          );
        },
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Conexões'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendentes'),
              Tab(text: 'Aceitas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildLista(pendentes),
            buildLista(aceitas),
            buildLista(recusadas),
          ],
        ),
      ),
    );
  }
}
