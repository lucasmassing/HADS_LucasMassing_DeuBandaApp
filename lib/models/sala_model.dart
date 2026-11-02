class SalaModel {
  final String id;
  final String estudioId;
  final String nomeSala;
  final int capacidade;
  final double precoHora;
  final bool isAtivo;
  final DateTime? createdAt;

  SalaModel({
    required this.id,
    required this.estudioId,
    required this.nomeSala,
    required this.capacidade,
    required this.precoHora,
    this.isAtivo = true,
    this.createdAt,
  });

  factory SalaModel.fromJson(Map<String, dynamic> json) {
    return SalaModel(
      id: json['sala_id'] as String,
      estudioId: json['estudio_id'] as String,
      nomeSala: json['nome_sala'] as String,
      capacidade: json['capacidade'] as int? ?? 1,
      precoHora: (json['preco_hora'] as num).toDouble(),
      isAtivo: json['is_ativo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'sala_id': id,
      'estudio_id': estudioId,
      'nome_sala': nomeSala,
      'capacidade': capacidade,
      'preco_hora': precoHora,
      'is_ativo': isAtivo,
    };
  }
}
