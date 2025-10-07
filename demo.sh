CLUSTER_NAME_PREFIX=clusterpedia-demo

git clone https://github.com/clusterpedia-io/clusterpedia.git

kind create cluster --name "${CLUSTER_NAME_PREFIX}-root"

helm repo add crossplane https://charts.crossplane.io/stable
helm repo update

for i in {1..3}; do
  MEMBER_CLUSTER_NAME="${CLUSTER_NAME_PREFIX}-member$i"

  echo "Creating member cluster: $MEMBER_CLUSTER_NAME"
  kind create cluster --name "$MEMBER_CLUSTER_NAME" --config kind-config.yaml
  kubectx kind-"${MEMBER_CLUSTER_NAME}"

  echo "Installing Crossplane (or upgrading if present)"
  helm upgrade --install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system --create-namespace \
    --wait --timeout 5m
  
  echo "Waiting for XRD CRD to be established"
  until kubectl get crd compositeresourcedefinitions.apiextensions.crossplane.io >/dev/null 2>&1; do
    echo "  .. still waiting for compositeresourcedefinitions CRD to be created"; sleep 2
  done
  kubectl wait --for=condition=Established crd/compositeresourcedefinitions.apiextensions.crossplane.io --timeout=120s

  echo "Installing XRD for XBucket"
  kubectl apply -f crossplane-resources/xbucket-xrd.yaml

  echo "Waiting for XRD to be established"
  until kubectl get crd xbuckets.storage.example.org >/dev/null 2>&1; do
    echo "  .. waiting for CRD xbuckets.storage.example.org to be created by Crossplane"; sleep 2
  done
  kubectl wait --for=condition=Established crd/xbuckets.storage.example.org --timeout=60s

  echo "Creating XBucket"
  kubectl apply -f crossplane-resources/xbucket-xr.yaml
done

uv init
uv add pyyaml
uv run generate-cluster-files.py

kubectx kind-"${CLUSTER_NAME_PREFIX}-root"

kubectl apply -f clusterpedia-storage/manifests.yaml
kubectl apply -f clusterpedia/deploy # TODO clusterpedia/deploy/clusterpedia_apiserver_deployment.yaml requires patching - volumeMount tracing-config not found
kubectl apply -f clusters



# curl -sfL https://raw.githubusercontent.com/clusterpedia-io/clusterpedia/v0.7.0/hack/gen-clusterconfigs.sh | sh -
# kubectl --cluster clusterpedia get xbuckets

sleep 20
kubectl get --raw="/apis/clusterpedia.io/v1beta1/resources/apis/storage.example.org/v1alpha1/xbuckets" | jq