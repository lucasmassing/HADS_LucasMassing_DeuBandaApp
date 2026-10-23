import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notificacao_viewmodel.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  @override
  Widget build(BuildContext context) {
    final notifViewModel = context.watch<NotificacaoViewModel>();
    final notificacoes = notifViewModel.notificacoes;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notificacoes.isEmpty
          ? const Center(child: Text('Você não tem notificações novas.'))
          : ListView.builder(
              itemCount: notificacoes.length,
              itemBuilder: (context, index) {
                final notif = notificacoes[index];
                final bool lida = notif['lida'] ?? false;
                final telefone = notif['telefone_contato'];

                return ListTile(
                  tileColor: lida ? null : Colors.grey.shade100,
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
                      notifViewModel.marcarNotificacaoComoLida(
                        notif['id'].toString(),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
