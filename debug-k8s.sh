#!/bin/bash
# Debugging-Script für soundterror Kubernetes Service

NAMESPACE="soundterror"
SERVICE_NAME="soundterror-service"
POD_LABEL="app=soundterror"

echo "=== Prüfe Namespace ==="
kubectl get namespace $NAMESPACE

echo -e "\n=== Prüfe Pod Status ==="
kubectl get pods -n $NAMESPACE -l $POD_LABEL

echo -e "\n=== Prüfe Service ==="
kubectl get svc -n $NAMESPACE $SERVICE_NAME
kubectl describe svc -n $NAMESPACE $SERVICE_NAME

echo -e "\n=== Prüfe Endpoints ==="
kubectl get endpoints -n $NAMESPACE $SERVICE_NAME

echo -e "\n=== Prüfe Ingress ==="
kubectl get ingress -n $NAMESPACE
kubectl describe ingress -n $NAMESPACE soundterror-ingress

echo -e "\n=== Prüfe TLS-Secret ==="
kubectl get secret -n $NAMESPACE my-tls-secret

echo -e "\n=== Pod Logs ==="
kubectl logs -n $NAMESPACE -l $POD_LABEL --tail=50

echo -e "\n=== Port-Forward Test (lokal) ==="
echo "Starte Port-Forward. Öffne dann: https://localhost:8443"
kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8443:8443 &
PF_PID=$!
sleep 2
curl -k -I https://localhost:8443/ || echo "Fehler beim Curl"
kill $PF_PID 2>/dev/null

echo -e "\n=== Ingress Host ==="
kubectl get ingress -n $NAMESPACE soundterror-ingress -o jsonpath='{.spec.rules[0].host}'
echo ""

