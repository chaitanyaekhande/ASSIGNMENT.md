# Findings — Part 4 debug lab

> Entries below have the **Cause** and **Fix** worked out from reading the manifests. Every
> **Symptom** and **How I found it** must be replaced with the real output from *my* cluster
> (`./scenario.sh up`, `kubectl describe`, `kubectl logs`, …) and match `part4-session.log`.
> Defects 5 and 6 are still open.

---

## Defect 1 — migrate Job rejected, whole release fails to install

**Symptom:** TODO paste the `helm upgrade --install` error from `./scenario.sh up`.

**Cause:** `lab/broken-chart/templates/migrate-job.yaml` sets `restartPolicy: Always`. Jobs only allow `OnFailure` or `Never`, so the API server rejects the Job and Helm aborts the release — which *masks* the other defects because nothing gets installed.

**Fix:** `restartPolicy: OnFailure` (retries in place, bounded by `backoffLimit`).

**How I found it:** TODO

---

## Defect 2 — metrics pods never created

**Symptom:** TODO (`kubectl -n debug-lab describe rs -l app=metrics` events).

**Cause:** `metrics.resources` requests `cpu: "2"` / limits `"4"`, above the namespace `LimitRange` per-container max (`cpu: 1`, `cluster-state/limits.yaml`), so the ReplicaSet's pod creation is forbidden.

**Fix:** requests/limits `50m` / `200m` in `values.yaml`, matching the other workloads, rather than touching the LimitRange (which is environment, not bug).

**How I found it:** TODO

---

## Defect 3 — gateway cannot reach backend

**Symptom:** TODO (gateway logs / `/status` output showing backend not ok).

**Cause:** `gateway.env.BACKEND_URL` pointed at `backend.default.svc:8080`; the backend lives in namespace `debug-lab`.

**Fix:** `http://backend.debug-lab.svc:8080`.

**How I found it:** TODO

---

## Defect 4 — reporter cannot list pods

**Symptom:** TODO (`kubectl auth can-i list pods --as=system:serviceaccount:debug-lab:reporter` → `no`; reporter logs).

**Cause:** `rbac.yaml` bound the `reporter-read` Role to ServiceAccount `default`, not `reporter`, which is what the reporter Deployment runs as.

**Fix:** RoleBinding subject now uses `.Values.reporter.serviceAccountName`.

**How I found it:** TODO

---

## Defect 5

**Symptom:** TODO — not yet found. Run `./scenario.sh verify` after `up` and inspect what is still failing.

**Cause:** TODO

**Fix:** TODO

**How I found it:** TODO

---

## Defect 6

**Symptom:** TODO — not yet found.

**Cause:** TODO

**Fix:** TODO

**How I found it:** TODO

---

Not yet verified on a cluster; the open items above are what I would investigate next.
