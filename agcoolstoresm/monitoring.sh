# monitoring configuration
oc project agcoolstoresm
# Add Promethues to the project
# Create a config map
oc create configmap prom --from-file=prometheus.yml
#
# Create a new instance of Prometheus
oc new-app prom/prometheus --name prometheus --as-deployment-config
oc expose svc/prometheus
#
# Mount the map into the container 
oc set volume dc/prometheus --add -t configmap --configmap-name=prom -m /etc/prometheus/prometheus.yml --sub-path=prometheus.yml
oc rollout status -w dc/prometheus
#
# Add Grafana (credentials: admin/admin)
#
oc new-app grafana/grafana --name grafana --as-deployment-config
oc expose svc/grafana

