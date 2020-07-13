# script to install agcoolstoresm  components
#oc new-project agcoolstoresm
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  -l app.openshift.io/runtime=java
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  -l app.openshift.io/runtime=java
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app.openshift.io/runtime=java \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web -l app.openshift.io/runtime=nodejs
oc new-app dotnet:2.1~https://github.com/alexgroom/inventory-api-1st-dotnet.git#dotnet2.1 --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app.openshift.io/runtime=dotnet
# Add component labels to group services
oc label dc gateway app.kubernetes.io/part-of=coolstore
oc label dc catalog app.kubernetes.io/part-of=coolstore
oc label dc inventory app.kubernetes.io/part-of=coolstore
oc label dc web app.kubernetes.io/part-of=coolstore
oc label dc inventory-dotnet app.kubernetes.io/part-of=coolstore
oc label dc gateway app.kubernetes.io/instance=gateway
oc label dc catalog app.kubernetes.io/instance=catalog
oc label dc inventory app.kubernetes.io/instance=inventory
oc label dc web app.kubernetes.io/instance=web
oc label dc inventory-dotnet app.kubernetes.io/instance=inventory-dotnet
# configure service mesh route labels
oc label dc gateway maistra.io/expose-route=true
oc label dc catalog maistra.io/expose-route=true
oc label dc inventory maistra.io/expose-route=true
oc label dc web maistra.io/expose-route=true
oc label dc inventory-dotnet maistra.io/expose-route=true
# expose routes
oc expose svc gateway
oc expose svc inventory
oc expose svc catalog
oc expose svc inventory-dotnet
oc expose svc web
# Manually Add agcoolstoresm into Service Mesh member roll
oc patch dc/catalog --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc patch dc/catalog --patch '{"spec": {"template": {"spec": {"containers": [{"name": "catalog", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}'
oc rollout latest dc/catalog
oc patch dc/gateway --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc patch dc/gateway --patch '{"spec": {"template": {"spec": {"containers": [{"name": "gateway", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}' 
oc rollout latest dc/gateway 
oc patch dc/inventory --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc patch dc/inventory --patch '{"spec": {"template": {"spec": {"containers": [{"name": "inventory", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}'
oc rollout latest dc/inventory
oc patch dc/web --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc rollout latest dc/web
oc patch dc/inventory-dotnet --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc rollout latest dc/inventory-dotnet
#
oc create -f istio-gateway.yml
oc create -f virtualservice.yml
#
oc set env dc/web COOLSTORE_GW_ENDPOINT=http://istio-ingressgateway-istio-system.apps.gitoc4ga.itaas.s2-eu.capgemini.com/agcoolstoresm
oc rollout latest dc/web
#
# curl http://istio-ingressgateway-istio-system.apps.gitoc4ga.itaas.s2-eu.capgemini.com/agcoolstoresm/api/products
#

