import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/projeto_viewmodel.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjetoViewModel>();
    final notificacoes = viewModel.notificacoes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notificacoes.isEmpty
          ? const Center(child: Text('Você não tem notificações.'))
          : ListView.builder(
              itemCount: notificacoes.length,
              itemBuilder: (context, index) {
                final notif = notificacoes[index];
                final bool lida = notif['lida'] ?? false;
                final telefone = notif['telefone_contato'];

                return ListTile(
                  tileColor: lida ? null : Colors.deepPurple.shade50,
                  leading: Icon(
                    lida
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: lida ? Colors.grey : Colors.deepPurple,
                  ),
                  title: Text(
                    notif['mensagem'] ?? '',
                    style: TextStyle(
                      fontWeight: lida ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: telefone != null
                      ? Text(
                          'Contato: $telefone',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  onTap: () {
                    if (!lida) {
                      viewModel.marcarNotificacaoComoLida(notif['id']);
                    }
                  },
                );
              },
            ),
    );
  }
}
