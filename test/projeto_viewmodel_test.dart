import 'dart:async';

import 'package:deubanda_app/models/projeto.dart';
import 'package:deubanda_app/viewmodels/projeto_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFilterBuilderList extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {
  final PostgrestList data;

  MockFilterBuilderList([PostgrestList? data]) : data = data ?? [];

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestList>.value(data).then(onValue, onError: onError);
  }
}

class MockTransformBuilderList extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {
  final PostgrestList data;

  MockTransformBuilderList([PostgrestList? data]) : data = data ?? [];

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestList>.value(data).then(onValue, onError: onError);
  }
}

class MockTransformBuilderSingle extends Mock
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final PostgrestMap? data;

  MockTransformBuilderSingle([this.data]);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestMap?) onValue, {
    Function? onError,
  }) {
    return Future<PostgrestMap?>.value(data).then(onValue, onError: onError);
  }
}

class MockFilterBuilderDynamic extends Mock
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<T> then<T>(
    FutureOr<T> Function(dynamic) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value().then(onValue, onError: onError);
  }
}

void main() {
  late ProjetoViewModel viewModel;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    registerFallbackValue(<String, dynamic>{});
  });

  void setupMockParaConstrutor() {
    final mockFilterListEmpty = MockFilterBuilderList();
    final mockTransformListEmpty = MockTransformBuilderList();

    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
    when(
      () => mockQueryBuilder.select(any()),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () => mockQueryBuilder.select(),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () => mockFilterListEmpty.eq(any(), any()),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () =>
          mockFilterListEmpty.order(any(), ascending: any(named: 'ascending')),
    ).thenAnswer((_) => mockTransformListEmpty);
  }

  group('Testes de Gerenciamento de Projetos e Vagas', () {
    test(
      'Deve adicionar e remover funções (instrumentos buscados) da vaga',
      () async {
        setupMockParaConstrutor();
        viewModel = ProjetoViewModel(client: mockSupabaseClient);
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.funcoesSelecionadas, isEmpty);

        viewModel.adicionarFuncao('Guitarra');
        viewModel.adicionarFuncao('Bateria');

        expect(viewModel.funcoesSelecionadas.length, 2);
        expect(viewModel.funcoesSelecionadas.contains('Bateria'), isTrue);

        viewModel.removerFuncao('Guitarra');

        expect(viewModel.funcoesSelecionadas.length, 1);
        expect(viewModel.funcoesSelecionadas.contains('Guitarra'), isFalse);
      },
    );

    test('Deve criar projeto e recarregar a lista', () async {
      setupMockParaConstrutor();
      viewModel = ProjetoViewModel(client: mockSupabaseClient);
      await Future<void>.delayed(Duration.zero);

      final projetoNovo = Projeto(
        criadorId: 'user123',
        projetoTitulo: 'Banda de Rock',
        projetoDescricao: 'Buscamos vocalista',
      );

      final mockFilterListEmpty = MockFilterBuilderList();
      when(
        () => mockSupabaseClient.from('projetos'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert(any()),
      ).thenAnswer((_) => MockFilterBuilderDynamic());
      when(
        () => mockQueryBuilder.select(any()),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.eq(any(), any()),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.order(
          any(),
          ascending: any(named: 'ascending'),
        ),
      ).thenAnswer((_) => MockTransformBuilderList());

      final sucesso = await viewModel.criarProjeto(projetoNovo);

      expect(sucesso, isTrue);
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('Testes de Candidaturas', () {
    test('Deve impedir candidatura duplicada no mesmo projeto', () async {
      setupMockParaConstrutor();
      viewModel = ProjetoViewModel(client: mockSupabaseClient);
      await Future<void>.delayed(Duration.zero);

      final projeto = Projeto(
        projetoId: 'proj999',
        criadorId: 'dono123',
        projetoTitulo: 'Projeto Teste',
      );

      final mockSingleExistente = MockTransformBuilderSingle({
        'candidatura_id': 'cand1',
      });
      final mockFilterList = MockFilterBuilderList();

      when(
        () => mockSupabaseClient.from('candidaturas'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterList);
      when(
        () => mockFilterList.eq(any(), any()),
      ).thenAnswer((_) => mockFilterList);
      when(
        () => mockFilterList.maybeSingle(),
      ).thenAnswer((_) => mockSingleExistente);

      final sucesso = await viewModel.candidatarSe(projeto);

      expect(sucesso, isFalse);
      expect(viewModel.errorMessage, 'Você já se candidatou a esta vaga!');
    });

    test(
      'Deve atualizar status da candidatura (Aceitar Candidato) e notificar',
      () async {
        setupMockParaConstrutor();
        viewModel = ProjetoViewModel(client: mockSupabaseClient);
        await Future<void>.delayed(Duration.zero);

        final mockMutation = MockFilterBuilderDynamic();
        final mockSinglePerfil = MockTransformBuilderSingle({
          'perfil_telefone': '912345678',
        });

        when(
          () => mockSupabaseClient.from('candidaturas'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.update(any()),
        ).thenAnswer((_) => mockMutation);
        when(
          () => mockMutation.eq(any(), any()),
        ).thenAnswer((_) => mockMutation);

        when(
          () => mockSupabaseClient.from('perfis_musicos'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockSupabaseClient.from('notificacoes'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.insert(any()),
        ).thenAnswer((_) => MockFilterBuilderDynamic());

        final perfilFilter = MockFilterBuilderList();
        when(
          () => mockQueryBuilder.select('perfil_telefone'),
        ).thenAnswer((_) => perfilFilter);
        when(
          () => perfilFilter.eq(any(), any()),
        ).thenAnswer((_) => perfilFilter);
        when(
          () => perfilFilter.maybeSingle(),
        ).thenAnswer((_) => mockSinglePerfil);

        final sucesso = await viewModel.atualizarStatusCandidatura(
          'cand1',
          'ACEITO',
          'candidato456',
          'Vaga de Bateria',
        );

        expect(sucesso, isTrue);
        verify(() => mockSupabaseClient.from('notificacoes')).called(1);
      },
    );
  });
}
