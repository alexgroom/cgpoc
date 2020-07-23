#
# Simple tekton pipeline to build all components
#
oc new-project agcoolstorepipeline 
oc apply -f deployments/catalog.yaml
oc apply -f deployments/catalog.yaml
oc apply -f deployments/catalog.yaml
oc apply -f deployments/catalog.yaml
oc apply -f simple_pipeline.yaml
oc apply -f pipelineresources.yaml
