import 'dart:convert';
import 'package:deubanda_app/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
  final _cepController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _equipamentosController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _buscandoCep = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<EstudioViewModel>(context, listen: false);
    if (viewModel.meuEstudio != null) {
      _nomeController.text = viewModel.meuEstudio!.nome;
      _telefoneController.text = viewModel.meuEstudio!.telefone;
      _descricaoController.text = viewModel.meuEstudio!.descricao ?? '';
      _equipamentosController.text = viewModel.meuEstudio!.equipamentos ?? '';

      final enderecoSalvo = viewModel.meuEstudio!.endereco;

      final regexComCep = RegExp(
        r'^(.*?),\s*(.*?)\s*-\s*(.*?),\s*(.*?)\s*-\s*(.*?),\s*(.*?)$',
      );
      final matchComCep = regexComCep.firstMatch(enderecoSalvo);

      final regexSemCep = RegExp(
        r'^(.*?),\s*(.*?)\s*-\s*(.*?),\s*(.*?)\s*-\s*(.*?)$',
      );
      final matchSemCep = regexSemCep.firstMatch(enderecoSalvo);

      if (matchComCep != null) {
        _ruaController.text = matchComCep.group(1) ?? '';
        _numeroController.text = matchComCep.group(2) ?? '';
        _bairroController.text = matchComCep.group(3) ?? '';
        _cidadeController.text = matchComCep.group(4) ?? '';
        _estadoController.text = matchComCep.group(5) ?? '';
        _cepController.text = matchComCep.group(6) ?? '';
      } else if (matchSemCep != null) {
        _ruaController.text = matchSemCep.group(1) ?? '';
        _numeroController.text = matchSemCep.group(2) ?? '';
        _bairroController.text = matchSemCep.group(3) ?? '';
        _cidadeController.text = matchSemCep.group(4) ?? '';
        _estadoController.text = matchSemCep.group(5) ?? '';
      } else {
        _ruaController.text = enderecoSalvo;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _descricaoController.dispose();
    _equipamentosController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _buscandoCep = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _ruaController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() => _buscandoCep = false);
    }
  }

  Future<void> _fazerLogoff() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Aplicativo'),
        content: const Text('Deseja realmente desconectar sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _salvarEstudio() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<EstudioViewModel>(context, listen: false);

      final enderecoCompleto =
          '${_ruaController.text}, ${_numeroController.text} - ${_bairroController.text}, ${_cidadeController.text} - ${_estadoController.text}, ${_cepController.text}';

      final novoEstudio = EstudioModel(
        id: viewModel.meuEstudio?.id ?? '',
        donoId: widget.donoId,
        nome: _nomeController.text,
        telefone: _telefoneController.text,
        endereco: enderecoCompleto,
        descricao: _descricaoController.text,
        equipamentos: _equipamentosController.text,
      );

      final sucesso = await viewModel.salvarEstudio(novoEstudio);

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estúdio salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Erro ao salvar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EstudioViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Estúdio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _fazerLogoff,
          ),
        ],
      ),
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
                      inputFormatters: [_telefoneFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Telefone Comercial *',
                        hintText: '(00) 00000-0000',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cepController,
                            inputFormatters: [_cepFormatter],
                            decoration: const InputDecoration(labelText: 'CEP'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _buscandoCep ? null : _buscarCep,
                          child: _buscandoCep
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Buscar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _ruaController,
                            decoration: const InputDecoration(labelText: 'Rua'),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _numeroController,
                            decoration: const InputDecoration(labelText: 'Nº'),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _bairroController,
                            decoration: const InputDecoration(
                              labelText: 'Bairro',
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Cidade',
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _estadoController,
                            decoration: const InputDecoration(labelText: 'UF'),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _salvarEstudio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Salvar Estúdio',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
