class FirestoreFields {
  static const String tenantId = 'tenantId';
  static const String role = 'role';
  static const String status = 'status';
  static const String ativo = 'ativo';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String docType = 'docType';
  static const String schemaVersion = 'schemaVersion';
}

class FirestoreStatus {
  static const String ativo = 'ativo';
  static const String inativo = 'inativo';
  static const String arquivado = 'arquivado';
  static const String aberto = 'aberto';
  static const String fechado = 'fechado';
}

class FirestoreDocTypes {
  static const String appConfig = 'app_config';
  static const String pixConfig = 'pix_config';
  static const String aluno = 'aluno';
  static const String fechamentoMensal = 'fechamento_mensal';
}
