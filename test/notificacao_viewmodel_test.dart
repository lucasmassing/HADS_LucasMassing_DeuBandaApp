import 'dart:async';

import 'package:deubanda_app/viewmodels/notificacao_viewmodel.dart';
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
  late NotificacaoViewModel viewModel;
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

  group('Testes de Notificação', () {
    final mockNotificacoesList = [
      {'id': '1', 'mensagem': 'Msg 1', 'lida': false, 'perfil_id': 'user123'},
      {'id': '2', 'mensagem': 'Msg 2', 'lida': true, 'perfil_id': 'user123'},
    ];

    test(
      'Deve carregar as notificações no arranque e contar as não lidas',
      () async {
        final mockFilter = MockFilterBuilderList();
        final mockTransform = MockTransformBuilderList(mockNotificacoesList);

        when(
          () => mockSupabaseClient.from('notificacoes'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilter);
        when(() => mockFilter.eq(any(), any())).thenAnswer((_) => mockFilter);
        when(
          () => mockFilter.order(any(), ascending: any(named: 'ascending')),
        ).thenAnswer((_) => mockTransform);

        viewModel = NotificacaoViewModel(client: mockSupabaseClient);

        await Future<void>.delayed(Duration.zero);

        expect(viewModel.notificacoes.length, 2);
        expect(viewModel.notificacoesNaoLidas, 1);
      },
    );

    test('Deve marcar notificação como lida e recarregar a lista', () async {
      final mockFilterListEmpty = MockFilterBuilderList();
      final mockTransformEmpty = MockTransformBuilderList();
      final mockMutation = MockFilterBuilderDynamic();

      when(
        () => mockSupabaseClient.from('notificacoes'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select(),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.eq(any(), any()),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.order(
          any(),
          ascending: any(named: 'ascending'),
        ),
      ).thenAnswer((_) => mockTransformEmpty);

      viewModel = NotificacaoViewModel(client: mockSupabaseClient);
      await Future<void>.delayed(Duration.zero);

      when(
        () => mockQueryBuilder.update(any()),
      ).thenAnswer((_) => mockMutation);
      when(() => mockMutation.eq(any(), any())).thenAnswer((_) => mockMutation);

      await viewModel.marcarNotificacaoComoLida('1');

      verify(() => mockQueryBuilder.update({'lida': true})).called(1);
    });

    test('Deve enviar notificação corretamente', () async {
      final mockFilterListEmpty = MockFilterBuilderList();
      final mockTransformEmpty = MockTransformBuilderList();
      final mockMutation = MockFilterBuilderDynamic();

      when(
        () => mockSupabaseClient.from('notificacoes'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select(),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.eq(any(), any()),
      ).thenAnswer((_) => mockFilterListEmpty);
      when(
        () => mockFilterListEmpty.order(
          any(),
          ascending: any(named: 'ascending'),
        ),
      ).thenAnswer((_) => mockTransformEmpty);

      viewModel = NotificacaoViewModel(client: mockSupabaseClient);

      when(
        () => mockQueryBuilder.insert(any()),
      ).thenAnswer((_) => mockMutation);

      await viewModel.enviarNotificacao(
        perfilId: 'outroUser',
        mensagem: 'Olá, tens um match!',
      );

      verify(
        () => mockQueryBuilder.insert({
          'perfil_id': 'outroUser',
          'mensagem': 'Olá, tens um match!',
          'telefone_contato': null,
        }),
      ).called(1);
    });
  });
}
