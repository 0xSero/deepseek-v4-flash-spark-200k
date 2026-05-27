# DeepSeek V4 Flash REAP on One DGX Spark at 200K

Private reproducible recipe for serving `0xSero/DeepSeek-V4-Flash-180B-codex-K160-REAP` on one DGX Spark (`spark-2822`) with vLLM, FP8 MLA KV, CUDA graphs, and DeepSeek MTP speculative decoding.

## One Command

From the Spark that already has the working image cached:

```bash
GITHUB_TOKEN=... HF_TOKEN=... bash -lc 'set -euo pipefail; cd /home/sero/spark; rm -rf deepseek-v4-flash-spark-200k; git clone https://x-access-token:${GITHUB_TOKEN}@github.com/0xSero/deepseek-v4-flash-spark-200k.git; cd deepseek-v4-flash-spark-200k; ./install.sh --profile k160-mtp2-200k --launch'
```

`GITHUB_TOKEN` is needed while this repo and the GHCR image are private. `HF_TOKEN` is only needed if the Hugging Face model is private or not already cached.

For a fresh Spark, publish/pull the Docker image first. The expected image name is:

```text
ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27
```

The current local GitHub token did not have `write:packages`, so GHCR upload was blocked. After refreshing a token with package scope, run:

```bash
./scripts/push_ghcr_image.sh
```

## Default Working Profile

`configs/k160-mtp2-200k.env`:

```bash
MODEL_REPO=0xSero/DeepSeek-V4-Flash-180B-codex-K160-REAP
MODEL_REVISION=7c360e1cd4a5168099dbc54d16d929bf6df04990
CONTEXT_LENGTH=200000
KV_CACHE_MEMORY_BYTES=6G
MAX_NUM_BATCHED_TOKENS=4096
MAX_NUM_SEQS=1
SPECULATIVE_CONFIG='{"method":"deepseek_mtp","num_speculative_tokens":2}'
ENFORCE_EAGER=0
```

The launch script also enables FP8 KV, DeepSeek V4 tokenizer/tool/reasoning parsers, prefix caching, `FULL_AND_PIECEWISE` CUDA graphs, and the GB10 REAP patcher.

## Evidence

Measured on `spark-2822`, May 27 2026:

| profile | ready | watchdog | prompt tokens | TTFT | prefill | decode | result |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| K160 MTP2, 6G KV, 4096 chunk | yes | no | 136,534 | 248.217s | 550.059 tok/s | 33.287 tok/s | needle retained |
| K160 no-spec, 8G KV, 4096 chunk | yes | no | 136,534 | 246.729s | 553.376 tok/s | 13.188 tok/s | needle retained |
| K144 no-spec, 14G KV, 8192 chunk | yes | no | 136,534 | 234.304s | 582.721 tok/s | 12.531 tok/s | needle retained |

K144 MTP2 improved short decode but was not long-context safe at the tested 8G watchdog threshold. K160 MTP2 was made long-context safe by using a 6G KV pool.

## Notes

- Do not add `--enforce-eager`; the working profiles capture CUDA graphs.
- The image lineage is `vllm-node-dsv4:latest` / vLLM `0.1.dev17016+g27fd665bd.d20260526` plus `nvidia-cutlass-dsl[cu13]==4.5.1`.
- The patcher applies the REAP nonstandard expert-count router fallback, MXFP4 memory hygiene, optional cute-dsl override hook, and FlashInfer CUDA IPC libcudart fix.
- The exact GHCR image is expected at `ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27`; if it is not available, the installer can use the already-cached `vllm-node-dsv4-cutlass451:latest` image or build from a local `vllm-node-dsv4:latest` base image.
