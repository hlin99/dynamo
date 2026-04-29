#!/bin/bash
set -e
trap 'echo Cleaning up...; kill 0' EXIT

export PYTHONHASHSEED=0
export no_proxy=10.239.44.27,10.239.44.4,localhost,127.0.0.1
export no_proxy=10.239.44.27,10.239.44.4,localhost,127.0.0.1,0.0.0.0

export NATS_SERVER=nats://10.239.44.27:4222
export ETCD_ENDPOINTS=http://10.239.44.27:2379

# Common configuration
MODEL="/root/hlin76/Llama-3.1-8B/"
MODEL="/workspace/Meta-Llama-3-8B-Instruct/"

BLOCK_SIZE=64
VLLM_NIXL_DEVICE_TO_DEVICE=true
NIXL_BUFFER_DEVICE=xpu
VLLM_NIXL_BACKEND=UCX
export UCX_MEMTYPE_CACHE=0
export UCX_NET_DEVICES=rocep160s0f0:1,rocep160s0f1:1,rocep192s0f0:1,rocep192s0f1:1
export UCX_NET_DEVICES=rocep160s0f0:1

export UCX_TLS=rc,ze_copy,ze_ipc,shm,self
#export UCX_TLS=tcp,self

# Start frontend with KV routing
python -m dynamo.frontend \
    --router-mode kv \
    --http-port 8000 \
    --router-reset-states &

# 1 decode worker (GPU 0)
VLLM_NIXL_SIDE_CHANNEL_PORT=20096 \
ZE_AFFINITY_MASK=0 python3 -m dynamo.vllm \
    --model $MODEL \
    --max-model-len 1024 \
    --block-size $BLOCK_SIZE \
    --kv-transfer-config "{\"kv_connector\": \"NixlConnector\", \"kv_role\": \"kv_consumer\", \"kv_buffer_device\": \"${NIXL_BUFFER_DEVICE}\", \"kv_connector_extra_config\": {\"backends\": [\"${VLLM_NIXL_BACKEND}\"]}}" \
    --kv-events-config '{"publisher":"zmq","topic":"kv-events","endpoint":"tcp://*:5556", "enable_kv_cache_events":true}'
