import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'estudio_form_page.dart';

class HomeEstudioPage extends StatefulWidget {
  const HomeEstudioPage({super.key});

  @override
  State<HomeEstudioPage> createState() => _HomeEstudioPageState();
}

class _HomeEstudioPageState extends State<HomeEstudioPage> {
  int _currentIndex = 0;
  late final String _donoId;
  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    _donoId = Supabase.instance.client.auth.currentUser!.id;

    _telas = [
      const SalasView(),
      const ReservasView(),
      EstudioFormView(donoId: _donoId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Salas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Meu Estúdio',
          ),
        ],
      ),
    );
  }
}

class SalasView extends StatelessWidget {
  const SalasView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Salas')),
      body: const Center(child: Text('Lista de Salas e Botão Adicionar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReservasView extends StatelessWidget {
  const ReservasView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Reservas')),
      body: const Center(child: Text('Painel de Aprovação de Reservas')),
    );
  }
}
