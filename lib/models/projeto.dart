class Projeto {
  final String? projetoId;
  final String criadorId;
  final String projetoTitulo;
  final String? projetoDescricao;
  final String? projetoFuncaoDesejada;
  final String? projetoLocalizacao;
  final String projetoStatus;
  final String? nomeCriador;

  Projeto({
    this.projetoId,
    required this.criadorId,
    required this.projetoTitulo,
    this.projetoDescricao,
    this.projetoFuncaoDesejada,
    this.projetoLocalizacao,
    this.projetoStatus = 'ATIVO',
    this.nomeCriador,
  });

  factory Projeto.fromJson(Map<String, dynamic> json) {
    return Projeto(
      projetoId: json['projeto_id'],
      criadorId: json['criador_id'],
      projetoTitulo: json['projeto_titulo'],
      projetoDescricao: json['projeto_descricao'],
      projetoFuncaoDesejada: json['projeto_funcao_desejada'],
      projetoLocalizacao: json['projeto_localizacao'],
      projetoStatus: json['projeto_status'],
      nomeCriador: json['perfis_musicos']?['perfil_nome'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'criador_id': criadorId,
      'projeto_titulo': projetoTitulo,
      'projeto_descricao': projetoDescricao,
      'projeto_funcao_desejada': projetoFuncaoDesejada,
      'projeto_localizacao': projetoLocalizacao,
      'projeto_status': projetoStatus,
    };
    if (projetoId != null) {
      data['projeto_id'] = projetoId;
    }
    return data;
  }
}
