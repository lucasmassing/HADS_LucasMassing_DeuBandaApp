import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notificacao_viewmodel.dart';
import '../viewmodels/matching_viewmodel.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchingViewModel>().carregarPedidosRecebidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifViewModel = context.watch<NotificacaoViewModel>();
    final matchViewModel = context.watch<MatchingViewModel>();

    final notificacoes = notifViewModel.notificacoes;
    final pedidos = matchViewModel.pedidosRecebidos;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notificacoes.isEmpty && pedidos.isEmpty
          ? const Center(child: Text('Você não tem notificações novas.'))
          : ListView(
              children: [
                // --- SEÇÃO 1: PEDIDOS DE CONEXÃO ---
                if (pedidos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'Pedidos de Conexão',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  ...pedidos.map((pedido) {
                    final perfil = pedido['perfis_musicos'];
                    final origemId = pedido['musico_origem_id'] ?? '';

                    return ListTile(
                      tileColor: Colors.deepPurple.shade50,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.handshake,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${perfil['perfil_nome']} enviou um convite!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        perfil['perfil_cidade'] ?? 'Ver perfil...',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              matchViewModel.responderPedido(
                                pedido['match_id'],
                                'RECUSADO',
                                origemId,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              matchViewModel.responderPedido(
                                pedido['match_id'],
                                'ACEITO',
                                origemId,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(thickness: 1, height: 32),
                ],

                // --- SEÇÃO 2: NOTIFICAÇÕES GERAIS ---
                if (notificacoes.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Geral',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...notificacoes.map((notif) {
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
                          fontWeight: lida
                              ? FontWeight.normal
                              : FontWeight.bold,
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
                  }),
                ],
              ],
            ),
    );
  }
}
