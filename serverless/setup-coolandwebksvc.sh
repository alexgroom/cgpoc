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
../agcoolstore/setup-noproject.sh
../agcoolstore/setup-gateway-dotnet.sh
#
# Remove the old webUI
oc delete all --selector app=web
#
# add web UI
kn service create web --image=image-registry.openshift-image-registry.svc:5000/$SERVERLESS_PROJECT/web \
  --label='app.openshift.io/runtime=nodejs' --label='app.kubernetes.io/part-of=coolstore' --label 'bindings.knative.dev/include=true'

