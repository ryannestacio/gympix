import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-gympix';
const FIRESTORE_HOST = '127.0.0.1';
const FIRESTORE_PORT = 8080;

let testEnv;

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

async function seedTenantMembership({
  uid,
  tenantId = uid,
  role = 'owner',
  memberAtivo = true,
  memberStatus = 'ativo',
  tenantAtivo = true,
  tenantStatus = 'ativo',
}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, 'user_tenants', uid), {
      tenantId,
      role,
      ativo: memberAtivo,
      status: memberStatus,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await setDoc(doc(adminDb, 'tenants', tenantId), {
      tenantId,
      nome: `Tenant ${tenantId}`,
      ativo: tenantAtivo,
      status: tenantStatus,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
}

before(async () => {
  const rules = readFileSync('firestore.rules', 'utf8');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: FIRESTORE_HOST,
      port: FIRESTORE_PORT,
      rules,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('Firestore security rules (multi-tenant)', () => {
  test('deny reads for unauthenticated users', async () => {
    await seedTenantMembership({ uid: 'tenant_admin' });
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDoc(doc(db, 'tenants', 'tenant_admin')));
    await assertFails(getDoc(doc(db, 'user_tenants', 'tenant_admin')));
  });

  test('allow bootstrap create for own tenant and own membership', async () => {
    const uid = 'owner_bootstrap';
    const db = authedDb(uid);

    await assertSucceeds(
      setDoc(doc(db, 'tenants', uid), {
        tenantId: uid,
        nome: 'Meu tenant',
        ativo: true,
        status: 'ativo',
      }),
    );

    await assertSucceeds(
      setDoc(doc(db, 'user_tenants', uid), {
        tenantId: uid,
        role: 'owner',
        ativo: true,
        status: 'ativo',
      }),
    );

    await assertSucceeds(
      setDoc(doc(db, 'tenants', uid, 'config', 'app'), {
        tenantId: uid,
        ativo: true,
        status: 'ativo',
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'tenants', uid, 'config', 'pix'), {
        tenantId: uid,
        ativo: true,
        status: 'ativo',
      }),
    );
  });

  test('deny bootstrap writes outside allowed docs', async () => {
    const uid = 'owner_bootstrap';
    const db = authedDb(uid);

    await assertFails(
      setDoc(doc(db, 'user_tenants', 'other_uid'), {
        tenantId: uid,
        role: 'owner',
        ativo: true,
        status: 'ativo',
      }),
    );

    await assertFails(
      setDoc(doc(db, 'tenants', uid, 'config', 'secreto'), {
        tenantId: uid,
        ativo: true,
        status: 'ativo',
      }),
    );
  });

  test('allow tenant member to CRUD allowed resources in own tenant', async () => {
    const uid = 'alice';
    const tenantId = 'tenant_admin';
    await seedTenantMembership({ uid, tenantId });
    const db = authedDb(uid);

    await assertSucceeds(getDoc(doc(db, 'tenants', tenantId)));

    const alunoRef = doc(db, 'tenants', tenantId, 'alunos', 'aluno_1');
    await assertSucceeds(
      setDoc(alunoRef, {
        tenantId,
        nome: 'Aluno 1',
        diaVencimento: 10,
        mensalidade: 100,
        ativo: true,
        status: 'ativo',
      }),
    );
    await assertSucceeds(updateDoc(alunoRef, { observacao: 'ok' }));
    await assertSucceeds(getDoc(alunoRef));

    await assertSucceeds(
      setDoc(doc(db, 'tenants', tenantId, 'config', 'app'), {
        tenantId,
        ativo: true,
        status: 'ativo',
      }),
    );

    await assertSucceeds(
      setDoc(doc(db, 'tenants', tenantId, 'cobranca_push_queue', 'job_1'), {
        tenantId,
        mensagem: 'teste',
      }),
    );
  });

  test('deny cross-tenant access', async () => {
    await seedTenantMembership({ uid: 'alice', tenantId: 'tenant_a' });
    await seedTenantMembership({ uid: 'bob', tenantId: 'tenant_b' });
    const aliceDb = authedDb('alice');

    await assertFails(getDoc(doc(aliceDb, 'tenants', 'tenant_b')));
    await assertFails(
      setDoc(doc(aliceDb, 'tenants', 'tenant_b', 'alunos', 'a1'), {
        tenantId: 'tenant_b',
        nome: 'Invasao',
      }),
    );
  });

  test('deny writes when tenantId field does not match route tenant', async () => {
    const uid = 'alice';
    const tenantId = 'tenant_admin';
    await seedTenantMembership({ uid, tenantId });
    const db = authedDb(uid);

    await assertFails(
      setDoc(doc(db, 'tenants', tenantId, 'alunos', 'aluno_bad'), {
        tenantId: 'tenant_outro',
        nome: 'Aluno invalido',
      }),
    );

    await assertFails(
      setDoc(doc(db, 'tenants', tenantId, 'cobranca_push_queue', 'job_bad'), {
        tenantId: 'tenant_outro',
      }),
    );
  });

  test('deny delete operations for protected collections', async () => {
    const uid = 'alice';
    const tenantId = 'tenant_admin';
    await seedTenantMembership({ uid, tenantId });

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await setDoc(doc(adminDb, 'tenants', tenantId, 'alunos', 'aluno_1'), {
        tenantId,
        nome: 'Aluno 1',
      });
    });

    const db = authedDb(uid);
    await assertFails(deleteDoc(doc(db, 'tenants', tenantId, 'alunos', 'aluno_1')));
    await assertFails(deleteDoc(doc(db, 'tenants', tenantId)));
  });

  test('deny access when membership is inactive', async () => {
    const uid = 'alice';
    const tenantId = 'tenant_admin';
    await seedTenantMembership({
      uid,
      tenantId,
      memberAtivo: false,
      memberStatus: 'inativo',
    });
    const db = authedDb(uid);

    await assertFails(getDoc(doc(db, 'tenants', tenantId)));
    await assertFails(
      setDoc(doc(db, 'tenants', tenantId, 'alunos', 'aluno_1'), {
        tenantId,
        nome: 'Aluno 1',
      }),
    );
  });

  test('deny list on user_tenants even for authenticated user', async () => {
    const uid = 'alice';
    await seedTenantMembership({ uid, tenantId: 'tenant_admin' });
    const db = authedDb(uid);

    const q = query(collection(db, 'user_tenants'), limit(1));
    await assertFails(getDocs(q));
  });

  test('allow own user_tenants get and deny others', async () => {
    await seedTenantMembership({ uid: 'alice', tenantId: 'tenant_admin' });
    await seedTenantMembership({ uid: 'bob', tenantId: 'tenant_admin' });
    const aliceDb = authedDb('alice');

    await assertSucceeds(getDoc(doc(aliceDb, 'user_tenants', 'alice')));
    await assertFails(getDoc(doc(aliceDb, 'user_tenants', 'bob')));
  });
});

test('sanity: environment initialized', () => {
  assert.ok(testEnv);
});
