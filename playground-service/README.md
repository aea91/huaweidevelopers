# ArkTS Playground service

Every request goes through three steps:

1. **ArkTS check** (`arkts-check.js`): the code is checked as `main.ets` with
   `ohos-typescript` (OpenHarmony's TypeScript fork, used by DevEco's
   ets-loader). It reports `strict` TypeScript type errors and the official ArkTS
   1.1 linter rules (`arkts-no-any-unknown`, `arkts-no-var`,
   `arkts-no-untyped-obj-literals`, ...). If there is an error, the code is not
   compiled; the response has `stage: "check"` and a `diagnostics` list.
2. **Compile**: `es2abc` turns the source into `.abc` bytecode.
3. **Run**: the bytecode runs on `ark_js_vm`.

The API targets console programs only; ArkUI (`struct`, `@Component`, ...) is
not supported and no screen preview is produced. `print()` and `console.*`
can be used for output; `console` is mapped to `print` by a single-line
polyfill added at compile time.

Course starter code has a `declare function print(arg: any): any` line. Since
`print` comes from the check prelude, that exact line is skipped by the check.

## Toolchain

OpenHarmony ArkCompiler's Linux x64 `es2abc`, `ark_js_vm` and required shared
Place the libraries under `toolchain/`. Expected folder structure
Described in `toolchain/README.md`.

## Tests

```bash
npm ci
npm test
```

The check tests do not need the toolchain.

## Local execution

```bash
docker build -t arkuibuild-playground .
docker run --rm -p 8080:8080 arkuibuild-playground
curl http://localhost:8080/health
curl -X POST http://localhost:8080/run\
  -H 'Content-Type: application/json' \
  -d '{"code":"console.log(\"Hello ArkTS\")"}'
```

## Cloud Run

```bash
gcloud run deploy arkuibuild-playground \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --memory 1Gi \
  --cpu 1 \
  --concurrency 2 \
  --max-instances 5 \
  --set-env-vars ALLOWED_ORIGIN=https://YOUR_DOMAIN
```

Compile Flutter web app with service URL:

```bash
flutter build web \
  --dart-define=ARKTS_PLAYGROUND_API_URL=https://YOUR_CLOUD_RUN_URL
```

## Security limits

- Source code is limited to 64 KiB.
- Compilation and running processes are terminated after 5 seconds.
- Commands are not run via shell.
- Container works with non-root user.
- Do not provide application secrets or large authorized service accounts to the Cloud Run service.
- Add Cloud Armor/rate limiting and a dedicated service account in production.
