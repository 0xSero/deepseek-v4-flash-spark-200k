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

**162B parameters | K144 REAP-pruned | 200K context | no speculative decoding**

This is a smaller pruned DeepSeek V4 Flash that runs on a single DGX Spark. It trades some model capacity for higher prefill speed and a more conservative memory profile. It is the fallback option when you want 200K context with a bit more headroom.

## What this is

- Base: `deepseek-ai/DeepSeek-V4-Flash`
- Pruning: REAP (Routing-Enhanced Activation Pruning) at K144
- Final size: ~162B active parameters
- Quantization: NVFP4 / MXFP4 expert weights with FP8 KV cache
- Serving: vLLM with DeepSeek V4 tokenizer, reasoning parser, and tool-call parser
- Context: 200,000 tokens validated end-to-end
- Hardware target: single NVIDIA DGX Spark / GB10 / SM121

K144 was the smaller checkpoint that still reached 200K on one Spark. It prefills faster than K160 (about 539 tok/s vs 514 tok/s) but decodes slower (about 14 tok/s vs 24 tok/s) because it lacks MTP speculative decoding. The watchdog also logged a low-memory kill at final teardown, so treat this as proof-of-concept rather than a comfortable always-on daemon.

## How we got here

See the [DeepSeek-V4-Flash-Spark](https://huggingface.co/0xSero/DeepSeek-V4-Flash-180B) model card for the full story. The short version: we tested every REAP checkpoint from 148B through 213B on a single DGX Spark. Most failed before the API came up. K160 was the largest that survived with speculative decoding. K144 was the next viable option without it.

The same runtime patches apply: native ARM64 vLLM build, Cutlass 4.5.1 workaround, REAP expert-count fallback, MXFP4 memory hygiene, and FlashInfer CUDA IPC fix.

## One-command install

Run this on the DGX Spark. `HF_TOKEN` is only needed if the model repo is private or not already cached.

```bash
HF_TOKEN=... bash -lc 'set -euo pipefail; cd /home/sero/spark; rm -rf deepseek-spark; git clone https://github.com/0xSero/deepseek-spark.git; cd deepseek-spark; ./setup.sh full k144'
```

Do not commit tokens. Pass them only through the environment for this one command.

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

The launcher enables DeepSeek V4 tokenizer, reasoning parser, tool-call parser, prefix caching, FP8 KV, and CUDA graph capture. No speculative decoding.

## Docker runtime

Registry target:

```text
ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27
```

The image is the DGX Spark DeepSeek V4 vLLM build `vllm-node-dsv4:latest` with vLLM `0.1.dev17016+g27fd665bd.d20260526` and `nvidia-cutlass-dsl[cu13]==4.5.1`. The installer tags the pulled image as `vllm-node-dsv4-cutlass451:latest`.

Exact image validated on `spark-2822`:

```text
vllm-node-dsv4-cutlass451:latest
sha256:5df60ebb9c10dfb86d5946cae8244adfe65a7fd405401bd542ecf22d5c497a4a
```

If GHCR anonymous manifest access returns `denied`, the image has not been package-published yet. The installer falls back to the already-cached local image or builds from the local base.

The runtime patcher applies the nonstandard REAP expert-count router fallback, MXFP4 memory hygiene, optional cute-dsl override hook, and a FlashInfer CUDA IPC `libcudart` fix. It does not modify model weights.

## Validation

Run on `spark-2822`, a single DGX Spark / GB10 / SM121, on May 27 2026.

200K long-needle benchmark:

```text
run_dir: /home/sero/spark/benchmarks/deepseek-reap/single-server-sweep/k144-nospec-200k-mnbt8192-20260527T190139Z
prompt_tokens: 186,390
TTFT: 345.834 s
prefill: 538.958 tok/s
decode: 13.899 tok/s
needle_retained: true
```

Task coverage at 200K included smoke, ASCII, Unicode, and Mermaid diagrams; code explanation; religion and philosophy prompts; tool-call fidelity; and long-needle retrieval. All passed. The watchdog logged a low-memory kill at final teardown near the 8 GB threshold, so this is proven but not the most comfortable always-on profile.

K144 with MTP2 was tested but was not long-context safe at the tested watchdog thresholds. The published 200K profile is therefore the no-speculative-decoding profile.

## Why K144 without speculative decoding

K144 without MTP is the conservative option. It uses a larger KV cache (14 GB vs 6 GB) and bigger prefill chunks (8192 vs 4096), which gives it the highest prefill speed of the tested single-Spark profiles. The tradeoff is lower decode speed and a tighter memory margin at teardown.

Choose this if you value prefill throughput over decode speed, or if you want a simpler profile without speculative decoding.

## Limitations

- This is a pruned model. It is not the full DeepSeek V4 Flash. Evaluate quality against your own tasks before trusting it for production work.
- 200K context works, but memory is tight. The watchdog killed the process at teardown during validation.
- The public 200K success path for the full model remains dual-Spark TP=2. This is a compromise.
- The Docker image and patches are experimental. They are not upstream vLLM and may break on newer commits.

## Links

- One-command wrapper: https://github.com/0xSero/deepseek-spark
- Runtime module (configs, patcher, evidence): https://github.com/0xSero/deepseek-v4-flash-spark-200k
- Base model: https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash
- Larger single-Spark profile: https://huggingface.co/0xSero/DeepSeek-V4-Flash-180B

## License

MIT for the serving recipe and tooling. The base model weights follow the DeepSeek V4 Flash license. Review it before use.
