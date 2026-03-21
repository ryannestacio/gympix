import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/core/utils/operation_lock.dart';

void main() {
  group('OperationLock', () {
    test(
      'evita execucao duplicada para o mesmo operationId em paralelo',
      () async {
        final lock = OperationLock();
        final release = Completer<void>();
        var calls = 0;

        Future<void> action() async {
          calls++;
          await release.future;
        }

        final first = lock.run('aluno:1:pagamento', action);
        final second = lock.run('aluno:1:pagamento', action);

        expect(calls, 1);
        expect(lock.isRunning('aluno:1:pagamento'), isTrue);
        expect(identical(first, second), isTrue);

        release.complete();
        await Future.wait([first, second]);
        expect(lock.isRunning('aluno:1:pagamento'), isFalse);
      },
    );

    test('permite nova execucao apos concluir a operacao anterior', () async {
      final lock = OperationLock();
      var calls = 0;

      Future<void> action() async {
        calls++;
      }

      await lock.run('aluno:1:inativar', action);
      await lock.run('aluno:1:inativar', action);

      expect(calls, 2);
    });

    test('permite operacoes diferentes em paralelo', () async {
      final lock = OperationLock();
      final release = Completer<void>();
      final executed = <String>[];

      Future<void> action(String id) async {
        executed.add(id);
        await release.future;
      }

      final first = lock.run('op-a', () => action('a'));
      final second = lock.run('op-b', () => action('b'));

      expect(executed, containsAll(<String>['a', 'b']));

      release.complete();
      await Future.wait([first, second]);
    });
  });
}
