for d in caller callee; do
  oc -n grpc-mesh-demo patch deploy "$d" --type merge -p '{
    "spec":{"template":{"metadata":{"annotations":{
      "prometheus.io/scrape":"true",
      "prometheus.io/port":"15090",
      "prometheus.io/path":"/stats/prometheus"
    }}}}}'
done

oc -n grpc-mesh-demo rollout restart deploy/caller deploy/callee