# ZTUNNEL, CHECKWORKLOAD
oc get pods -n grpc-mesh-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.ambient\.istio\.io/redirection}{"\n"}{end}'


# istioctl ztunnle-configg heck

istioctl ztunnel-config workloads -n ztunnel

NAMESPACE      POD NAME                            ADDRESS      NODE              WAYPOINT PROTOCOL
grpc-mesh-demo callee-689d7fbccc-vhrqs             10.128.1.116 24-6e-96-b1-76-54 None     HBONE
grpc-mesh-demo caller-8bf76d78-qtx6q               10.128.1.117 24-6e-96-b1-76-54 None     HBONE
grpc-mesh-demo grpc-mesh-waypoint-6464455ff9-ptj7z 10.128.1.115 24-6e-96-b1-76-54 None     TCP
grpc-mesh-demo public-gw-istio-7f6bbf77bb-d4fpg    10.128.1.114 24-6e-96-b1-76-54 None     TCP
istio-cni      istio-cni-node-lbrdf                10.128.1.111 24-6e-96-b1-76-54 None     TCP
istio-system   istiod-ffbd6dc96-78dhr              10.128.1.112 24-6e-96-b1-76-54 None     TCP
istio-system   kiali-dcc64dfdf-p4k4r               10.128.0.128 24-6e-96-b1-76-54 None     TCP
istio-system   ossmconsole-7f54749765-5kx4c        10.128.1.120 24-6e-96-b1-76-54 None     TCP
ztunnel        ztunnel-zmn2d                       10.128.1.113 24-6e-96-b1-76-54 None     TCP



# ztunnel port forward

ZTUNNEL=$(oc get pods -n ztunnel -o jsonpath='{.items[0].metadata.name}')
echo $ZTUNNEL

ztunnel-gg2jr

oc port-forward pod/$ZTUNNEL 15020:15020 -n ztunnel &
sleep 2
curl -s localhost:15020/stats/prometheus | grep -i "ztunnel\|istio_requests" | head -20

# ->> some get metrics 

ztunnel has named port ztunnel-stats on 15020

# waypoint check for prom

WAYPOINT=$(oc get pods -n grpc-mesh-demo -l gateway.networking.k8s.io/gateway-name=grpc-mesh-waypoint \
  -o jsonpath='{.items[0].metadata.name}')

oc get pod -n grpc-mesh-demo $WAYPOINT \
  -o jsonpath='{.spec.containers[0].ports}' | python3 -m json.tool


####
####

# Check what is being scraped from targets enabled or errored

PROM=$(oc get pods -n openshift-user-workload-monitoring -l app.kubernetes.io/name=prometheus \
  -o jsonpath='{.items[0].metadata.name}')

oc port-forward pod/$PROM 9091:9090 -n openshift-user-workload-monitoring &
sleep 2

# /api/v1/targets
curl -s 'localhost:9091/api/v1/targets' | python3 -m json.tool | \
  grep -E '"scrapePool"|"health"|"lastError"' | head -60

# should be vector
curl -s 'localhost:9091/api/v1/query?query=istio_tcp_connections_opened_total' | \
  python3 -m json.tool | grep "resultType"

kill %1


###


PROM=$(oc get pods -n openshift-user-workload-monitoring -l app.kubernetes.io/name=prometheus \
  -o jsonpath='{.items[0].metadata.name}')

oc port-forward pod/$PROM 9091:9090 -n openshift-user-workload-monitoring &
sleep 2

# check health specifically for istio monitors
curl -s 'localhost:9091/api/v1/targets' | python3 -m json.tool | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data['data']['activeTargets']:
    pool = t.get('scrapePool','')
    if 'istio' in pool or 'ztunnel' in pool or 'waypoint' in pool:
        print(pool, '→', t.get('health'), t.get('lastError',''))
"

# query actual metric values
curl -s 'localhost:9091/api/v1/query?query=istio_tcp_connections_opened_total' | \
  python3 -m json.tool | grep -A3 "metric\|value" | head -40

kill %1



###
# SCRAPE, DROPTARGET
# ehckking dropped targets.

PROM=$(oc get pods -n openshift-user-workload-monitoring -l app.kubernetes.io/name=prometheus \
  -o jsonpath='{.items[0].metadata.name}')

oc port-forward pod/$PROM 9091:9090 -n openshift-user-workload-monitoring &
sleep 2

curl -s 'localhost:9091/api/v1/targets' | python3 -m json.tool | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
print('=== ACTIVE ===')
for t in data['data']['activeTargets']:
    pool = t.get('scrapePool','')
    if 'ztunnel' in pool or 'waypoint' in pool or 'proxies' in pool:
        print(pool, '->', t.get('health'), t.get('lastError',''))

print()
print('=== DROPPED ===')
for t in data['data']['droppedTargets']:
    pool = t.get('scrapePool','')
    if 'ztunnel' in pool or 'waypoint' in pool or 'proxies' in pool:
        labels = t.get('discoveredLabels',{})
        print(pool)
        print('  address:', labels.get('__address__',''))
        print('  container:', labels.get('__meta_kubernetes_pod_container_name',''))
        print('  scrape:', labels.get('__meta_kubernetes_pod_annotation_prometheus_io_scrape',''))
        print()
"

kill %1