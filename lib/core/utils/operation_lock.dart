class OperationLock {
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  bool isRunning(String operationId) => _inFlight.containsKey(operationId);

  Future<void> run(String operationId, Future<void> Function() action) {
    final existing = _inFlight[operationId];
    if (existing != null) return existing;

    late final Future<void> future;
    future = Future.sync(action).whenComplete(() {
      _inFlight.remove(operationId);
    });
    _inFlight[operationId] = future;
    return future;
  }
}
