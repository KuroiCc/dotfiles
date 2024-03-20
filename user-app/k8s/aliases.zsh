alias k='kubectl'
function kall() {
    kubectl get "$(kubectl api-resources --namespaced=true --verbs=list -o name | tr "\n" "," | sed -e 's/,$//')"
}
