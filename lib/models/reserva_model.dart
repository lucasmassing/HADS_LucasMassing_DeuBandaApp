class ReservaModel {
  final String id;
  final String salaId;
  final String musicoId;
  final DateTime dataReserva;
  final String horarioInicio;
  final String horarioFim;
  final String status;
  final int? quantidadePessoas;
  final String? equipamentos;
  final String? mensagem;
  final DateTime? createdAt;

  ReservaModel({
    required this.id,
    required this.salaId,
    required this.musicoId,
    required this.dataReserva,
    required this.horarioInicio,
    required this.horarioFim,
    this.status = 'PENDENTE',
    this.quantidadePessoas,
    this.equipamentos,
    this.mensagem,
    this.createdAt,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id:
          json['reserva_id'] ??
          json['id'] as String,
      salaId: json['sala_id'] as String,
      musicoId: json['musico_id'] as String,
      dataReserva: DateTime.parse(json['data_reserva']),
      horarioInicio: json['horario_inicio'] as String,
      horarioFim: json['horario_fim'] as String,
      status: json['status'] as String? ?? 'PENDENTE',
      quantidadePessoas: json['quantidade_pessoas'] as int?,
      equipamentos: json['equipamentos'] as String?,
      mensagem: json['mensagem'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'reserva_id': id,
      'sala_id': salaId,
      'musico_id': musicoId,
      'data_reserva': dataReserva.toIso8601String().split('T').first,
      'horario_inicio': horarioInicio,
      'horario_fim': horarioFim,
      'status': status,
      if (quantidadePessoas != null) 'quantidade_pessoas': quantidadePessoas,
      if (equipamentos != null) 'equipamentos': equipamentos,
      if (mensagem != null) 'mensagem': mensagem,
    };
  }
}
