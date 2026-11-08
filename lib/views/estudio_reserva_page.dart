import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/reserva_model.dart';
import '../viewmodels/estudio_viewmodel.dart';
import '../viewmodels/notificacao_viewmodel.dart';
import 'notificacoes_page.dart';

class ReservasView extends StatefulWidget {
  const ReservasView({super.key});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  CalendarFormat _calendarFormat =
      CalendarFormat.twoWeeks; // Formato mais compacto
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
              margin: const EdgeInsets.only(top: 4),
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

  List<ReservaModel> _getReservasPorDia(
    DateTime dia,
    List<ReservaModel> todasReservas,
  ) {
    return todasReservas.where((r) => isSameDay(r.dataReserva, dia)).toList();
  }

  Widget _buildListaReservas(
    List<String> statusAceitos,
    EstudioViewModel viewModel,
    List<ReservaModel> todasReservas,
  ) {
    // Primeiro filtra pelo status da aba (Pendente, Aceito, Cancelado)
    var reservasFiltradas = todasReservas
        .where((res) => statusAceitos.contains(res.status))
        .toList();

    // Depois filtra pelo dia selecionado no calendário (se houver algum)
    if (_selectedDay != null) {
      reservasFiltradas = reservasFiltradas
          .where((res) => isSameDay(res.dataReserva, _selectedDay))
          .toList();
    }

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reservasFiltradas.isEmpty) {
      return Center(
        child: Text(
          _selectedDay == null
              ? 'Nenhuma solicitação nesta categoria.'
              : 'Nenhuma solicitação para este dia.',
        ),
      );
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
            onTap: () => _mostrarDetalhes(context, reserva),
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
    final todasReservas = viewModel.reservas;

    return DefaultTabController(
      length: 3,
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
                      ).then((_) => notifViewModel.carregarNotificacoes());
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Calendário de Controle
            TableCalendar<ReservaModel>(
              locale: 'pt_BR', // Deixa os dias e meses em português
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _getReservasPorDia(day, todasReservas),
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  // Se o usuário clicar no dia que já está selecionado, remove o filtro
                  if (isSameDay(_selectedDay, selectedDay)) {
                    _selectedDay = null;
                  } else {
                    _selectedDay = selectedDay;
                  }
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
              ),
              // Construção das bolinhas de notificação nos dias
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, reservas) {
                  if (reservas.isEmpty) return null;

                  bool temPendente = reservas.any(
                    (r) => r.status == 'PENDENTE',
                  );
                  bool temAceita = reservas.any((r) => r.status == 'ACEITO');

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (temPendente)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (temAceita)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Abas de Status
            const TabBar(
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(text: 'Pendentes'),
                Tab(text: 'Aceitas'),
                Tab(text: 'Canceladas'),
              ],
            ),

            // Lista Filtrada
            Expanded(
              child: TabBarView(
                children: [
                  _buildListaReservas(['PENDENTE'], viewModel, todasReservas),
                  _buildListaReservas(['ACEITO'], viewModel, todasReservas),
                  _buildListaReservas(
                    ['RECUSADO', 'CANCELADO'],
                    viewModel,
                    todasReservas,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
