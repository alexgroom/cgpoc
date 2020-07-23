# monitoring configuration
# Create a config map
oc create configmap prom --from-file=prometheus.yml
#
# Create a new instance of Prometheus
oc new-app prom/prometheus --name prometheus
oc expose svc/prometheus
#
# Mount the map into the container 
oc set volume dc/prometheus --add -t configmap --configmap-name=prom -m /etc/prometheus/prometheus.yml --sub-path=prometheus.yml
oc rollout status -w deployment/prometheus
