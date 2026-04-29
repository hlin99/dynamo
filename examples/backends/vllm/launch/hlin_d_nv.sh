#!/bin/bash
set -e
trap 'echo Cleaning up...; kill 0' EXIT
export no_proxy=10.239.44.27,10.239.44.4,localhost,127.0.0.1
export no_proxy=10.239.44.27,10.239.44.4,localhost,127.0.0.1,0.0.0.0

export PYTHONHASHSEED=0
export NATS_SERVER=nats://10.239.44.27:4222
export ETCD_ENDPOINTS=http://10.239.44.27:2379

# Common configuration
MODEL="/workspace/Meta-Llama-3-8B-Instruct/"
BLOCK_SIZE=64
VLLM_NIXL_DEVICE_TO_DEVICE=true
NIXL_BUFFER_DEVICE=cuda
VLLM_NIXL_BACKEND=UCX
export UCX_MEMTYPE_CACHE=0
export UCX_NET_DEVICES=mlx5_0:1,mlx5_1:1,mlx5_2:1,mlx5_3:1
export UCX_NET_DEVICES=mlx5_0:1
export UCX_TLS=rc,cuda_copy,cuda_ipc,shm,self

#export UCX_TLS=tcp,self
# 1 prefill worker (GPU 0)
VLLM_NIXL_SIDE_CHANNEL_PORT=20098 \
CUDA_VISIBLE_DEVICES=0 python3 -m dynamo.vllm \
    --model $MODEL \
    --max-model-len 1024 \
    --block-size $BLOCK_SIZE \
    --enforce-eager \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_consumer\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --is-prefill-worker \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5558", "enable_kv_cache_events":true}'
