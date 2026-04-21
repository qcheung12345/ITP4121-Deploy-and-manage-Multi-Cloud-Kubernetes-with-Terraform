# Documentation Index

## Grading and Evidence

- [report.md](report.md)


## Repository Map
- [FILE_CLASSIFICATION.md](FILE_CLASSIFICATION.md)

## Main Project Areas
- [main.tf](../main.tf)
- [variables.tf](../variables.tf)
- [outputs.tf](../outputs.tf)
- [modules/](../modules/)
- [deploy/](../deploy/)
- [website/](../website/)
- [terraform/](../terraform/)

## Marking Evidence Template

Use this table to organize screenshots and command outputs before submission.

| Rubric Item | Max Mark | Status | Evidence Screenshot(s) | Command / Output Proof | Notes |
|---|---:|---|---|---|---|
| Setup GitHub Project and shared to lecturer | 5 | Pending | Add screenshot link | Add sharing proof | Include lecturer access confirmation |
| Using multiple Cloud Providers | 15 | Pending | Azure outputs, GCP outputs | Terraform outputs for both clouds | Show both clusters and networks |
| Multiple VMs in VPC and 2 private subnets | 5 | Pending | Azure subnet and node pool, GCP subnet and node pool | az and gcloud subnet and node pool commands | Show 2 subnets per cloud |
| Unique Kubernetes Application with database | 5 | Pending | kubectl resources, app page | kubectl get deploy,sts,svc,pods | Show app and db together |
| Cluster AutoScaler | 5 | Pending | AKS autoscale, GKE autoscale, HPA | az and gcloud autoscale, kubectl get hpa | Include min and max values |
| Connect to Database | 5 | Pending | App write and read success, logs | kubectl logs and app test | Show real db interaction |
| Using Kubernetes Secret properly | 5 | Pending | secrets list and describe output | kubectl get and describe secret | Show app, db, tls secrets |
| Using Cloud native load balancer | 5 | Pending | Ingress address and reachable URL | kubectl get ingress -o wide | Show cloud ingress endpoint |
| With SSL/TLS | 5 | Pending | tls secret exists, https response | kubectl get secret guestbook-tls, curl -vk https://host | Show handshake and response |
| Stream application log data to cloud logging services | 5 | Pending | Azure Monitor logs, GCP Logs Explorer | Query screenshots and timestamps | Include app or cluster log lines |
| Multiple Cloud High Availability | 5 | Pending | Traffic Manager profile, fqdn resolve | terraform global outputs, nslookup, curl | Show both endpoints in global layer |

## Final Submission Checklist

1. One clean run of deploy/all setup.sh with successful stage summaries.
2. Cloud screenshots for ingress, tls, autoscaling, and logging on both Azure and GCP.
3. Global DNS proof with Traffic Manager outputs and fqdn resolution.
4. Evidence table completed with screenshot links and command proofs.
