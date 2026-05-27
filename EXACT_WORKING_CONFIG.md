# Exact Working Config

Default target: K160 / `Deepseek-V4-Flash-180B-REAP` + MTP2 + 200K on one DGX Spark.

```bash
MODEL_DIR=/home/sero/spark/models/hf-cache/models--0xSero--DeepSeek-V4-Flash-180B-codex-K160-REAP/snapshots/7c360e1cd4a5168099dbc54d16d929bf6df04990
IMAGE=vllm-node-dsv4-cutlass451:latest
SERVED_MODEL_NAME=deepseek-v4-flash-k160-g27-cutlass451-mtp2
CONTEXT_LENGTH=200000
KV_CACHE_MEMORY_BYTES=6G
MAX_NUM_BATCHED_TOKENS=4096
MAX_NUM_SEQS=1
GPU_MEMORY_UTILIZATION=0.88
KV_CACHE_DTYPE=fp8
ENFORCE_EAGER=0
THINKING=false
SPECULATIVE_CONFIG='{"method":"deepseek_mtp","num_speculative_tokens":2}'
VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP=0
VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH=1
```

Launch:

```bash
PROFILE=k160-mtp2-200k ./scripts/serve_profile.sh
```

Key startup evidence:

```text
MTP draft model loaded: 39 params
Model loading took 96.66 GiB memory
GPU KV cache size: 537,516 tokens
Maximum concurrency for 200,000 tokens per request: 2.69x
Graph capturing finished in 20 secs, took 1.66 GiB
```

Benchmark evidence:

```text
prompt_tokens: 186,390
TTFT: 362.573s
prefill: 514.075 tok/s
decode: 24.378 tok/s
needle_retained: true
watchdog_kill: false
```

Fixed long-coding evidence:

```text
prompt_tokens: 182,112
TTFT: 353.799s
prefill: 514.733 tok/s
decode: 18.946 tok/s
off_by_one_found: true
watchdog_kill: false
```

K144 / `Deepseek-V4-Flash-162B-REAP` validated 200K profile:

```bash
MODEL_DIR=/home/sero/spark/models/hf-cache/models--0xSero--DeepSeek-V4-Flash-162B-codex-K144-REAP/snapshots/d663e8fb16809f6619000648b187b257249ed824
IMAGE=vllm-node-dsv4-cutlass451:latest
SERVED_MODEL_NAME=deepseek-v4-flash-k144-g27-cutlass451
CONTEXT_LENGTH=200000
KV_CACHE_MEMORY_BYTES=14G
MAX_NUM_BATCHED_TOKENS=8192
MAX_NUM_SEQS=1
GPU_MEMORY_UTILIZATION=0.88
KV_CACHE_DTYPE=fp8
ENFORCE_EAGER=0
THINKING=false
SPECULATIVE_CONFIG=
VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP=0
VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH=1
```

K144 benchmark evidence:

```text
prompt_tokens: 186,390
TTFT: 345.834s
prefill: 538.958 tok/s
decode: 13.899 tok/s
needle_retained: true
```
