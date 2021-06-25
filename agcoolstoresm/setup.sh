# script to install agcoolstoresm  components
#
# First install elastic serach, jaeger Operators
# Create istio-system project
# Install kiali into that project
# Install Service Mesh Operator into istio-system
# Create Control plane and Member roll
##############
# PLEASE manually Add <projectname> into Service Mesh member roll
#
# $1 = project name
if test -z "$1" 
then 
  export SM_PROJECT=agcoolstoresm
else
  export SM_PROJECT=$1
  oc new-project $SM_PROJECT
  oc project $SM_PROJECT
fi
#
# $2 = Service mesh project name
if test -z "$2" 
then 
  export ISTIO_PROJECT=istio-system 
else
  export ISTIO_PROJECT=$2
fi
#
echo "Using project:" $SM_PROJECT
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
  -l app=inventory-dotnet,app.kubernetes.io/part-of=coolstore --as-deployment-config
# configure dev console labels
oc label dc gateway app.openshift.io/runtime=vertx
oc label dc catalog app.openshift.io/runtime=spring
oc label dc inventory app.openshift.io/runtime=quarkus
oc label dc web app.openshift.io/runtime=nodejs
oc label dc inventory-dotnet app.openshift.io/runtime=dotnet
# configure service mesh route labels - note that web is not part of the mesh
oc patch dc gateway -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}' 
oc patch dc catalog -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
oc patch dc inventory -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
oc patch dc inventory-dotnet -p '{"spec":{"template":{"metadata":{"labels":{"maistra.io/expose-route":"true"}}}}}'
##
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
#oc patch dc/catalog --patch '{"spec": {"template": {"spec": {"containers": [{"name": "catalog", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}'
oc rollout latest dc/catalog
oc patch dc/gateway --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
#oc patch dc/gateway --patch '{"spec": {"template": {"spec": {"containers": [{"name": "gateway", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}' 
oc rollout latest dc/gateway 
oc patch dc/inventory --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
#oc patch dc/inventory --patch '{"spec": {"template": {"spec": {"containers": [{"name": "inventory", "command" : ["/bin/bash"], "args": ["-c", "until $(curl -o /dev/null -s -I -f http://127.0.0.1:15000); do echo \"Waiting for Istio Sidecar...\"; sleep 1; done; sleep 10; /usr/local/s2i/run"]}]}}}}'
oc rollout latest dc/inventory
oc patch dc/inventory-dotnet --patch '{"spec": {"template": {"metadata": {"annotations": {"sidecar.istio.io/inject": "true"}}}}}' 
oc rollout latest dc/inventory-dotnet
# Create the ingress gateway and virtual service for initial use
oc create -f istio-gateway.yml
# modify the istio file so it is named to the current project
sed s/agcoolstoresm/$SM_PROJECT/ virtualservice.yml | oc apply -f -
#
# Tell the web server the new gateway location
sleep 10
export GATEWAY_URL=$(oc -n $ISTIO_PROJECT get route istio-ingressgateway -o jsonpath='{.spec.host}')
oc set env dc/web COOLSTORE_GW_ENDPOINT=http://$GATEWAY_URL/$SM_PROJECT
oc rollout latest dc/web

