# Firestore Deploy Checklist (Controlled)

Use this checklist every time you publish `firestore.rules` and `firestore.indexes.json`.

## 1. Pre-deploy validation

- [ ] Confirm branch/commit that will be deployed.
- [ ] Confirm target Firebase project id.
- [ ] Run Flutter tests:
  - `flutter test`
- [ ] Run Firestore rule tests on Emulator:
  - `npm run emulator:test:firestore`
- [ ] Confirm `firestore.rules` and `firestore.indexes.json` contain only intended changes.

## 2. Controlled release snapshot

- [ ] Generate a versioned snapshot and validation report:
  - `powershell -ExecutionPolicy Bypass -File scripts/firestore_deploy_controlled.ps1 -ProjectId <seu-project-id> -SkipDeploy`
- [ ] Check folder generated in `docs/deployments/firestore/<releaseVersion>/`.
- [ ] Check `manifest.json` (hashes, status, project, commit).

## 3. Publish

- [ ] Deploy rules and indexes:
  - `powershell -ExecutionPolicy Bypass -File scripts/firestore_deploy_controlled.ps1 -ProjectId <seu-project-id>`
- [ ] If needed, deploy only one artifact:
  - rules: `-DeployScope rules`
  - indexes: `-DeployScope indexes`

## 4. Post-deploy validation

- [ ] Login and basic app smoke test.
- [ ] Confirm key Firestore flows (alunos, config, cobranca, relatorios).
- [ ] Confirm no spikes in `PERMISSION_DENIED`.
- [ ] Confirm no `FAILED_PRECONDITION` caused by missing index.
- [ ] Save any deployment evidence (logs/screenshot/commit id) with release notes.
