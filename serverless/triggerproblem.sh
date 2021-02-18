# Script to create 3 demo projects in increasing stages of deployment
export SERVERLESS_PROJECT=triggerprob
oc new-project $SERVERLESS_PROJECT
#
echo "Using project:" $SERVERLESS_PROJECT
#
oc new-build java:11~https://github.com/alexgroom/cnw3.git --context-dir=catalog-spring-boot --name=catalog  
kn service create catalog --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/catalog \
  --label='app.openshift.io/runtime=spring' --label='app.kubernetes.io/part-of=coolstore'
#
# Take the maria branch of inventory simce it support db access
oc new-build java:11~https://github.com/alexgroom/cnw3.git --context-dir=inventory-quarkus --name=inventory  
kn service create inventory --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/inventory \
  --label='app.openshift.io/runtime=quarkus' --label='app.kubernetes.io/part-of=coolstore'
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

sleep 10
# Now add eventing
# Add the default broker 
oc label namespace $SERVERLESS_PROJECT bindings.knative.dev/include=true
kn broker create default
#
# Add the K_SINK sink binding for the web server to broker, or failing that hard code the broker value
kn source binding create bind-webserver --subject Service:serving.knative.dev/v1:web --sink broker:default
#
# Set this on inital KSVC web build and force a revision
kn service update web --label 'bindings.knative.dev/include=true'
# 
#
# Add triggers fors inventory and catalog
kn trigger create events-trigger2 --filter type=web-wakeup --sink ksvc:inventory
kn trigger create events-trigger3 --filter type=web-wakeup --sink ksvc:catalog
sleep 10
# Now add golang config
oc new-build https://github.com/alexgroom/cnw3.git --context-dir=catalog-go --name=catalog-go --strategy=docker
kn service create catalog-go --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/catalog-go \
  --label='app.openshift.io/runtime=golang' --label='app.kubernetes.io/part-of=coolstore'

# update gateway and apply new environment variables
kn service update gateway --env COMPONENT_CATALOG_HOST=catalog-go.$SERVERLESS_PROJECT.svc.cluster.local 
# add trigger
kn trigger create events-trigger4 --filter type=web-wakeup --sink ksvc:catalog-go
#
# now delete the KSVC and check the toplogy display
echo "Wait 4 minutes and then delete a KSVC"
sleep 60
echo "3 minutes"
sleep 60
echo "2 minutes"
sleep 60
echo "1 minute"
sleep 60
# delete a KSVC
kn service delete catalog