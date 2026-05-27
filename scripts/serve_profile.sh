#!/usr/bin/env bash
set -euo pipefail

PROFILE=${PROFILE:-k160-mtp2-200k}
SPARK_ROOT=${SPARK_ROOT:-/home/sero/spark}
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG="${REPO_ROOT}/configs/${PROFILE}.env"

if [[ ! -f "$CONFIG" ]]; then
  echo "missing profile config: $CONFIG" >&2
  exit 2
fi

set -a
# shellcheck source=/dev/null
source "$CONFIG"
set +a

MODEL_DIR=${MODEL_DIR:-${HF_HOME:-${SPARK_ROOT}/models/hf-cache}/models--${MODEL_REPO//\//--}/snapshots/${MODEL_REVISION}}
IMAGE=${IMAGE:-vllm-node-dsv4-cutlass451:latest}
NAME=${NAME:-dsv4-${PROFILE}}
PORT=${PORT:-8002}
HOST=${HOST:-100.83.190.2}

if [[ ! -d "$MODEL_DIR" ]]; then
  echo "missing MODEL_DIR: $MODEL_DIR" >&2
  echo "run ./install.sh --profile ${PROFILE} first" >&2
  exit 1
fi

MODEL_DIR="$MODEL_DIR" \
IMAGE="$IMAGE" \
NAME="$NAME" \
PORT="$PORT" \
HOST="$HOST" \
SERVED_MODEL_NAME="$SERVED_MODEL_NAME" \
CONTEXT_LENGTH="$CONTEXT_LENGTH" \
KV_CACHE_MEMORY_BYTES="$KV_CACHE_MEMORY_BYTES" \
KV_CACHE_DTYPE="$KV_CACHE_DTYPE" \
MAX_NUM_BATCHED_TOKENS="$MAX_NUM_BATCHED_TOKENS" \
MAX_NUM_SEQS="$MAX_NUM_SEQS" \
GPU_MEMORY_UTILIZATION="$GPU_MEMORY_UTILIZATION" \
WATCHDOG_MIN_AVAILABLE_KB="$WATCHDOG_MIN_AVAILABLE_KB" \
ENFORCE_EAGER="$ENFORCE_EAGER" \
THINKING="$THINKING" \
SPECULATIVE_CONFIG="$SPECULATIVE_CONFIG" \
VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP="$VLLM_ENABLE_DEEPSEEK_V4_SPARSE_MLA_WARMUP" \
VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH="$VLLM_TRITON_MLA_SPARSE_ALLOW_CUDAGRAPH" \
"${SPARK_ROOT}/tools/launch_vllm_deepseek_v4_guarded.sh"

echo "server starting on http://${HOST}:${PORT}"
echo "container: ${NAME}"
