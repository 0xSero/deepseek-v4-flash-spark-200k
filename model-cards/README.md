# Model Cards

Hugging Face model card READMEs for the validated DGX Spark DeepSeek V4 Flash profiles.

| Model | HF Repo | Served Name | Params | Context | Speculative | Best For |
|---|---|---|---|---|---|---|
| [DeepSeek-V4-Flash-Spark](DeepSeek-V4-Flash-Spark.md) | `0xSero/DeepSeek-V4-Flash-180B` | `DeepSeek-V4-Flash-Spark` | 180B | 200K | MTP2 | Best balance of capacity and speed on one Spark |
| [DeepSeek-V4-Flash-Spark-Mini](DeepSeek-V4-Flash-Spark-Mini.md) | `0xSero/DeepSeek-V4-Flash-162B` | `DeepSeek-V4-Flash-Spark-Mini` | 162B | 200K | None | Higher prefill speed, more conservative memory |

Both are REAP-pruned derivatives of `deepseek-ai/DeepSeek-V4-Flash` built to run on a single DGX Spark / GB10 / SM121. They are experimental. Evaluate quality on your own tasks before production use.

The full story of how these were built -- every failed checkpoint, every patch, every benchmark -- is in the model cards above and the runtime repo at https://github.com/0xSero/deepseek-v4-flash-spark-200k.
