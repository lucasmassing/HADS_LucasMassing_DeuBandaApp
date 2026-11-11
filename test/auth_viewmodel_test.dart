import 'package:deubanda_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late AuthViewModel viewModel;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    viewModel = AuthViewModel(client: mockSupabaseClient);
  });

  group('Testes de Login', () {
    test('Deve retornar true e não ter erro quando o login for sucesso', () async {
      when(() => mockAuth.signInWithPassword(email: 'a@a.com', password: '123'))
          .thenAnswer((_) async => AuthResponse(session: null, user: null));

      final sucesso = await viewModel.fazerLogin('a@a.com', '123');

      expect(sucesso, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('Deve retornar false e salvar errorMessage quando o login falhar', () async {
      when(() => mockAuth.signInWithPassword(email: 'a@a.com', password: 'errado'))
          .thenThrow(const AuthException('Credenciais inválidas'));

      final sucesso = await viewModel.fazerLogin('a@a.com', 'errado');

      expect(sucesso, isFalse);
      expect(viewModel.errorMessage, 'Credenciais inválidas');
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('Testes de Cadastro', () {
    test('Deve retornar true quando o cadastro for sucesso', () async {
      when(() => mockAuth.signUp(
            email: 'novo@a.com',
            password: '123',
            data: {'full_name': 'Teste', 'tipo_perfil': 'Musico'},
          )).thenAnswer((_) async => AuthResponse(session: null, user: null));

      final sucesso = await viewModel.realizarCadastro(
        'Teste', 'novo@a.com', '123', 'Musico'
      );

      expect(sucesso, isTrue);
      expect(viewModel.errorMessage, isNull);
    });
  });
}