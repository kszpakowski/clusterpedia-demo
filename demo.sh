CLUSTER_NAME_PREFIX=clusterpedia-demo

git clone https://github.com/clusterpedia-io/clusterpedia.git

kind create cluster --name "${CLUSTER_NAME_PREFIX}-root"

for i in {1..3}; do
  kind create cluster --name "${CLUSTER_NAME_PREFIX}-member$i" --config kind-config.yaml
done

uv init
uv add pyyaml
uv run generate-cluster-files.py

kubectx kind-"${CLUSTER_NAME_PREFIX}-root"

kubectl apply -f clusterpedia-storage/manifests.yaml
kubectl apply -f clusterpedia/deploy
kubectl apply -f clusters
