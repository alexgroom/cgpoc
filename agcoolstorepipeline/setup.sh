#
# Simple tekton pipeline to build all components
#
oc new-project agcoolstorepipeline 
oc apply -f deployments/catalog.yaml
oc apply -f deployments/inventory.yaml
oc apply -f deployments/gateway.yaml
oc apply -f deployments/web.yaml
oc apply -f simple_pipeline.yaml
oc apply -f pipelineresources.yaml
