import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deubanda_app/viewmodels/estudio_viewmodel.dart';
import 'package:deubanda_app/models/estudio_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFilterBuilderList extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {
  final PostgrestList? data;

  MockFilterBuilderList([this.data]);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return Future.value(
      data ?? <Map<String, dynamic>>[],
    ).then(onValue, onError: onError);
  }
}

class MockTransformBuilderList extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {}

class MockTransformBuilderMap extends Mock
    implements PostgrestTransformBuilder<PostgrestMap> {
  final PostgrestMap? data;

  MockTransformBuilderMap([this.data]);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestMap) onValue, {
    Function? onError,
  }) {
    return Future.value(
      data ?? <String, dynamic>{},
    ).then(onValue, onError: onError);
  }
}

void main() {
  late EstudioViewModel viewModel;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    registerFallbackValue(<String, dynamic>{});

    viewModel = EstudioViewModel(client: mockSupabaseClient);
  });

  group('Testes de Estado e Limpeza', () {
    test('Deve limpar todos os dados da memória ao chamar limparDados()', () {
      viewModel.meuEstudio = EstudioModel(
        id: '1',
        donoId: '2',
        nome: 'A',
        telefone: '1',
        endereco: 'A',
      );
      viewModel.limparDados();
      expect(viewModel.meuEstudio, isNull);
    });
  });

  group('Testes de Banco de Dados - Estúdio', () {
    final mockEstudioMap = {
      'estudio_id': '123',
      'dono_id': 'dono123',
      'nome': 'Estúdio Teste',
      'telefone': '123456789',
      'endereco': 'Rua Teste',
    };
    final estudioModel = EstudioModel.fromJson(mockEstudioMap);

    test(
      'Deve salvar estúdio com sucesso, atualizar meuEstudio e retornar true',
      () async {
        final mockFilter = MockFilterBuilderList();
        final mockTransformList = MockTransformBuilderList();
        final mockTransformMap = MockTransformBuilderMap(mockEstudioMap);

        when(
          () => mockSupabaseClient.from('estudios'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.upsert(any()),
        ).thenAnswer((_) => mockFilter);
        when(() => mockFilter.select()).thenAnswer((_) => mockTransformList);
        when(
          () => mockTransformList.single(),
        ).thenAnswer((_) => mockTransformMap);

        final sucesso = await viewModel.salvarEstudio(estudioModel);

        expect(sucesso, isTrue);
        expect(viewModel.meuEstudio?.nome, 'Estúdio Teste');
        expect(viewModel.isLoading, isFalse);
      },
    );

    test(
      'Deve retornar false e preencher errorMessage se salvarEstudio falhar',
      () async {
        when(
          () => mockSupabaseClient.from('estudios'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.upsert(any()),
        ).thenThrow(Exception('Falha de conexão'));

        final sucesso = await viewModel.salvarEstudio(estudioModel);

        expect(sucesso, isFalse);
        expect(viewModel.meuEstudio, isNull);
        expect(viewModel.errorMessage, contains('Erro ao salvar estúdio'));
      },
    );
  });

  group('Testes de Banco de Dados - Salas', () {
    test('Deve carregar salas e atualizar a lista', () async {
      final mockSalasList = [
        {
          'sala_id': 's1',
          'estudio_id': '123',
          'nome_sala': 'Sala 1',
          'capacidade': 5,
          'preco_hora': 50.0,
          'is_ativo': true,
        },
      ];

      final mockFilter = MockFilterBuilderList(mockSalasList);

      when(
        () => mockSupabaseClient.from('salas'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any())).thenAnswer((_) => mockFilter);

      await viewModel.carregarSalas('123');

      expect(viewModel.minhasSalas.first.capacidade, 5);
      expect(viewModel.minhasSalas.first.id, 's1');
      expect(viewModel.minhasSalas.first.nomeSala, 'Sala 1');
    });
  });
}
