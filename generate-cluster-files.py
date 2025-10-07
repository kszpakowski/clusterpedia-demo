import yaml
import os

ip = "host.docker.internal"

with open(os.environ["HOME"] + "/.kube/config", "r") as kubeconfig_file:
    kubeconfig = yaml.safe_load(kubeconfig_file)

    member_ctxs = [
        ctx["context"] for ctx in kubeconfig["contexts"] if "member" in ctx["name"]
    ]

    for member_ctx in member_ctxs:
        cluster = [
            cluster["cluster"]
            for cluster in kubeconfig["clusters"]
            if cluster["name"] == member_ctx["cluster"]
        ][0]
        user = [
            user["user"]
            for user in kubeconfig["users"]
            if user["name"] == member_ctx["user"]
        ][0]

        name = member_ctx["cluster"].replace("kind-", "")
        port = int(cluster["server"].split(":")[-1]) - 1
        print(name, port)
        pedia_cluster = {
            "apiVersion": "cluster.clusterpedia.io/v1alpha2",
            "kind": "PediaCluster",
            "metadata": {
                "name": name,
            },
            "spec": {
                "apiserver": f"https://{ip}:{port}",
                "caData": cluster.get("certificate-authority-data", ""),
                "certData": user.get("client-certificate-data", ""),
                "keyData": user.get("client-key-data", ""),
                "syncResources": [
                    # {"group": "apps", "resources": ["deployments"]},
                    {
                        "group": "apiextensions.crossplane.io",
                        "resources": ["compositions", "compositeresourcedefinitions"],
                    },
                    { "group": "storage.example.org", "resources": ["*"]},
                ],
            },
        }

        yaml.dump(pedia_cluster, open(f"clusters/{name}.yaml", "w"), sort_keys=False)
        # print(cluster)
