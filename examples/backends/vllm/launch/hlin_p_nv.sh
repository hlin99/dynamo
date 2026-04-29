#!/bin/bash
set -e
trap 'echo Cleaning up...; kill 0' EXIT

export PYTHONHASHSEED=0
export NATS_SERVER=nats://10.239.44.27:4222
export DYNAMO_ETCD_ENDPOINTS=http://10.239.44.27:2379

# Common configuration
MODEL="/workspace/Meta-Llama-3-8B-Instruct/"
BLOCK_SIZE=64
VLLM_NIXL_DEVICE_TO_DEVICE=true
NIXL_BUFFER_DEVICE=cuda
VLLM_NIXL_BACKEND=UCX
export UCX_MEMTYPE_CACHE=0
export UCX_NET_DEVICES=mlx5_0:1,mlx5_1:1,mlx5_2:1,mlx5_3:1
export UCX_TLS=rc,cuda_copy,cuda_ipc,shm,self

# Start frontend with KV routing
python -m dynamo.frontend \
    --router-mode kv \
    --http-port 8000 \
    --router-reset-states &

# 1 prefill worker (GPU 0)
VLLM_NIXL_SIDE_CHANNEL_PORT=20098 \
CUDA_VISIBLE_DEVICES=0 python3 -m dynamo.vllm \
    --model $MODEL \
    --max-model-len 1024 \
    --block-size $BLOCK_SIZE \
    --enforce-eager \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_both\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5558", "enable_kv_cache_events":true}'
