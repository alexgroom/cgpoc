#
#
# script to install agcoolstore serverless eventing components using Faas as the event filter
# assumes kn CLI has been installed
# $1 = project name
if test -z "$1" 
then 
  export SERVERLESS_PROJECT=$(oc project --short) 
else
  export SERVERLESS_PROJECT=$1
  oc new-project $SERVERLESS_PROJECT
fi
#
echo "Using project:" $SERVERLESS_PROJECT

#
# Take the maria branch of inventory simce it support db access
# add web UI
oc new-build https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web 
kn service create web --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/web \
  --label='app.openshift.io/runtime=nodejs' --label='app.kubernetes.io/part-of=coolstore' --label 'bindings.knative.dev/include=true'

# create dotnet gateway and apply environment variables
oc new-build dotnet:3.1~https://github.com/alexgroom/cnw3.git --context-dir=gateway-dotnet --name=gateway
kn service create gateway --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/gateway \
  --label='app.openshift.io/runtime=dotnet' --label='app.kubernetes.io/part-of=coolstore' \
   --env COMPONENT_CATALOG_HOST=catalog.$SERVERLESS_PROJECT.svc.cluster.local --env COMPONENT_INVENTORY_HOST=inventory.$SERVERLESS_PROJECT.svc.cluster.local \
   --env COMPONENT_CATALOG_PORT=80 --env COMPONENT_INVENTORY_PORT=80
# Now add eventing
# Add the default broker 
oc label namespace $SERVERLESS_PROJECT bindings.knative.dev/include=true
kn broker create default
#
# Add trigger for gateway
kn trigger create events-trigger5 --filter type=web-wakeup --sink ksvc:gateway
#
# Now add golang config and fast start inventory
oc new-build https://github.com/alexgroom/cnw3.git --context-dir=catalog-go --name=catalog-go --strategy=docker
kn service create catalog-go --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/catalog-go \
  --label='app.openshift.io/runtime=golang' --label='app.kubernetes.io/part-of=coolstore'

# update gateway and apply new environment variables
kn service update gateway --env COMPONENT_CATALOG_HOST=catalog-go.$SERVERLESS_PROJECT.svc.cluster.local 
# add trigger
kn trigger create events-trigger4 --filter type=web-wakeup --sink ksvc:catalog-go
#
oc new-app mariadb-ephemeral \
    --param=DATABASE_SERVICE_NAME=inventory-mariadb \
    --param=MYSQL_DATABASE=inventorydb \
    --param=MYSQL_USER=inventory \
    --param=MYSQL_PASSWORD=inventory \
    --labels=app=inventory \
    --labels=app.openshift.io/runtime=mariadb \
    --as-deployment-config
#
# Update inventory service
kn service create inventory --image=quay.io/agroom/inventory:latest \
  --label='app.openshift.io/runtime=quarkus' --label='app.kubernetes.io/part-of=coolstore'
# 
# Add triggers fors inventory and catalog
kn trigger create events-trigger2 --filter type=web-wakeup --sink ksvc:inventory
# Add service account
oc apply -f service-account.yaml
# Add event source
kn source apiserver create apisource --mode Resource --service-account events-sa --sink broker:default --resource "event:v1"
# Add event filter by building from fetched source and func.yaml
# cd ..cnw3/faas
# kn func deploy -n $SERVERLESS_PROJECT
# Build from quay image
oc apply -f faas.yaml
kn trigger create events-trigger6 --sink ksvc:faas --filter type=dev.knative.apiserver.resource.add
