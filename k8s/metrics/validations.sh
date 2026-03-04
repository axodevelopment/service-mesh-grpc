Need to check for prometheus.io/scrape

oc -n grpc-mesh-demo get pod -l app=callee -o jsonpath='{.items[0].metadata.annotations}{"\n"}' | tr ' ' '\n' | egrep -i 'prometheus\.io|istio'