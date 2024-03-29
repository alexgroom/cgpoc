# Script to create 4 demo projects in increasing stages of deployment
# ADd agcoolstore0
#
oc new-project agcoolserve0
../agcoolstore/setup-noproject.sh
../agcoolstore/setup-gateway-dotnet.sh
#
# Remove the old webUI dc
oc delete dc/web
oc delete svc/web
oc delete route web

# add gateway route supporting TLS
oc delete route gateway
oc create route edge gateway --service=gateway --insecure-policy=Allow 
#
# add web UI using the same image as was built for normal coolstore
kn service create web --image=image-registry.openshift-image-registry.svc:5000/agcoolserve0/web \
  --label='app.openshift.io/runtime=nodejs' --label='app.kubernetes.io/part-of=coolstore' --label 'bindings.knative.dev/include=true'

./setup-noproject.sh agcoolserve2
./setup-noproject.sh agcoolserve1
# Now add eventing
./setup-eventing.sh agcoolserve2
# add the enhanced project components
./setup-coolserv4.sh agcoolserve3
