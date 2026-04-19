import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/core/utils/firestore_error_formatter.dart';

FirebaseException _makeException({required String code, String? message}) {
  return FirebaseException(
    plugin: 'cloud_firestore',
    code: code,
    message: message,
  );
}

void main() {
  group('formatFirestoreError', () {
    test('retorna mensagem generica para nao-FirebaseException', () {
      final result = formatFirestoreError(Exception('generic error'));
      expect(result, 'Ocorreu um erro inesperado. Tente novamente.');
    });

    test('codigo unavailable retorna mensagem de conexao', () {
      final result = formatFirestoreError(_makeException(code: 'unavailable'));
      expect(result, contains('Servico temporariamente indisponivel'));
    });

    test('codigo permission-denied retorna mensagem de permissao', () {
      final result = formatFirestoreError(
        _makeException(code: 'permission-denied'),
      );
      expect(result, contains('nao tem permissao'));
    });

    test('codigo not-found retorna mensagem de registro nao encontrado', () {
      final result = formatFirestoreError(_makeException(code: 'not-found'));
      expect(result, contains('nao encontrado'));
    });

    test('codigo unknown retorna fallback', () {
      final result = formatFirestoreError(_makeException(code: 'unknown'));
      expect(result, 'Ocorreu um erro inesperado. Tente novamente.');
    });

    test('codigo nao mapeado retorna fallback generico do Firestore', () {
      final result = formatFirestoreError(
        _makeException(code: 'some-random-code'),
      );
      expect(result, 'Erro ao acessar dados. Tente novamente.');
    });

    test('codigo network-request-failed retorna mensagem de rede', () {
      final result = formatFirestoreError(
        _makeException(code: 'network-request-failed'),
      );
      expect(result, contains('Falha de rede'));
    });

    test('codigo resource-exhausted retorna mensagem de limite', () {
      final result = formatFirestoreError(
        _makeException(code: 'resource-exhausted'),
      );
      expect(result, contains('Limite de operacoes excedido'));
    });
  });
}
