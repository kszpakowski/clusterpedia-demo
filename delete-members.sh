for i in {1..3}; do
    kind delete cluster --name clusterpedia-demo-member$i
done