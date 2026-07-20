# ArkTS Playground service

Converts the ArkTS/TypeScript source to bytecode `es2abc` and `.abc` and
Runs on `ark_js_vm`. The API targets console programs only;
ArkUI does not produce screen previews.

## Toolchain

OpenHarmony ArkCompiler's Linux x64 `es2abc`, `ark_js_vm` and required shared
Place the libraries under `toolchain/`. Expected folder structure
Described in `toolchain/README.md`.

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
