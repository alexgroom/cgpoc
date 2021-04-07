# script to install agcoolstore serverless components
# assumes kn CLI has been installed
# $1 = project name
if test -z "$1" 
then 
  export SERVERLESS_PROJECT=$(oc project --short) 
else
  export SERVERLESS_PROJECT=$1
  oc project $SERVERLESS_PROJECT
fi
echo "Using project:" $SERVERLESS_PROJECT

oc new-build https://github.com/alexgroom/cnw3.git --context-dir=catalog-go --name=catalog-go --strategy=docker
kn service create catalog-go --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/catalog-go \
  --label='app.openshift.io/runtime=golang' --label='app.kubernetes.io/part-of=coolstore'

# update gateway and apply new environment variables
kn service update gateway --env COMPONENT_CATALOG_HOST=catalog-go.$SERVERLESS_PROJECT.svc.cluster.local 
# add trigger
kn trigger create events-trigger4 --filter type=web-wakeup --sink ksvc:catalog-go
#
# delete the old catalog service
kn service delete catalog
