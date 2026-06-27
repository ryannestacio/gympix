// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gympix/core/providers/firebase_providers.dart';
import 'package:gympix/features/portal_aluno/providers/portal_auth_provider.dart';

class _FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data);
  final Map<String, dynamic> _data;

  @override
  String get id => 'aluno-teste-id';

  @override
  Map<String, dynamic> data() => _data;

  @override
  SnapshotMetadata get metadata => _FakeSnapshotMetadata();
}

class _FakeSnapshotMetadata extends Fake implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this._docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  int get size => _docs.length;
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  _FakeQuery(this._snapshot);
  final QuerySnapshot<Map<String, dynamic>> _snapshot;

  @override
  Query<Map<String, dynamic>> limit(int limit) => this;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async => _snapshot;
}

class _FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._collection);
  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _collection;
  }
}

class _FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this._query);
  final Query<Map<String, dynamic>> _query;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _FakeDocumentReference(this);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return _query;
  }
}

class _FakeFirestore extends Fake implements FirebaseFirestore {
  _FakeFirestore(this._collection);
  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _collection;
  }

  @override
  Query<Map<String, dynamic>> collectionGroup(String collectionPath) {
    return _collection;
  }
}

void main() {
  group('PortalAuthProvider', () {
    test('login com sucesso - matrícula e senha corretas', () async {
      final docSnapshot = _FakeQueryDocumentSnapshot({
        'nome': 'Arthur Dent',
        'telefone': '11988888888',
        'observacao': '',
        'diaVencimento': 10,
        'mensalidade': 120.0,
        'ativo': true,
        'matricula': '42',
        'senha': 'forty-two',
        'tenantId': 'tenant-earth',
      });
      final querySnapshot = _FakeQuerySnapshot([docSnapshot]);
      final query = _FakeQuery(querySnapshot);
      final collection = _FakeCollectionReference(query);
      final firestore = _FakeFirestore(collection);

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
        ],
      );

      final notifier = container.read(portalAuthProvider.notifier);
      final ok = await notifier.login('42', 'forty-two', 'tenant-earth');

      expect(ok, isTrue);
      final state = container.read(portalAuthProvider);
      expect(state.aluno, isNotNull);
      expect(state.aluno!.nome, 'Arthur Dent');
      expect(state.aluno!.tenantId, 'tenant-earth');
      expect(state.error, isNull);
    });

    test('login falha - senha incorreta', () async {
      final docSnapshot = _FakeQueryDocumentSnapshot({
        'nome': 'Arthur Dent',
        'telefone': '11988888888',
        'observacao': '',
        'diaVencimento': 10,
        'mensalidade': 120.0,
        'ativo': true,
        'matricula': '42',
        'senha': 'forty-two',
      });
      final querySnapshot = _FakeQuerySnapshot([docSnapshot]);
      final query = _FakeQuery(querySnapshot);
      final collection = _FakeCollectionReference(query);
      final firestore = _FakeFirestore(collection);

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
        ],
      );

      final notifier = container.read(portalAuthProvider.notifier);
      final ok = await notifier.login('42', 'senha-errada', 'tenant-earth');

      expect(ok, isFalse);
      final state = container.read(portalAuthProvider);
      expect(state.aluno, isNull);
      expect(state.error, 'Senha incorreta.');
    });

    test('login com sucesso - senha padrão (igual matrícula)', () async {
      final docSnapshot = _FakeQueryDocumentSnapshot({
        'nome': 'Arthur Dent',
        'telefone': '11988888888',
        'observacao': '',
        'diaVencimento': 10,
        'mensalidade': 120.0,
        'ativo': true,
        'matricula': '42',
        'senha': '', // Vazia
      });
      final querySnapshot = _FakeQuerySnapshot([docSnapshot]);
      final query = _FakeQuery(querySnapshot);
      final collection = _FakeCollectionReference(query);
      final firestore = _FakeFirestore(collection);

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
        ],
      );

      final notifier = container.read(portalAuthProvider.notifier);
      final ok = await notifier.login('42', '42', 'tenant-earth'); // Usando a matrícula como senha

      expect(ok, isTrue);
      final state = container.read(portalAuthProvider);
      expect(state.aluno, isNotNull);
      expect(state.error, isNull);
    });

    test('login falha - matrícula não cadastrada', () async {
      final querySnapshot = _FakeQuerySnapshot([]); // Retorna nada
      final query = _FakeQuery(querySnapshot);
      final collection = _FakeCollectionReference(query);
      final firestore = _FakeFirestore(collection);

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
        ],
      );

      final notifier = container.read(portalAuthProvider.notifier);
      final ok = await notifier.login('999', 'senha', 'tenant-earth');

      expect(ok, isFalse);
      final state = container.read(portalAuthProvider);
      expect(state.aluno, isNull);
      expect(state.error, 'Matrícula não cadastrada.');
    });

    test('login falha - aluno inativo', () async {
      final docSnapshot = _FakeQueryDocumentSnapshot({
        'nome': 'Arthur Dent',
        'telefone': '11988888888',
        'observacao': '',
        'diaVencimento': 10,
        'mensalidade': 120.0,
        'ativo': false, // Inativo
        'matricula': '42',
        'senha': 'forty-two',
      });
      final querySnapshot = _FakeQuerySnapshot([docSnapshot]);
      final query = _FakeQuery(querySnapshot);
      final collection = _FakeCollectionReference(query);
      final firestore = _FakeFirestore(collection);

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
        ],
      );

      final notifier = container.read(portalAuthProvider.notifier);
      final ok = await notifier.login('42', 'forty-two', 'tenant-earth');

      expect(ok, isFalse);
      final state = container.read(portalAuthProvider);
      expect(state.aluno, isNull);
      expect(state.error, 'Este aluno está inativo no sistema.');
    });
  });
}
