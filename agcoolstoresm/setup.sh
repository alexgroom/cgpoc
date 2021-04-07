# script to install agcoolstoresm  components
#
# First install elastic serach, jaeger Operators
# Create istio-system project
# Install kiali into that project
# Install Service Mesh Operator into istio-system
# Create Control plane and Member roll
oc new-project agcoolstoresm
##############
# PLEASE manually Add agcoolstoresm into Service Mesh member roll
#
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog \
	 -l app=catalog,app.kubernetes.io/part-of=coolstore --as-deployment-config
#
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  \
	-l app=inventory,app.kubernetes.io/part-of=coolstore --as-deployment-config
# create gateway and apply environment variables
oc new-app java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app=gateway,app.kubernetes.io/part-of=coolstore --as-deployment-config\
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
#
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web \
	-l app=web,app.kubernetes.io/part-of=coolstore --as-deployment-config
#
oc new-app dotnet:3.1~https://github.com/alexgroom/inventory-api-1st-dotnet.git --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app=inventory-dotnet,app.kubernetes.io/part-of=coolstore,version=dotnet --as-deployment-config
# configure dev console labels
oc label dc gateway app.openshift.io/runtime=vertx
oc label dc catalog app.openshift.io/runtime=spring
oc label dc inventory app.openshift.io/runtime=quarkus
oc label dc web app.openshift.io/runtime=nodejs
oc label dc inventory-dotnet app.openshift.io/runtime=dotnet
# configure service mesh route labels
oc patch dc gateway -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}' 
oc patch dc catalog -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
oc patch dc inventory -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
oc patch dc web -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
oc patch dc inventory-dotnet -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
#
# Patch the inventory and dotnet services selector to work nicely with mesh, removing all the extra labels added by new-app
#
oc patch svc/inventory --patch '{"spec": {"selector": null }}'
oc patch svc/inventory --patch '{"spec": {"selector": {"app": "inventory"}}}}'
oc patch svc/inventory-dotnet --patch '{"spec": {"selector": null }}'
oc patch svc/inventory-dotnet --patch '{"spec": {"selector": {"app": "inventory-dotnet"}}}}'
#
# Align the port names according to the service mesh Gateway
#
oc patch svc/inventory --patch '{"spec": { "ports": [{ "name":"http", "port":8080}]}}'
oc patch svc/inventory-dotnet --patch '{"spec": { "ports": [{ "name":"http", "port":8080}]}}'
oc patch svc/catalog --patch '{"spec": { "ports": [{ "name":"http", "port":8080}]}}'
oc patch svc/gateway --patch '{"spec": { "ports": [{ "name":"http", "port":8080}]}}'

# expose routes
oc expose svc gateway
oc expose svc inventory
oc expose svc catalog
oc expose svc inventory-dotnet
oc expose svc web
sleep 30
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
# Tell the web server the new gateway location
sleep 10
export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
oc set env dc/web COOLSTORE_GW_ENDPOINT=http://$GATEWAY_URL/agcoolstoresm
oc rollout latest dc/web

