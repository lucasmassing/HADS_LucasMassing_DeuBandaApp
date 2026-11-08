import 'package:deubanda_app/views/minhas_reservas_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notificacao_viewmodel.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacaoViewModel>().carregarNotificacoes();
    });
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

  void _mostrarDialogReserva(
    BuildContext context,
    Map<String, dynamic> sala,
    String donoId,
    String equipamentosDoEstudio,
  ) {
    final formKey = GlobalKey<FormState>();
    DateTime? dataSelecionada;
    TimeOfDay? horaInicio;
    TimeOfDay? horaFim;
    final pessoasController = TextEditingController();
    final mensagemController = TextEditingController();
    String? equipamentosSelecionados;

    List<String> opcoesEquipamentos = equipamentosDoEstudio.isNotEmpty
        ? equipamentosDoEstudio.split('|').where((e) => e.isNotEmpty).toList()
        : [];

    opcoesEquipamentos.insert(0, 'Nenhum (Levo meu próprio equipamento)');
    opcoesEquipamentos.add('Outro (Especificarei na mensagem abaixo)');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Reservar ${sala['nome_sala']}'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selecionar Data
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          dataSelecionada == null
                              ? 'Escolher Data'
                              : 'Data: ${dataSelecionada!.toIso8601String().split('T').first}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                          );
                          if (data != null)
                            setStateDialog(() => dataSelecionada = data);
                        },
                      ),

                      // Selecionar Horários
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                horaInicio?.format(context) ?? 'Início',
                              ),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 14,
                                    minute: 0,
                                  ),
                                );
                                if (time != null)
                                  setStateDialog(() => horaInicio = time);
                              },
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.access_time_filled),
                              label: Text(horaFim?.format(context) ?? 'Fim'),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 16,
                                    minute: 0,
                                  ),
                                );
                                if (time != null)
                                  setStateDialog(() => horaFim = time);
                              },
                            ),
                          ),
                        ],
                      ),

                      // Número de Pessoas
                      TextFormField(
                        controller: pessoasController,
                        decoration: InputDecoration(
                          labelText:
                              'Nº de Pessoas (Máx: ${sala['capacidade']})',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Obrigatório';
                          final num = int.tryParse(val);
                          if (num == null || num <= 0) return 'Número inválido';
                          if (num > (sala['capacidade'] as int))
                            return 'Excede a capacidade';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Equipamentos (Lista Suspensa)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Equipamentos Necessários',
                        ),
                        value: equipamentosSelecionados,
                        items: opcoesEquipamentos
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setStateDialog(
                          () => equipamentosSelecionados = val,
                        ),
                        validator: (val) => val == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: mensagemController,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem para o dono (Opcional)',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dataSelecionada == null ||
                        horaInicio == null ||
                        horaFim == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione data e horários.'),
                        ),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      await _processarReserva(
                        context: context,
                        salaId: sala['sala_id'],
                        salaNome: sala['nome_sala'] ?? 'Sala',
                        donoId: donoId,
                        data: dataSelecionada!,
                        inicio: horaInicio!,
                        fim: horaFim!,
                        pessoas: int.parse(pessoasController.text),
                        equipamentos: equipamentosSelecionados!,
                        mensagem: mensagemController.text,
                      );
                    }
                  },
                  child: const Text('Confirmar Reserva'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processarReserva({
    required BuildContext context,
    required String salaId,
    required String salaNome,
    required String donoId,
    required DateTime data,
    required TimeOfDay inicio,
    required TimeOfDay fim,
    required int pessoas,
    required String equipamentos,
    required String mensagem,
  }) async {
    final musicoId = _supabase.auth.currentUser!.id;
    final dataString = data.toIso8601String().split('T').first;

    final inicioStr =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
    final fimStr =
        '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';

    try {
      final conflitos = await _supabase
          .from('reservas')
          .select()
          .eq('sala_id', salaId)
          .eq('data_reserva', dataString)
          .eq('status', 'ACEITO');

      for (var res in conflitos) {
        final startExistente = res['horario_inicio'] as String;
        final endExistente = res['horario_fim'] as String;

        if (inicioStr.compareTo(endExistente) < 0 &&
            fimStr.compareTo(startExistente) > 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Horário indisponível nesta data.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await _supabase.from('reservas').insert({
        'sala_id': salaId,
        'musico_id': musicoId,
        'data_reserva': dataString,
        'horario_inicio': inicioStr,
        'horario_fim': fimStr,
        'quantidade_pessoas': pessoas,
        'equipamentos': equipamentos,
        'mensagem': mensagem,
        'status': 'PENDENTE',
      });

      await _supabase.from('notificacoes').insert({
        'perfil_id': musicoId,
        'mensagem':
            'Sua solicitação de reserva para o dia $dataString foi enviada e está pendente.',
      });

      await _supabase.from('notificacoes').insert({
        'perfil_id': donoId,
        'mensagem':
            'Você tem uma nova solicitação de reserva pendente para a $salaNome!',
      });

      if (context.mounted) {
        Provider.of<NotificacaoViewModel>(
          context,
          listen: false,
        ).carregarNotificacoes();

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar: $e'),
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
        actions: [
          Consumer<NotificacaoViewModel>(
            builder: (context, notifViewModel, child) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: notifViewModel.notificacoesNaoLidas > 0,
                  label: Text(notifViewModel.notificacoesNaoLidas.toString()),
                  child: const Icon(Icons.receipt_long),
                ),
                tooltip: 'Minhas Reservas',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MinhasReservasPage(),
                    ),
                  ).then((_) {
                    notifViewModel.carregarNotificacoes();
                  });
                },
              );
            },
          ),
        ],
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
                        estudio['nome'] ??
                            'Estúdio sem nome',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  estudio['endereco'] ??
                                      'Endereço não informado',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${salas.length} sala(s) disponível(is)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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
                                title: Text(
                                  sala['nome_sala'] ?? 'Sala sem nome',
                                ),
                                subtitle: Text(
                                  'Capacidade: ${sala['capacidade']} | R\$ ${sala['preco_hora']}/h',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _mostrarDialogReserva(
                                    context,
                                    sala,
                                    estudio['dono_id'],
                                    estudio['equipamentos'] ?? '',
                                  ),
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
