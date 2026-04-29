nats-server -a 0.0.0.0 -p 4222 &
etcd \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://10.239.44.27:2379 &

