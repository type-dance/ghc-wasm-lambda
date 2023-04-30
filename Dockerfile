FROM arm64v8/alpine:edge

ENV \
  LANG=C.UTF-8 \
  PATH=/root/.local/bin:/tmp/ghc-boot/_build/stage1/bin:${PATH}

RUN \
  apk update && \
  apk upgrade && \
  apk add \
    alpine-sdk \
    autoconf \
    automake \
    bash \
    cabal \
    coreutils \
    git \
    grep \
    gzip \
    llvm15 \
    musl-locales \
    ncurses-dev \
    ncurses-static \
    py3-sphinx \
    sed \
    unzip && \
  cabal update && \
  cabal install \
    alex \
    happy && \
  git clone --depth=1 --recursive --shallow-submodules -c fetch.parallel=0 -c submodule.fetchJobs=0 https://gitlab.haskell.org/ghc/ghc.git /tmp/ghc-boot && \
  cd /tmp/ghc-boot && \
  cd utils/hsc2hs && \
  curl -f -L --retry 5 https://patch-diff.githubusercontent.com/raw/haskell/hsc2hs/pull/76.patch | git apply && \
  cd ../.. && \
  ./boot && \
  ./configure \
    --with-intree-gmp \
    LLC=/usr/bin/llc15 \
    OPT=/usr/bin/opt15 && \
  hadrian/build --flavour=perf+llvm+no_profiled_libs "stage1.*.ghc.hs.opts += -split-sections" --docs=none -j && \
  cd $(mktemp -d) && \
  mkdir -p /opt/wasi-sdk && \
  curl -f -L --retry 5 https://gitlab.haskell.org/ghc/wasi-sdk/-/jobs/1451757/artifacts/raw/dist/wasi-sdk-17-linux.tar.gz | tar xz --strip-components=1 -C /opt/wasi-sdk && \
  curl -f -L --retry 5 https://gitlab.haskell.org/ghc/libffi-wasm/-/jobs/1227903/artifacts/download -o libffi-wasm.zip && \
  unzip libffi-wasm.zip && \
  mv out/libffi-wasm/include/* /opt/wasi-sdk/share/wasi-sysroot/include && \
  mv out/libffi-wasm/lib/* /opt/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi && \
  cp -a /tmp/ghc-boot /tmp/ghc && \
  cd /tmp/ghc && \
  git clean -xdf && \
  git submodule foreach --recursive git clean -xdf && \
  ./boot && \
  ./configure \
    --host=aarch64-alpine-linux \
    --target=wasm32-wasi \
    --with-intree-gmp \
    --with-system-libffi \
    --enable-bootstrap-with-devel-snapshot \
    AR=/opt/wasi-sdk/bin/llvm-ar \
    CC=/opt/wasi-sdk/bin/clang \
    CC_FOR_BUILD=cc \
    CXX=/opt/wasi-sdk/bin/clang++ \
    LD=/opt/wasi-sdk/bin/wasm-ld \
    NM=/opt/wasi-sdk/bin/llvm-nm \
    OBJCOPY=/opt/wasi-sdk/bin/llvm-objcopy \
    OBJDUMP=/opt/wasi-sdk/bin/llvm-objdump \
    RANLIB=/opt/wasi-sdk/bin/llvm-ranlib \
    SIZE=/opt/wasi-sdk/bin/llvm-size \
    STRINGS=/opt/wasi-sdk/bin/llvm-strings \
    STRIP=/opt/wasi-sdk/bin/llvm-strip \
    CONF_CC_OPTS_STAGE2="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_CXX_OPTS_STAGE2="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -fno-exceptions -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-error=unused-command-line-argument" \
    CONF_CC_OPTS_STAGE1="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_CXX_OPTS_STAGE1="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -fno-exceptions -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_GCC_LINKER_OPTS_STAGE1="-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-error=unused-command-line-argument" \
    LLC=/usr/bin/llc15 \
    OPT=/usr/bin/opt15 && \
  GHC=/usr/bin/ghc hadrian/build --flavour=perf+fully_static+no_profiled_libs "stage0.*.ghc.hs.opts += -fllvm -split-sections" --docs=none -j binary-dist-dir && \
  cd _build/bindist/ghc-* && \
  ./configure \
    --prefix=/opt/wasm32-wasi-ghc \
    --host=aarch64-alpine-linux \
    --target=wasm32-wasi \
    AR=/opt/wasi-sdk/bin/llvm-ar \
    CC=/opt/wasi-sdk/bin/clang \
    CXX=/opt/wasi-sdk/bin/clang++ \
    LD=/opt/wasi-sdk/bin/wasm-ld \
    NM=/opt/wasi-sdk/bin/llvm-nm \
    OBJCOPY=/opt/wasi-sdk/bin/llvm-objcopy \
    OBJDUMP=/opt/wasi-sdk/bin/llvm-objdump \
    RANLIB=/opt/wasi-sdk/bin/llvm-ranlib \
    SIZE=/opt/wasi-sdk/bin/llvm-size \
    STRINGS=/opt/wasi-sdk/bin/llvm-strings \
    STRIP=/opt/wasi-sdk/bin/llvm-strip \
    CONF_CC_OPTS_STAGE2="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_CXX_OPTS_STAGE2="-Wno-error=int-conversion -Wno-error=strict-prototypes -Wno-error=implicit-function-declaration -Oz -fno-exceptions -msimd128 -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mmultivalue -mreference-types" \
    CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-error=unused-command-line-argument" && \
  make install

FROM public.ecr.aws/lambda/nodejs:latest-arm64

COPY --from=0 --chown=0:0 --chmod=0755 /opt /opt
