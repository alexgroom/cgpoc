# script to install agcoolstore serverless components
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
oc new-build java:openjdk-17-ubi8~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  
kn service create catalog --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/catalog \
  --label='app.openshift.io/runtime=spring' --label='app.kubernetes.io/part-of=coolstore'
#
oc new-build java:openjdk-17-ubi8~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  
kn service create inventory --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/inventory \
  --label='app.openshift.io/runtime=quarkus' --label='app.kubernetes.io/part-of=coolstore'
# add web UI
oc new-build https://github.com/alexgroom/cnw3.git --context-dir=web-nodejs --name=web 
kn service create web --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/web \
  --label='app.openshift.io/runtime=nodejs' --label='app.kubernetes.io/part-of=coolstore' --label 'bindings.knative.dev/include=true'

# create dotnet gateway and apply environment variables
oc new-build dotnet:6.0~https://github.com/alexgroom/cnw3.git --context-dir=gateway-dotnet --name=gateway
kn service create gateway --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/gateway \
  --label='app.openshift.io/runtime=dotnet' --label='app.kubernetes.io/part-of=coolstore' \
   --env COMPONENT_CATALOG_HOST=catalog.$SERVERLESS_PROJECT.svc.cluster.local --env COMPONENT_INVENTORY_HOST=inventory.$SERVERLESS_PROJECT.svc.cluster.local \
   --env COMPONENT_CATALOG_PORT=80 --env COMPONENT_INVENTORY_PORT=80

# create vertx gateway and apply environment variables
# oc new-build java:11~https://github.com/alexgroom/cnw3.git --context-dir=gateway-vertx --name=gateway
# kn service create gateway --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/gateway \
#   --label='app.openshift.io/runtime=vertx' --label='app.kubernetes.io/part-of=coolstore' \
#    --env COMPONENT_CATALOG_HOST=catalog.$SERVERLESS_PROJECT.svc.cluster.local --env COMPONENT_INVENTORY_HOST=inventory.$SERVERLESS_PROJECT.svc.cluster.local \
#    --env COMPONENT_CATALOG_PORT=80 --env COMPONENT_INVENTORY_PORT=80
