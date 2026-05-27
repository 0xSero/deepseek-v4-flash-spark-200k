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
- speculative-decoding
- experimental
base_model: deepseek-ai/DeepSeek-V4-Flash
---

# Deepseek-V4-Flash-180B-REAP

This is the 180B / K160 REAP-pruned DeepSeek V4 Flash model. The validated single-DGX Spark serving recipe is maintained here:

- GitHub: https://github.com/0xSero/deepseek-v4-flash-spark-200k
- Docker registry target: `ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27`
- Validated local Docker image: `vllm-node-dsv4-cutlass451:latest` / `sha256:5df60ebb9c10dfb86d5946cae8244adfe65a7fd405401bd542ecf22d5c497a4a`
- Model repo used by the recipe: `0xSero/DeepSeek-V4-Flash-180B-codex-K160-REAP`
- Validated revision: `7c360e1cd4a5168099dbc54d16d929bf6df04990`

## One-command Spark install

Run this on the DGX Spark. `HF_TOKEN` is only required if the model repo is private or not already cached on the machine.

```bash
HF_TOKEN=... bash -lc 'set -euo pipefail; cd /home/sero/spark; rm -rf deepseek-v4-flash-spark-200k; git clone https://github.com/0xSero/deepseek-v4-flash-spark-200k.git; cd deepseek-v4-flash-spark-200k; ./install.sh --profile k160-mtp2-200k --launch'
```

Do not commit tokens into the repo or a model card. Pass them only through the environment for the one command above.

## Exact working profile

The profile lives at `configs/k160-mtp2-200k.env` in the GitHub repo.

```bash
MODEL_REPO=0xSero/DeepSeek-V4-Flash-180B-codex-K160-REAP
MODEL_REVISION=7c360e1cd4a5168099dbc54d16d929bf6df04990
SERVED_MODEL_NAME=deepseek-v4-flash-k160-g27-cutlass451-mtp2
CONTEXT_LENGTH=200000
KV_CACHE_MEMORY_BYTES=6G
MAX_NUM_BATCHED_TOKENS=4096
MAX_NUM_SEQS=1
GPU_MEMORY_UTILIZATION=0.88
WATCHDOG_MIN_AVAILABLE_KB=6291456
KV_CACHE_DTYPE=fp8
ENFORCE_EAGER=0
THINKING=false
SPECULATIVE_CONFIG='{"method":"deepseek_mtp","num_speculative_tokens":2}'
VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP=0
VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH=1
```

The launcher enables DeepSeek V4 tokenizer, reasoning parser, tool-call parser, prefix caching, FP8 KV, MTP speculative decoding, and CUDA graphs. Do not add `--enforce-eager`; this profile was validated with CUDA graph capture enabled.

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

Startup evidence:

```text
MTP draft model loaded: 39 params
Model loading took 96.66 GiB memory
GPU KV cache size: 537,516 tokens
Maximum concurrency for 200,000 tokens per request: 2.69x
Graph capturing finished in about 20 seconds and used about 1.66 GiB
```

Full 200K long-needle benchmark:

```text
run_dir: /home/sero/spark/benchmarks/deepseek-reap/single-server-sweep/k160-mtp2-200k-mnbt4096-kv6g-20260527T192208Z
prompt_tokens: 186,390
TTFT: 362.573 s
prefill: 514.075 tok/s
decode: 24.378 tok/s
needle_retained: true
watchdog_kill: false
```

Fixed 200K long-coding benchmark:

```text
run_dir: /home/sero/spark/benchmarks/deepseek-reap/single-server-sweep/k160-mtp2-200k-longcoding-fixed-20260527T194241Z
prompt_tokens: 182,112
TTFT: 353.799 s
prefill: 514.733 tok/s
decode: 18.946 tok/s
mentions_off_by_one: true
watchdog_kill: false
```

Task coverage at 200K included smoke, ASCII, Unicode, Mermaid, code explanation, religion/philosophy prompts, tool-call fidelity, long-needle retrieval, and long-code review. Smoke, ASCII, Unicode, Mermaid, code, religion, tool-call fidelity, and long-needle passed. A few qualitative rubrics missed narrow fields at `128` output tokens, so benchmark prompts should reserve more completion tokens when judging broad reasoning quality.

## Why this is the default profile

K160 with MTP2 was the best single-Spark balance found so far: it kept the 200K path alive without a watchdog kill and roughly doubled decode speed versus no-spec in comparable long-context tests. The 6G KV pool and 4096-token prefill chunks leave enough room for the weights, DeepGEMM/CUDA graph workspaces, and activations on a 121 GiB usable-memory GB10 system.

## Intended use

This model card is for experimental local inference and reproducibility of the DGX Spark REAP serving recipe. The model is a pruned/quantized DeepSeek V4 Flash derivative; evaluate behavior and license obligations before production use.
