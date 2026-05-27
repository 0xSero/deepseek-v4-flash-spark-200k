---
license: mit
library_name: transformers
pipeline_tag: text-generation
tags:
- deepseek-v4
- mixture-of-experts
- reap
- dgx-spark
- vllm
- long-context
- fp8
- mxfp4
- experimental
base_model: deepseek-ai/DeepSeek-V4-Flash
---

# DeepSeek-V4-Flash-Spark-Mini

This is the 162B / K144 REAP-pruned DeepSeek V4 Flash model, served as `DeepSeek-V4-Flash-Spark-Mini`. The validated single-DGX Spark serving recipe is maintained here:

- One-command Spark wrapper: https://github.com/0xSero/deepseek-spark
- Runtime module: https://github.com/0xSero/deepseek-v4-flash-spark-200k
- Docker registry target: `ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27`
- Validated local Docker image: `vllm-node-dsv4-cutlass451:latest` / `sha256:5df60ebb9c10dfb86d5946cae8244adfe65a7fd405401bd542ecf22d5c497a4a`
- Model repo used by the recipe: `0xSero/DeepSeek-V4-Flash-162B`
- Validated revision: `d663e8fb16809f6619000648b187b257249ed824`

## One-command Spark install

Run this on the DGX Spark. `HF_TOKEN` is only required if the model repo is private or not already cached on the machine.

```bash
HF_TOKEN=... bash -lc 'set -euo pipefail; cd /home/sero/spark; rm -rf deepseek-spark; git clone https://github.com/0xSero/deepseek-spark.git; cd deepseek-spark; ./setup.sh full k144'
```

Do not commit tokens into the repo or a model card. Pass them only through the environment for the one command above.

## Exact working profile

The profile lives at `configs/k144-nospec-200k.env` in the GitHub repo.

```bash
MODEL_REPO=0xSero/DeepSeek-V4-Flash-162B
MODEL_REVISION=d663e8fb16809f6619000648b187b257249ed824
SERVED_MODEL_NAME=DeepSeek-V4-Flash-Spark-Mini
CONTEXT_LENGTH=200000
KV_CACHE_MEMORY_BYTES=14G
MAX_NUM_BATCHED_TOKENS=8192
MAX_NUM_SEQS=1
GPU_MEMORY_UTILIZATION=0.88
WATCHDOG_MIN_AVAILABLE_KB=8388608
KV_CACHE_DTYPE=fp8
THINKING=true
SPECULATIVE_CONFIG=
VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP=0
VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH=1
```

The launcher enables DeepSeek V4 tokenizer, reasoning parser, tool-call parser, prefix caching, FP8 KV, and CUDA graph capture.

## Docker runtime

The registry target is:

```text
ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27
```

The image lineage is the DGX Spark DeepSeek V4 vLLM build `vllm-node-dsv4:latest` with vLLM `0.1.dev17016+g27fd665bd.d20260526` and `nvidia-cutlass-dsl[cu13]==4.5.1`. The installer tags the pulled image as `vllm-node-dsv4-cutlass451:latest`.

The exact image validated on `spark-2822` is:

```text
vllm-node-dsv4-cutlass451:latest
sha256:5df60ebb9c10dfb86d5946cae8244adfe65a7fd405401bd542ecf22d5c497a4a
```

If GHCR anonymous manifest access returns `denied`, the image has not been package-published yet. In that case the installer uses the already-cached local image or builds `vllm-node-dsv4-cutlass451:latest` from a local `vllm-node-dsv4:latest` base.

The repo also carries the runtime patcher used during validation. It applies the nonstandard REAP expert-count router fallback, MXFP4 memory hygiene, optional cute-dsl override hook, and a FlashInfer CUDA IPC `libcudart` fix. It does not modify model weights.

## Validation

Validation was run on `spark-2822`, a single DGX Spark / GB10 / SM121 machine, on May 27 2026.

```text
run_dir: /home/sero/spark/benchmarks/deepseek-reap/single-server-sweep/k144-nospec-200k-mnbt8192-20260527T190139Z
prompt_tokens: 186,390
TTFT: 345.834 s
prefill: 538.958 tok/s
decode: 13.899 tok/s
needle_retained: true
```

Task coverage at 200K included smoke, ASCII, Unicode, Mermaid, code explanation, religion/philosophy prompts, tool-call fidelity, and a long-needle retrieval test. The 200K sweep completed and retained the needle, but the watchdog logged a low-memory kill at final teardown near the 8 GiB threshold. Treat this as proof that K144 can serve 200K on one Spark, not as the most comfortable always-on daemon profile.

K144 MTP2 improved short-context decode in testing, but it was not long-context safe at the tested watchdog thresholds. The published 200K profile is therefore the no-speculative-decoding profile.

## Intended use

This model card is for experimental local inference and reproducibility of the DGX Spark REAP serving recipe. The model is a pruned/quantized DeepSeek V4 Flash derivative; evaluate behavior and license obligations before production use.
