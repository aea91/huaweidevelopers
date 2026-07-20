# ArkCompiler toolchain

This folder was created with Linux x64 ArkCompiler outputs before the Docker image was created.
must be filled. The portable package produced from OpenHarmony resources has the following structure
should be:

```text
toolchain/
  bin/
    es2abc
    ark_js_vm
  lib/
    *.so
```

`es2abc` and `ark_js_vm` must be executable (`chmod +x`). Compiler and
runtime must be generated from the same OpenHarmony version. This is not an official version for binaries.
Since there is no ready download package, they are not added to the repo.
