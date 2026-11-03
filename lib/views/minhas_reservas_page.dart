import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Reservas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _minhasReservas.isEmpty
          ? const Center(child: Text('Você ainda não fez nenhuma reserva.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _minhasReservas.length,
              itemBuilder: (context, index) {
                final res = _minhasReservas[index];
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getStatusColor(res['status']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
