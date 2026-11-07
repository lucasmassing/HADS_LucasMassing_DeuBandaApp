import 'package:deubanda_app/models/reserva_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/estudio_viewmodel.dart';
import '../viewmodels/notificacao_viewmodel.dart';
import 'package:deubanda_app/views/notificacoes_page.dart';

class ReservasView extends StatefulWidget {
  const ReservasView({super.key});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<EstudioViewModel>();
      if (viewModel.meuEstudio != null) {
        viewModel.carregarReservas(viewModel.meuEstudio!.id);
      }
      context.read<NotificacaoViewModel>().carregarNotificacoes();
    });
  }

  void _mostrarDetalhes(BuildContext context, ReservaModel reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data: ${reserva.dataReserva.toIso8601String().split('T').first}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Horário: ${reserva.horarioInicio} às ${reserva.horarioFim}'),
            const Divider(),
            Text('Pessoas: ${reserva.quantidadePessoas ?? "Não informado"}'),
            const SizedBox(height: 8),
            Text('Equipamentos: ${reserva.equipamentos ?? "Nenhum"}'),
            const SizedBox(height: 8),
            const Text(
              'Mensagem do Músico:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reserva.mensagem?.isNotEmpty == true
                    ? reserva.mensagem!
                    : 'Nenhuma mensagem.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACEITO':
        return Colors.green;
      case 'RECUSADO':
      case 'CANCELADO':
        return Colors.red;
      case 'PENDENTE':
      default:
        return Colors.orange;
    }
  }

  Widget _buildListaReservas(
    List<String> statusAceitos,
    EstudioViewModel viewModel,
    List<ReservaModel> todasReservas,
  ) {
    final reservasFiltradas = todasReservas
        .where((res) => statusAceitos.contains(res.status))
        .toList();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reservasFiltradas.isEmpty) {
      return const Center(child: Text('Nenhuma solicitação nesta categoria.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (viewModel.meuEstudio != null) {
          await viewModel.carregarReservas(viewModel.meuEstudio!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservasFiltradas.length,
        itemBuilder: (context, index) {
          final reserva = reservasFiltradas[index];
          final statusColor = _getStatusColor(reserva.status);
          final dataFormatada = reserva.dataReserva
              .toIso8601String()
              .split('T')
              .first;

          return InkWell(
            onTap: () {
              _mostrarDetalhes(context, reserva);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reserva.nomeMusico ?? 'Músico Desconhecido',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Chip(
                          label: Text(
                            reserva.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Data: $dataFormatada'),
                    Text(
                      'Horário: ${reserva.horarioInicio} - ${reserva.horarioFim}',
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          reserva.telefoneMusico ?? 'Não informado',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (reserva.status == 'PENDENTE') ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final sucesso = await viewModel.responderReserva(
                                reserva.id,
                                'RECUSADO',
                              );
                              if (context.mounted && sucesso) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reserva recusada!'),
                                  ),
                                );
                                // Atualiza a tela após recusa
                                viewModel.carregarReservas(
                                  viewModel.meuEstudio!.id,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Recusar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final sucesso = await viewModel.responderReserva(
                                reserva.id,
                                'ACEITO',
                              );
                              if (context.mounted && sucesso) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reserva aprovada com sucesso!',
                                    ),
                                  ),
                                );
                                // Atualiza a tela após aceite
                                viewModel.carregarReservas(
                                  viewModel.meuEstudio!.id,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Aprovar'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EstudioViewModel>();
    final reservas = viewModel.reservas;

    return DefaultTabController(
      length: 3, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão de Reservas'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Consumer<NotificacaoViewModel>(
              builder: (context, notifViewModel, child) {
                return IconButton(
                  icon: Badge(
                    isLabelVisible: notifViewModel.notificacoesNaoLidas > 0,
                    label: Text(notifViewModel.notificacoesNaoLidas.toString()),
                    child: const Icon(Icons.notifications),
                  ),
                  tooltip: 'Notificações',
                  onPressed: () async {
                    await notifViewModel.carregarNotificacoes();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificacoesPage(),
                        ),
                      ).then((_) {
                        notifViewModel.carregarNotificacoes();
                      });
                    }
                  },
                );
              },
            ),
          ],
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
            _buildListaReservas(['PENDENTE'], viewModel, reservas),
            _buildListaReservas(['ACEITO'], viewModel, reservas),
            _buildListaReservas(['RECUSADO', 'CANCELADO'], viewModel, reservas),
          ],
        ),
      ),
    );
  }
}
