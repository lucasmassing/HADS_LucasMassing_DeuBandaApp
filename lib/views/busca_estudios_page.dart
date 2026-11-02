import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuscaEstudiosPage extends StatefulWidget {
  const BuscaEstudiosPage({super.key});

  @override
  State<BuscaEstudiosPage> createState() => _BuscaEstudiosPageState();
}

class _BuscaEstudiosPageState extends State<BuscaEstudiosPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _estudios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstudiosESalas();
  }

  Future<void> _carregarEstudiosESalas() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('estudios')
          .select('*, salas(*)')
          .eq('salas.is_ativo', true);

      setState(() {
        _estudios = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao buscar estúdios: $e')));
      }
    }
  }

  Future<void> _solicitarReserva(String salaId) async {
    final dataReserva = DateTime.now().add(const Duration(days: 1));
    final horarioInicio = '14:00';
    final horarioFim = '16:00';
    final musicoId = _supabase.auth.currentUser!.id;

    try {
      await _supabase.from('reservas').insert({
        'sala_id': salaId,
        'musico_id': musicoId,
        'data_reserva': dataReserva.toIso8601String().split('T').first,
        'horario_inicio': horarioInicio,
        'horario_fim': horarioFim,
        'status': 'PENDENTE',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Estúdios'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estudios.isEmpty
          ? const Center(child: Text('Nenhum estúdio disponível no momento.'))
          : RefreshIndicator(
              onRefresh: _carregarEstudiosESalas,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _estudios.length,
                itemBuilder: (context, index) {
                  final estudio = _estudios[index];
                  final salas = estudio['salas'] as List<dynamic>? ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.store,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        estudio['nome_estudio'] ?? 'Estúdio sem nome',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${salas.length} sala(s) disponível(is)'),
                      children: salas.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Nenhuma sala ativa.'),
                              ),
                            ]
                          : salas.map((sala) {
                              return ListTile(
                                leading: const Icon(Icons.meeting_room),
                                title: Text(sala['nome_sala']),
                                subtitle: Text(
                                  'Capacidade: ${sala['capacidade']} | R\$ ${sala['preco_hora']}/h',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _solicitarReserva(sala['sala_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                  ),
                                  child: const Text(
                                    'Reservar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
