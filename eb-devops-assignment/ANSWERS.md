# Part 5 — ingress-nginx → Gateway API, ~40 Ingresses, zero downtime

**Approach: run both side by side, move traffic gradually, keep rollback trivial.**

1. **Inventory first.** List every Ingress with its annotations (`kubectl get ingress -A -o yaml`). Annotations (rewrites, auth, timeouts, snippets, body size, canary) are where behaviour hides; Gateway API has no 1:1 for many of them.
2. **Pick a conformant controller** (Envoy Gateway, Cilium, NGINX Gateway Fabric…) and install the Gateway API CRDs, pinned to a version. Deploy it *alongside* ingress-nginx with its own LoadBalancer IP.
3. **Translate** Ingress → Gateway/HTTPRoute (tooling such as `ingress2gateway` helps, but review output by hand). Move TLS certs/cert-manager to the Gateway listeners.
4. **Test on the new IP** with `curl --resolve` and synthetic checks, comparing status codes, headers and redirects against the old path.
5. **Shift traffic by DNS**, lowest-risk services first, using weighted records / short TTLs (lowered days earlier). Watch 5xx rate, latency and logs per route; roll back by flipping DNS weight.
6. **Decommission** ingress-nginx only after a full traffic cycle (including month-end/batch jobs) shows zero hits.

**What I expect to break**
- Snippet/`configuration-snippet` annotations and custom Lua: no equivalent, need redesign.
- Regex path semantics and rewrite behaviour differ subtly.
- Default timeouts, max body size, and header handling (X-Forwarded-*, real client IP).
- Cross-namespace references need `ReferenceGrant`; RBAC/ownership changes (Gateway vs Route owners).
- Client-IP preservation, WebSockets/gRPC, and DNS TTL caching by clients.
- Monitoring/alerts and dashboards built on nginx metrics.
