# DevOps take-home — Enterprise Bot GmbH

Layout: `service/` (Part 1), `chart/` (Part 2), `setup.sh` (Part 3), `lab/` (Part 4), `ANSWERS.md` (Part 5).

## Run and verify

Needs Docker, kind, kubectl, helm.

```bash
./setup.sh            # safe to run twice
```

Verify the service:

```bash
kubectl -n demo get pods                          # 2/2 Running, Ready
kubectl -n demo get ingress                       # host demo.local
curl -s -H 'Host: demo.local' http://localhost/   # {"app": "demo", "version": "1.0.0", "pod": "..."}
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: demo.local' http://localhost/healthz   # 200
# optional: echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts  → curl http://demo.local/
```

Change config at runtime (no restart; takes up to ~1 min for kubelet to sync the mounted ConfigMap):

```bash
kubectl -n demo patch configmap demo --type merge -p '{"data":{"APP_NAME":"changed"}}'
```

Lab: `cd lab && ./scenario.sh up && ./scenario.sh verify` (see `lab/FINDINGS.md`).

## Resource requests and limits (and why)

| | CPU | Memory |
|---|---|---|
| requests | 50m | 32Mi |
| limits | 200m | 64Mi |

A stdlib Python HTTP server idles at roughly 15–25 MiB RSS and uses almost no CPU, so 32Mi/50m reserves a realistic floor for scheduling. Limits are ~2× memory headroom (to avoid OOMKills on a burst) and 4× CPU so a traffic spike isn't throttled hard. **TODO(Uday): measure with `kubectl top pod` on your cluster and adjust these numbers/explanation to what you actually saw.**

## What I deliberately skipped (and the risk)

- **TLS on the Ingress** — traffic is plain HTTP; fine locally, unacceptable in production (cert-manager + HTTPS redirect).
- **PodDisruptionBudget / HPA / topology spread** — a node drain could take both replicas down at once; no autoscaling under load.
- **NetworkPolicies** — any pod can reach the service.
- **Image tests/pinning by digest, SBOM, signing** — supply-chain risk; base image pinned by tag only.
- **Real config reload strategy** — ConfigMap-volume reads give live updates, but there's no schema validation of values.
- **Structured logging/metrics endpoint** — limited observability.

## What I'd change for production

Registry-hosted, digest-pinned, signed images; TLS via cert-manager; PDB + HPA + anti-affinity; NetworkPolicies; a proper app server and metrics (`/metrics`); resource sizing from real load tests; GitOps (Argo CD/Flux) instead of `setup.sh`; and migrating off ingress-nginx (see `ANSWERS.md`).

## How I used AI

- **Tool:** Claude (Anthropic) — **TODO(Uday): list any other tools.**
- **What it did:** drafted the service, Dockerfile, chart, `setup.sh`, CI workflow, `ANSWERS.md` and this README; spotted four lab defects by reading the manifests.
- **What had to be corrected / what I did myself:** **TODO(Uday): write this truthfully** — e.g. what you changed after running it on your cluster, the lab defects you found by investigating, and anything the AI got wrong. The Part 4 diagnosis, recording and pasted output are from my own cluster run.
