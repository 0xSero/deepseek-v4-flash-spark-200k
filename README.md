# deepseek-v4-flash-spark-200k

**This repo has been merged into [`0xSero/deepseek-spark`](https://github.com/0xSero/deepseek-spark) and is archived.**

The runtime module (configs, GB10 patcher, launch scripts, model cards, evidence) now lives at:

https://github.com/0xSero/deepseek-spark/tree/main/runtime

Hugging Face model cards:

- https://huggingface.co/0xSero/DeepSeek-V4-Flash-180B
- https://huggingface.co/0xSero/DeepSeek-V4-Flash-162B

Docker note: the old GHCR target `ghcr.io/0xsero/deepseek-v4-flash-spark-vllm:cutlass451-g27` was never package-published. The active `deepseek-spark` installer does not depend on that missing image; it uses the validated local image when present and otherwise builds the native DGX Spark vLLM image locally from public sources.
