import 'dart:async';

import 'package:deubanda_app/viewmodels/profile_viewmodel.dart';
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
  late ProfileViewModel viewModel;
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
    final mockTransformSingleEmpty = MockTransformBuilderSingle();

    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
    when(
      () => mockQueryBuilder.select(),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () => mockQueryBuilder.select(any()),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () =>
          mockFilterListEmpty.order(any(), ascending: any(named: 'ascending')),
    ).thenAnswer((_) => mockTransformListEmpty);
    when(
      () => mockFilterListEmpty.eq(any(), any()),
    ).thenAnswer((_) => mockFilterListEmpty);
    when(
      () => mockFilterListEmpty.maybeSingle(),
    ).thenAnswer((_) => mockTransformSingleEmpty);
  }

  group('Testes de Lógica de Estado (Síncrona)', () {
    test('Deve alternar a seleção de objetivos corretamente', () async {
      setupMockParaConstrutor();
      viewModel = ProfileViewModel(client: mockSupabaseClient);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.objetivosSelecionados, isEmpty);

      viewModel.alternarObjetivo('Banda Cover / Tributo');
      expect(
        viewModel.objetivosSelecionados.contains('Banda Cover / Tributo'),
        isTrue,
      );
      expect(viewModel.objetivosSelecionados.length, 1);

      viewModel.alternarObjetivo('Banda Cover / Tributo');
      expect(viewModel.objetivosSelecionados, isEmpty);
    });

    test(
      'Deve adicionar e remover um artista de referência (sem duplicados e limite de 5)',
      () async {
        setupMockParaConstrutor();

        final mockMutation = MockFilterBuilderDynamic();
        when(
          () => mockQueryBuilder.update(any()),
        ).thenAnswer((_) => mockMutation);
        when(
          () => mockMutation.eq(any(), any()),
        ).thenAnswer((_) => mockMutation);

        viewModel = ProfileViewModel(client: mockSupabaseClient);
        await Future<void>.delayed(Duration.zero);

        final artista1 = {'name': 'John Mayer', 'image': 'url1'};
        final artista2 = {'name': 'Eric Clapton', 'image': 'url2'};

        viewModel.adicionarArtista(artista1);
        viewModel.adicionarArtista(artista2);
        viewModel.adicionarArtista(artista1);

        expect(viewModel.artistasSelecionados.length, 2);

        viewModel.removerArtista('John Mayer');
        expect(viewModel.artistasSelecionados.length, 1);
        expect(viewModel.artistasSelecionados.first['name'], 'Eric Clapton');
      },
    );
  });

  group('Testes de Chamadas ao Supabase', () {
    test('Deve chamar a função upsert ao adicionar instrumento', () async {
      setupMockParaConstrutor();
      viewModel = ProfileViewModel(client: mockSupabaseClient);
      await Future<void>.delayed(Duration.zero);

      final mockFilterListEmpty = MockFilterBuilderList();
      when(
        () => mockSupabaseClient.from('musico_instrumentos'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenAnswer((_) => mockFilterListEmpty);

      final resultado = await viewModel.adicionarInstrumento(
        1,
        'Intermediário',
      );

      expect(resultado, isTrue);
      verify(
        () => mockQueryBuilder.upsert({
          'musico_id': 'user123',
          'instrumento_id': 1,
          'instrumento_nivel': 'Intermediário',
        }),
      ).called(1);
    });
  });
}
