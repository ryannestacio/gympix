// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/alunos/repository/aluno_mapper.dart';

class _FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  SnapshotMetadata get metadata => _FakeSnapshotMetadata();
}

class _FakeSnapshotMetadata extends Fake implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;
}

void main() {
  group('Aluno Senha Tests', () {
    test('Aluno constructor and copyWith preserves senha', () {
      final aluno = Aluno(
        id: '123',
        nome: 'João da Silva',
        telefone: '(11) 98765-4321',
        observacao: 'Observação teste',
        diaVencimento: 10,
        mensalidade: 150.0,
        criadoEm: DateTime(2026, 1, 1),
        pagamentos: const {},
        matricula: '0015',
        senha: 'senha-secreta',
      );

      expect(aluno.senha, 'senha-secreta');

      final copied = aluno.copyWith(senha: 'nova-senha');
      expect(copied.senha, 'nova-senha');

      final copiedWithNull = aluno.copyWith(senha: null);
      expect(copiedWithNull.senha, 'senha-secreta'); // copyWith preserves existing value when null is passed (if defined like that)
    });

    test('AlunoMapper.toFirestoreUpdate includes senha', () {
      final aluno = Aluno(
        id: '123',
        nome: 'João da Silva',
        telefone: '(11) 98765-4321',
        observacao: 'Observação teste',
        diaVencimento: 10,
        mensalidade: 150.0,
        criadoEm: DateTime(2026, 1, 1),
        pagamentos: const {},
        matricula: '0015',
        senha: 'senha-atualizar',
      );

      final updateMap = AlunoMapper.toFirestoreUpdate(aluno);
      expect(updateMap['senha'], 'senha-atualizar');
    });

    test('AlunoMapper.toFirestoreCreate includes senha', () {
      final aluno = Aluno(
        id: '123',
        nome: 'João da Silva',
        telefone: '(11) 98765-4321',
        observacao: 'Observação teste',
        diaVencimento: 10,
        mensalidade: 150.0,
        criadoEm: DateTime(2026, 1, 1),
        pagamentos: const {},
        matricula: '0020',
        senha: 'senha-criar',
      );

      final createMap = AlunoMapper.toFirestoreCreate(aluno);
      expect(createMap['senha'], 'senha-criar');
    });

    test('AlunoMapper.fromDoc parses senha and tenantId', () {
      final doc = _FakeDocumentSnapshot('aluno-id-123', {
        'nome': 'João da Silva',
        'telefone': '(11) 98765-4321',
        'observacao': 'Obs',
        'diaVencimento': 10,
        'mensalidade': 150.0,
        'criadoEm': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'ativo': true,
        'matricula': '0015',
        'senha': 'senha-firestore',
        'tenantId': 'tenant-test-123',
      });

      final parsed = AlunoMapper.fromDoc(doc);
      expect(parsed.senha, 'senha-firestore');
      expect(parsed.tenantId, 'tenant-test-123');
    });
  });
}
