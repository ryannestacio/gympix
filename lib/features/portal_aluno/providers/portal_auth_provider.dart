import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../alunos/models/aluno.dart';
import '../../alunos/repository/aluno_mapper.dart';
import '../../cobranca/services/pix_payload_service.dart';

part 'portal_auth_provider.g.dart';

class PortalAuthState {
  const PortalAuthState({
    this.aluno,
    this.isLoading = false,
    this.error,
  });

  final Aluno? aluno;
  final bool isLoading;
  final String? error;

  PortalAuthState copyWith({
    Aluno? aluno,
    bool? isLoading,
    String? error,
    bool clearAluno = false,
    bool clearError = false,
  }) {
    return PortalAuthState(
      aluno: clearAluno ? null : (aluno ?? this.aluno),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class PortalAuth extends _$PortalAuth {
  @override
  PortalAuthState build() {
    return const PortalAuthState();
  }

  Future<bool> login(String matricula, String senha, String tenantId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final firestore = ref.read(firestoreProvider);
      
      if (tenantId.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Código da academia não informado.',
        );
        return false;
      }

      // Busca pelo aluno ativo correspondente à matrícula dentro da academia específica
      final query = await firestore
          .collection('tenants')
          .doc(tenantId.trim())
          .collection('alunos')
          .where('matricula', isEqualTo: matricula.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Matrícula não cadastrada.',
        );
        return false;
      }

      final doc = query.docs.first;
      final aluno = AlunoMapper.fromDoc(doc);

      if (!aluno.ativo) {
        state = state.copyWith(
          isLoading: false,
          error: 'Este aluno está inativo no sistema.',
        );
        return false;
      }

      // Se a senha estiver cadastrada no banco, valida. 
      // Caso contrário (vazio), o fallback de segurança é a própria matrícula.
      final senhaArmazenada = (aluno.senha ?? '').trim().isEmpty 
          ? aluno.matricula 
          : aluno.senha;

      if (senhaArmazenada != senha.trim()) {
        state = state.copyWith(
          isLoading: false,
          error: 'Senha incorreta.',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, aluno: aluno);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao conectar: ${e.toString()}',
      );
      return false;
    }
  }

  void logout() {
    state = const PortalAuthState();
  }
}

@riverpod
Future<String?> portalPixPayload(Ref ref) async {
  final authState = ref.watch(portalAuthProvider);
  final aluno = authState.aluno;
  if (aluno == null || aluno.tenantId == null) return null;

  final pagamento = aluno.pagamentoDoMes();
  final isPago = pagamento.status == PagamentoStatus.pago;
  final valor = isPago ? aluno.mensalidade : pagamento.valor;

  final db = ref.watch(firestoreProvider);
  final docRef = FirestoreRefs.tenantConfigDoc(db, aluno.tenantId!, FirestoreConfigDocs.pix);
  final doc = await docRef.get();
  final data = doc.data();

  final pixKey = data?['pixCode'] as String?;
  if (pixKey == null || pixKey.trim().isEmpty) {
    throw StateError('Chave Pix da academia não cadastrada.');
  }

  final normalizedKey = pixKey.trim();

  const service = PixPayloadService();
  return service.resolvePayload(
    pixCodeOrKey: normalizedKey,
    amount: valor,
    merchantName: 'GYMPIX',
    merchantCity: 'BRASIL',
    txid: _buildPixTxid(aluno.id),
  );
}

String _buildPixTxid(String alunoId) {
  final normalized = alunoId.toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]'),
    '',
  );
  if (normalized.isEmpty) return 'GYMPIX';
  final suffix = normalized.length <= 18
      ? normalized
      : normalized.substring(normalized.length - 18);
  return 'GYMPIX$suffix';
}
