# script to install agcoolstoresm  components
#
# First install elastic serach, jaeger Operators
# Create istio-system project
# Install kiali into that project
# Install Service Mesh Operator into istio-system
# Create Control plane and Member roll
#oc new-project agcoolstoresm
# Manually Add agcoolstoresm into Service Mesh member roll
#
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog \
	 -l app=catalog,app.kubernetes.io/part-of=coolstore
#
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  \
	-l app=inventory,app.kubernetes.io/part-of=coolstore
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app=gateway,app.kubernetes.io/part-of=coolstore \
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
#
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web \
	-l app=web,app.kubernetes.io/part-of=coolstore
#
oc new-app dotnet:2.1~https://github.com/alexgroom/inventory-api-1st-dotnet.git#dotnet2.1 --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app=inventory,app.kubernetes.io/part-of=coolstore,version=dotnet
# configure dev console labels
oc label dc gateway app.openshift.io/runtime=java
oc label dc catalog app.openshift.io/runtime=java
oc label dc inventory app.openshift.io/runtime=java
oc label dc web app.openshift.io/runtime=nodejs
oc label dc inventory-dotnet app.openshift.io/runtime=dotnet
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
# Patch the components to run with sidecar
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
oc patch dc/inventory-dotnet --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc rollout latest dc/inventory-dotnet
# Create the ingress gateway and virtual service for initial use
oc create -f istio-gateway.yml
oc create -f virtualservice.yml
#
# Patch the inventory and dotnet services selector to work nicely with mesh, removing all the extra labels added by new-app
#
oc patch svc/inventory --patch '{"spec": {"selector": null }}'
oc patch svc/inventory --patch '{"spec": {"selector": {"app": "inventory"}}}}'
oc patch svc/inventory-dotnet --patch '{"spec": {"selector": null }}'
oc patch svc/inventory-dotnet --patch '{"spec": {"selector": {"app": "inventory-dotnet"}}}}'
#
# Tell the web server the new gateway location
#oc set env dc/web COOLSTORE_GW_ENDPOINT=http://istio-ingressgateway-istio-system.apps.gitoc4ga.itaas.s2-eu.capgemini.com/agcoolstoresm
oc set env dc/web COOLSTORE_GW_ENDPOINT=http://istio-ingressgateway-istio-system.apps.cluster-alton-1f57.alton-1f57.example.opentlc.com/agcoolstoresm
oc rollout latest dc/web
#
# Test the new ingress curl http://istio-ingressgateway-istio-system.apps.gitoc4ga.itaas.s2-eu.capgemini.com/agcoolstoresm/api/products
#

