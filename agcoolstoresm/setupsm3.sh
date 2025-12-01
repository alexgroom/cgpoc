# script to install agcoolstoresm  components
#
# Create istio-system project
# Install kiali into that project
# Install Service Mesh Operator into istio-system
##############
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
oc label namespace $SM_PROJECT istio-injection=enabled
oc label namespace $SM_PROJECT istio-discovery=enabled 

oc new-app java:openjdk-17-ubi8~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog \
	 -l app=catalog,app.kubernetes.io/part-of=coolstore 
#
oc new-app java:openjdk-17-ubi8~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  \
	-l app=inventory,app.kubernetes.io/part-of=coolstore 
# create gateway and apply environment variables
oc new-app java:openjdk-17-ubi8~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway \
   -l app=gateway,app.kubernetes.io/part-of=coolstore\
  -e COMPONENT_CATALOG_HOST=catalog -e COMPONENT_INVENTORY_HOST=inventory -e COMPONENT_CATALOG_PORT=8080 -e COMPONENT_INVENTORY_PORT=8080
#
oc new-app https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web \
	-l app=web,app.kubernetes.io/part-of=coolstore 
#
oc new-app dotnet:6.0~https://github.com/alexgroom/inventory-api-1st-dotnet.git --context-dir=src/Coolstore.Inventory --name=inventory-dotnet \
  -l app=inventory-dotnet,app.kubernetes.io/part-of=coolstore 
# configure dev console labels
oc label deployment gateway app.openshift.io/runtime=vertx
oc label deployment catalog app.openshift.io/runtime=spring
oc label deployment inventory app.openshift.io/runtime=quarkus
oc label deployment web app.openshift.io/runtime=nodejs
oc label deployment inventory-dotnet app.openshift.io/runtime=dotnet
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

oc apply -f https://raw.githubusercontent.com/istio-ecosystem/sail-operator/main/chart/samples/ingress-gateway.yaml

oc create -f istio-gateway.yml
oc create -f podmonitor.yml
# modify the istio file so it is named to the current project
sed s/agcoolstoresm/$SM_PROJECT/ virtualservice.yml | oc apply -f -
#
# Tell the web server the new gateway location
#sleep 10
oc expose service istio-ingressgateway

export GATEWAY_URL=$(oc get route istio-ingressgateway -o jsonpath='{.spec.host}')
oc set env deployment/web COOLSTORE_GW_ENDPOINT=http://$GATEWAY_URL/$SM_PROJECT

