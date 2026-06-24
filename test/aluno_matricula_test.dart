import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/alunos/repository/aluno_mapper.dart';

void main() {
  group('Aluno Matricula Tests', () {
    test('Aluno constructor and copyWith preserves matricula', () {
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
      );

      expect(aluno.matricula, '0015');

      final copied = aluno.copyWith(matricula: '0016');
      expect(copied.matricula, '0016');

      final copiedWithNull = aluno.copyWith(matricula: null);
      expect(copiedWithNull.matricula, '0015');
    });

    test('AlunoMapper.toFirestoreUpdate includes matricula', () {
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
      );

      final updateMap = AlunoMapper.toFirestoreUpdate(aluno);
      expect(updateMap['matricula'], '0015');
    });

    test('AlunoMapper.toFirestoreCreate includes matricula', () {
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
      );

      final createMap = AlunoMapper.toFirestoreCreate(aluno);
      expect(createMap['matricula'], '0020');
    });

    group('Proxima Matricula sequencing logic helper tests', () {
      // Replicates the logic of _calcularProximaMatricula(List<Aluno> alunos)
      String calcularProximaMatricula(List<Aluno> alunos) {
        var maxMatriculaInt = 0;
        for (final a in alunos) {
          if (a.matricula != null && a.matricula!.trim().isNotEmpty) {
            final parsed = int.tryParse(a.matricula!.replaceAll(RegExp(r'\D'), ''));
            if (parsed != null && parsed > maxMatriculaInt) {
              maxMatriculaInt = parsed;
            }
          }
        }
        return (maxMatriculaInt + 1).toString().padLeft(4, '0');
      }

      Aluno buildAlunoWithMatricula(String? matricula, {DateTime? criadoEm}) {
        return Aluno(
          id: 'test',
          nome: 'Test',
          telefone: '',
          observacao: '',
          diaVencimento: 10,
          mensalidade: 100.0,
          criadoEm: criadoEm ?? DateTime.now(),
          pagamentos: const {},
          matricula: matricula,
        );
      }

      test('generates 0001 for empty list of students', () {
        final result = calcularProximaMatricula([]);
        expect(result, '0001');
      });

      test('generates 0001 when no students have matricula', () {
        final result = calcularProximaMatricula([
          buildAlunoWithMatricula(null),
          buildAlunoWithMatricula(''),
          buildAlunoWithMatricula('   '),
        ]);
        expect(result, '0001');
      });

      test('sequencing increments based on the highest integer matrícula found', () {
        final result = calcularProximaMatricula([
          buildAlunoWithMatricula('0005'),
          buildAlunoWithMatricula('0012'),
          buildAlunoWithMatricula('0001'),
        ]);
        expect(result, '0013');
      });

      test('gracefully ignores non-numeric characters and finds highest sequence', () {
        final result = calcularProximaMatricula([
          buildAlunoWithMatricula('ABC-0042'),
          buildAlunoWithMatricula('0099'),
          buildAlunoWithMatricula('Invalid'),
        ]);
        // ABC-0042 becomes 42, 0099 becomes 99. Max is 99. Next is 100.
        expect(result, '0100');
      });
    });
  });
}
