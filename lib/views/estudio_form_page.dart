import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/estudio_model.dart';
import '../viewmodels/estudio_viewmodel.dart';

class EstudioFormView extends StatefulWidget {
  final String donoId;

  const EstudioFormView({Key? key, required this.donoId}) : super(key: key);

  @override
  State<EstudioFormView> createState() => _EstudioFormViewState();
}

class _EstudioFormViewState extends State<EstudioFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _equipamentosController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _descricaoController.dispose();
    _equipamentosController.dispose();
    super.dispose();
  }

  void _salvarEstudio() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<EstudioViewModel>(context, listen: false);

      final novoEstudio = EstudioModel(
        id: viewModel.meuEstudio?.id ?? '',
        donoId: widget.donoId,
        nome: _nomeController.text,
        telefone: _telefoneController.text,
        endereco: _enderecoController.text,
        descricao: _descricaoController.text,
        equipamentos: _equipamentosController.text,
      );

      final sucesso = await viewModel.salvarEstudio(novoEstudio);

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estúdio salvo com sucesso!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'Erro ao salvar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EstudioViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro do Estúdio')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Estúdio *',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone Comercial *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _enderecoController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço Completo *',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do Espaço',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _equipamentosController,
                      decoration: const InputDecoration(
                        labelText: 'Equipamentos (Amps, Bateria, PA)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvarEstudio,
                      child: const Text('Salvar Estúdio'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
