import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:deubanda_app/viewmodels/matching_viewmodel.dart';

// 1. Mocks Principais
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

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

class MockTransformBuilderMap extends Mock
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final PostgrestMap? data;

  MockTransformBuilderMap([this.data]);

  @override
  Future<T> then<T>(
    FutureOr<T> Function(PostgrestMap?) onValue, {
    Function? onError,
  }) {
    return Future.value(data).then(onValue, onError: onError);
  }
}

void main() {
  late MatchingViewModel viewModel;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    // Configura o usuário autenticado falso
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    registerFallbackValue(<String, dynamic>{});
  });

  group('Testes de Estado Inicial e Variáveis', () {
    test('Valores iniciais devem estar vazios ou falsos', () {
      // O construtor inicia carregarFeed(), então preparamos a primeira consulta.
      final mockFilterList = MockFilterBuilderList([]);
      final mockTransformMap = MockTransformBuilderMap();
      when(
        () => mockSupabaseClient.from(any()),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select(any()),
      ).thenAnswer((_) => mockFilterList);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterList);
      when(
        () => mockFilterList.eq(any(), any()),
      ).thenAnswer((_) => mockFilterList);
      when(
        () => mockFilterList.maybeSingle(),
      ).thenAnswer((_) => mockTransformMap);

      viewModel = MatchingViewModel(client: mockSupabaseClient);

      expect(viewModel.musicosFeed, isEmpty);
      expect(viewModel.pedidosRecebidos, isEmpty);
      expect(viewModel.minhasConexoes, isEmpty);
      expect(viewModel.quantidadeConvitesPendentes, 0);
    });
  });

  group('Testes de Envio de Match', () {
    test(
      'Deve enviar match e remover músico do feed se a operação for bem sucedida',
      () async {
        final mockFeedFilter = MockFilterBuilderList([]);
        final mockMatchFilter = MockFilterBuilderList();
        final mockProfileFilter = MockFilterBuilderList();
        final mockTransformMapVazio = MockTransformBuilderMap();
        final mockTransformMapPerfil = MockTransformBuilderMap({
          'perfil_nome': 'João',
        });

        // 1. Prepara a consulta iniciada pelo construtor.
        when(
          () => mockSupabaseClient.from(any()),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.select(any()),
        ).thenAnswer((_) => mockFeedFilter);
        when(
          () => mockFeedFilter.eq(any(), any()),
        ).thenAnswer((_) => mockFeedFilter);
        when(
          () => mockFeedFilter.maybeSingle(),
        ).thenAnswer((_) => mockTransformMapVazio);
        when(
          () => mockQueryBuilder.select(),
        ).thenAnswer((_) => mockMatchFilter);
        when(
          () => mockQueryBuilder.select('perfil_nome'),
        ).thenAnswer((_) => mockProfileFilter);
        viewModel = MatchingViewModel(client: mockSupabaseClient);
        viewModel.musicosFeed.add({
          'perfil_id': 'outroUser456',
          'nome': 'Maria',
        });

        // 2. Simula que ainda não existe um match.
        when(
          () => mockSupabaseClient.from('matchings'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockMatchFilter.eq(any(), any()),
        ).thenAnswer((_) => mockMatchFilter);
        when(
          () => mockMatchFilter.maybeSingle(),
        ).thenAnswer((_) => mockTransformMapVazio);

        // 3. Mocka o insert do match e da notificação.
        when(
          () => mockQueryBuilder.insert(any()),
        ).thenAnswer((_) => mockMatchFilter);

        when(
          () => mockSupabaseClient.from('perfis_musicos'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockProfileFilter.eq(any(), any()),
        ).thenAnswer((_) => mockProfileFilter);
        when(
          () => mockProfileFilter.maybeSingle(),
        ).thenAnswer((_) => mockTransformMapPerfil);

        when(
          () => mockSupabaseClient.from('notificacoes'),
        ).thenAnswer((_) => mockQueryBuilder);

        final sucesso = await viewModel.enviarMatch('outroUser456');

        expect(sucesso, isTrue);
        expect(
          viewModel.musicosFeed
              .where((m) => m['perfil_id'] == 'outroUser456')
              .isEmpty,
          isTrue,
        );
      },
    );

    test(
      'Deve retornar false e não enviar se já existir um match pendente/ativo entre eles',
      () async {
        // Simula que JÁ EXISTE um match
        final mockTransformMapExistente = MockTransformBuilderMap({
          'match_id': 'match999',
          'match_status': 'PENDENTE',
        });
        final mockFeedFilter = MockFilterBuilderList([]);
        final mockFilterList = MockFilterBuilderList();

        when(
          () => mockSupabaseClient.from(any()),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.select(any()),
        ).thenAnswer((_) => mockFeedFilter);
        when(
          () => mockFeedFilter.eq(any(), any()),
        ).thenAnswer((_) => mockFeedFilter);
        when(
          () => mockFeedFilter.maybeSingle(),
        ).thenAnswer((_) => MockTransformBuilderMap());
        when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterList);
        when(
          () => mockFilterList.eq(any(), any()),
        ).thenAnswer((_) => mockFilterList);
        when(
          () => mockFilterList.maybeSingle(),
        ).thenAnswer((_) => MockTransformBuilderMap());
        viewModel = MatchingViewModel(client: mockSupabaseClient);

        // Configura a verificação do match existente para retornar o mapa do mock acima
        when(
          () => mockSupabaseClient.from('matchings'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterList);
        when(
          () => mockFilterList.maybeSingle(),
        ).thenAnswer((_) => mockTransformMapExistente);

        final sucesso = await viewModel.enviarMatch('alvo789');

        expect(sucesso, isFalse);
      },
    );
  });
}
