import 'dart:convert';
import 'package:deubanda_app/views/home_estudio_page.dart';
import 'package:deubanda_app/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final List<String> _opcoesEquipamentos = [
    'Voz e Acústico (PA, 2 microfones, pedestais e cabos)',
    'Banda Básica (Bateria s/ pratos, 2 Amps, PA, 3 Mics)',
    'Banda Completa (Bateria c/ pratos, 2 Amps, PA, Mics)',
    'Teclas/Sintetizadores (PA, Suportes em X, Cabos P10)',
    'Gravação de Voz/Mixagem (Condensador, Fones, Interface)',
    'Gravação de Banda (Microfonação completa de bateria/amps)',
    'DJ / Eletrônica (Monitores de referência, espaço/mesa)',
    'Podcast / Mesacast (Mesa de som, Mics de locução, Fones)',
  ];
  List<String> _equipamentosSelecionados = [];
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
      final equipSalvos = viewModel.meuEstudio!.equipamentos ?? '';
      if (equipSalvos.isNotEmpty) {
        _equipamentosSelecionados = equipSalvos
            .split('|')
            .where((e) => e.isNotEmpty)
            .toList();
      }

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
      final viewModel = Provider.of<EstudioViewModel>(context, listen: false);
      await viewModel.fazerLogout();

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
        equipamentos: _equipamentosSelecionados.join('|'),
      );

      final sucesso = await viewModel.salvarEstudio(novoEstudio);

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estúdio salvo com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeEstudioPage()),
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
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Informações Básicas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Estúdio *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefoneController,
                          inputFormatters: [_telefoneFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone Comercial *',
                            hintText: '(00) 00000-0000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(thickness: 2),
                        ),

                        const Text(
                          'Localização',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cepController,
                                inputFormatters: [_cepFormatter],
                                decoration: const InputDecoration(
                                  labelText: 'CEP',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.map),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _buscandoCep ? null : _buscarCep,
                                icon: _buscandoCep
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                label: const Text('Buscar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _ruaController,
                                decoration: const InputDecoration(
                                  labelText: 'Rua',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _numeroController,
                                decoration: const InputDecoration(
                                  labelText: 'Nº',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _bairroController,
                                decoration: const InputDecoration(
                                  labelText: 'Bairro',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _estadoController,
                                decoration: const InputDecoration(
                                  labelText: 'UF',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(thickness: 2),
                        ),

                        const Text(
                          'Detalhes e Estrutura',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição do Espaço',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Equipamentos Oferecidos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _opcoesEquipamentos.map((equipamento) {
                              final isSelected = _equipamentosSelecionados
                                  .contains(equipamento);
                              return CheckboxListTile(
                                title: Text(equipamento),
                                value: isSelected,
                                activeColor: Colors.deepPurple,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _equipamentosSelecionados.add(
                                        equipamento,
                                      );
                                    } else {
                                      _equipamentosSelecionados.remove(
                                        equipamento,
                                      );
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _salvarEstudio,
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Salvar Estúdio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
