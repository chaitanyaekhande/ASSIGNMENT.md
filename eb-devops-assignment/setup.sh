#!/usr/bin/env bash
# One-command, idempotent setup: kind cluster "demo" + ingress-nginx + image + chart.
set -euo pipefail
cd "$(dirname "$0")"

CLUSTER=demo
NS=demo
RELEASE=demo
IMAGE=demo-service:1.0.0
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml"

for bin in docker kind kubectl helm; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin" >&2; exit 1; }
done

echo "==> kind cluster '$CLUSTER'"
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "    already exists, reusing"
else
  cat <<KIND | kind create cluster --name "$CLUSTER" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - { containerPort: 80,  hostPort: 80,  protocol: TCP }
      - { containerPort: 443, hostPort: 443, protocol: TCP }
KIND
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null

echo "==> ingress-nginx"
kubectl apply -f "$INGRESS_MANIFEST"
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

echo "==> build + load image $IMAGE"
docker build -t "$IMAGE" service/
kind load docker-image "$IMAGE" --name "$CLUSTER"

echo "==> helm release '$RELEASE' in namespace '$NS'"
# The admission webhook can lag the controller becoming Ready, so retry briefly.
for attempt in 1 2 3 4 5; do
  if helm upgrade --install "$RELEASE" chart/ -n "$NS" --create-namespace --wait --timeout 120s; then
    break
  fi
  [ "$attempt" = 5 ] && { echo "helm failed after $attempt attempts" >&2; exit 1; }
  echo "    helm attempt $attempt failed, retrying in 10s"; sleep 10
done

echo "==> done. Verify with the commands in README.md"
