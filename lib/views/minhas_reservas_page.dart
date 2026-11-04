import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notificacao_viewmodel.dart';

class MinhasReservasPage extends StatefulWidget {
  const MinhasReservasPage({super.key});

  @override
  State<MinhasReservasPage> createState() => _MinhasReservasPageState();
}

class _MinhasReservasPageState extends State<MinhasReservasPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _minhasReservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMinhasReservas();
  }

  Future<void> _carregarMinhasReservas() async {
    setState(() => _isLoading = true);
    final uid = _supabase.auth.currentUser!.id;

    try {
      final data = await _supabase
          .from('reservas')
          .select('*, salas(*, estudios(*))')
          .eq('musico_id', uid)
          .order('created_at', ascending: false);

      setState(() {
        _minhasReservas = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'ACEITO') return Colors.green;
    if (status == 'RECUSADO' || status == 'CANCELADO') return Colors.red;
    return Colors.orange;
  }

  Widget _buildListaReservas(List<String> statusAceitos) {
    final listaFiltrada = _minhasReservas
        .where((res) => statusAceitos.contains(res['status']))
        .toList();

    if (listaFiltrada.isEmpty) {
      return const Center(child: Text('Nenhuma reserva nesta categoria.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, index) {
        final res = listaFiltrada[index];
        final sala = res['salas'] != null
            ? res['salas']['nome_sala'] ??
                  res['salas']['nome'] ??
                  'Sala Desconhecida'
            : 'Sala Desconhecida';
        final estudioData = res['salas'] != null
            ? res['salas']['estudios']
            : null;
        final estudio = estudioData != null
            ? estudioData['nome_estudio'] ??
                  estudioData['nome'] ??
                  'Estúdio Desconhecido'
            : 'Estúdio Desconhecido';

        return Card(
          child: ListTile(
            onTap: () {
              final notifVM = context.read<NotificacaoViewModel>();
              final naoLidas = notifVM.notificacoes
                  .where((n) => n['lida'] == false)
                  .toList();
              if (naoLidas.isNotEmpty) {
                notifVM.marcarNotificacaoComoLida(
                  naoLidas.first['id'].toString(),
                );
              }
            },
            title: Text(
              '$estudio - $sala',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Data: ${res['data_reserva']}\nHorário: ${res['horario_inicio']} às ${res['horario_fim']}',
            ),
            isThreeLine: true,
            trailing: Chip(
              label: Text(
                res['status'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getStatusColor(res['status']),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Reservas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendentes'),
              Tab(text: 'Aceitas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildListaReservas(['PENDENTE']),
                  _buildListaReservas(['ACEITO']),
                  _buildListaReservas(['RECUSADO', 'CANCELADO']),
                ],
              ),
      ),
    );
  }
}
