import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/estudio_viewmodel.dart';
import '../models/sala_model.dart';

class SalasView extends StatelessWidget {
  const SalasView({super.key});

  void _mostrarDialogNovaSala(
    BuildContext context,
    EstudioViewModel viewModel,
  ) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final capacidadeController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Nova Sala'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Sala (ex: Sala A)',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                TextFormField(
                  controller: capacidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidade (pessoas)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                TextFormField(
                  controller: precoController,
                  decoration: InputDecoration(
                    labelText: 'Preço por Hora (€/R\$)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final novaSala = SalaModel(
                    id: '',
                    estudioId: viewModel.meuEstudio!.id,
                    nomeSala: nomeController.text.trim(),
                    capacidade: int.parse(capacidadeController.text.trim()),
                    precoHora: double.parse(
                      precoController.text.replaceAll(',', '.').trim(),
                    ),
                  );

                  final sucesso = await viewModel.salvarSala(novaSala);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sucesso
                              ? 'Sala adicionada!'
                              : 'Erro ao adicionar sala',
                        ),
                        backgroundColor: sucesso ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fica à escuta das alterações na ViewModel
    final viewModel = context.watch<EstudioViewModel>();
    final salas = viewModel.minhasSalas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Salas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma sala registada. Adicione a sua primeira sala!',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: salas.length,
              itemBuilder: (context, index) {
                final sala = salas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.meeting_room,
                      color: Colors.deepPurple,
                      size: 40,
                    ),
                    title: Text(
                      sala.nomeSala,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Capacidade: ${sala.capacidade} pessoas\nPreço: ${sala.precoHora.toStringAsFixed(2)} /h',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Inativar Sala?'),
                            content: const Text(
                              'Isto irá inativar a sala e cancelar todas as reservas pendentes para a mesma.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Inativar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await viewModel.inativarSala(sala.id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogNovaSala(context, viewModel),
        icon: const Icon(Icons.add),
        label: const Text('Nova Sala'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
