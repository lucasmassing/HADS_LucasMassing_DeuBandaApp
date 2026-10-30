import 'package:flutter/material.dart';

class PerfilVisitaPage extends StatelessWidget {
  final Map<String, dynamic> musico;

  const PerfilVisitaPage({super.key, required this.musico});

  @override
  Widget build(BuildContext context) {
    final instrumentosMap =
        musico['musico_instrumentos'] as List<dynamic>? ?? [];
    final generosMap = musico['musico_generos'] as List<dynamic>? ?? [];
    final horariosMap = musico['musico_horarios'] as List<dynamic>? ?? [];
    final artistasMap = musico['artistas_referencia'] as List<dynamic>? ?? [];
    final telefone = musico['perfil_telefone'] ?? musico['telefone'];
    final bio = musico['perfil_bio']?.toString().trim() ?? '';
    final objetivo = musico['perfil_objetivo']?.toString().trim() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(musico['perfil_nome'] ?? 'Perfil do Músico'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(telefone),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bio.isNotEmpty) ...[
                    _buildCardInfo(Icons.format_quote, 'Biografia', bio),
                    const SizedBox(height: 16),
                  ],
                  if (objetivo.isNotEmpty) ...[
                    _buildCardInfo(Icons.flag_outlined, 'Objetivos', objetivo),
                    const SizedBox(height: 24),
                  ],
                  if (artistasMap.isNotEmpty) ...[
                    _buildArtistas(artistasMap),
                    const SizedBox(height: 24),
                  ],
                  if (instrumentosMap.isNotEmpty) ...[
                    _buildInstrumentos(instrumentosMap),
                    const SizedBox(height: 24),
                  ],
                  if (generosMap.isNotEmpty) ...[
                    _buildGeneros(generosMap),
                    const SizedBox(height: 24),
                  ],
                  if (horariosMap.isNotEmpty) ...[
                    _buildAgenda(horariosMap),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CABEÇALHO DO PERFIL ---
  Widget _buildHeader(dynamic telefone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 55,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            musico['perfil_nome'] ?? 'Desconhecido',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (musico['perfil_cidade'] != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  musico['perfil_cidade'],
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          if (telefone != null && telefone.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    telefone.toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfo(IconData icone, String titulo, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Colors.deepPurple, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistas(List artistasMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Artistas de Referência',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artistasMap.length,
            itemBuilder: (context, index) {
              final artista = artistasMap[index];
              final nome =
                  artista['name'] ?? artista['artista_nome'] ?? 'Desconhecido';
              final imageUrl =
                  artista['imageUrl'] ?? artista['url'] ?? artista['image'];

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl == null
                          ? const Icon(Icons.music_note, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- INSTRUMENTOS ---
  Widget _buildInstrumentos(List instrumentosMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Instrumentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: instrumentosMap.map((inst) {
            final nomeInst =
                inst['instrumentos']?['instrumento_nome'] ?? 'Desconhecido';
            final nivel = inst['instrumento_nivel'] ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.piano, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    '$nomeInst ($nivel)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- GÊNEROS MUSICAIS ---
  Widget _buildGeneros(List generosMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Gêneros Musicais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: generosMap.map((g) {
            final nomeGenero =
                g['generos_musicais']?['genero_nome'] ?? 'Desconhecido';
            final isPrioritario = g['is_prioritario'] == true;

            return Chip(
              label: Text(nomeGenero),
              labelStyle: TextStyle(
                fontWeight: isPrioritario ? FontWeight.bold : FontWeight.normal,
                color: isPrioritario ? Colors.amber.shade900 : Colors.black87,
              ),
              backgroundColor: isPrioritario
                  ? Colors.amber.shade100
                  : Colors.white,
              side: BorderSide(
                color: isPrioritario
                    ? Colors.amber.shade300
                    : Colors.grey.shade300,
              ),
              avatar: isPrioritario
                  ? Icon(Icons.star, size: 16, color: Colors.amber.shade700)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- AGENDA DE DISPONIBILIDADE ---
  Widget _buildAgenda(List horariosMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Disponibilidade',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: horariosMap.map((h) {
            final diaTurno = h['dia_turno'] ?? h.toString();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    diaTurno,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
