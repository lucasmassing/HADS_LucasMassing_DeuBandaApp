class EstudioModel {
  final String id;
  final String donoId;
  final String nome;
  final String? descricao;
  final String telefone;
  final String endereco;
  final String? equipamentos;
  final bool isAtivo;
  final DateTime? createdAt;

  EstudioModel({
    required this.id,
    required this.donoId,
    required this.nome,
    this.descricao,
    required this.telefone,
    required this.endereco,
    this.equipamentos,
    this.isAtivo = true,
    this.createdAt,
  });

  factory EstudioModel.fromJson(Map<String, dynamic> json) {
    return EstudioModel(
      id: json['estudio_id'] as String,
      donoId: json['dono_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      telefone: json['telefone'] as String,
      endereco: json['endereco'] as String,
      equipamentos: json['equipamentos'] as String?,
      isAtivo: json['is_ativo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'estudio_id': id,
      'dono_id': donoId,
      'nome': nome,
      'descricao': descricao,
      'telefone': telefone,
      'endereco': endereco,
      'equipamentos': equipamentos,
      'is_ativo': isAtivo,
    };
  }
}
