# script to install agcoolstore serverless eventing components
# assumes kn CLI has been installed
# $1 = project name
if test -z "$1" 
then 
  export SERVERLESS_PROJECT=$(oc project --short) 
else
  export SERVERLESS_PROJECT=$1
  oc project $SERVERLESS_PROJECT
fi
#
echo "Using project:" $SERVERLESS_PROJECT
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
#
# Debugging
#
# Event display service
#
#kn service create event-display --image quay.io/openshift-knative/knative-eventing-sources-event-display:latest --scale 1
#kn trigger create events-trigger4 --sink ksvc:event-display
#

