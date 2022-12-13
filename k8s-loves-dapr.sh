# Create k8s cluster for dapr
kind create cluster --name dapr-k8s --config kind-cluster-config.yaml

# Initialice dapr
dapr init --kubernetes --wait

# Verify 
dapr status -k

# Deploy tour-of-heroes 
kubectl apply -f dapr-k8s-manifests --recursive

# Wait until pods are ready
brew install watch
watch kubectl get pods

# Check services
k get svc

# cURL things
HERO_API_URL=http://localhost:30080/api/hero
VILLAIN_API_URL=http://localhost:30090/villain

# check if hero api is working
curl $HERO_API_URL | jq

curl --header "Content-Type: application/json" \
  --request POST \
  --data '{
    "name": "Batman",
    "description": "Un multimillonario magnate empresarial y filántropo dueño de Empresas Wayne en Gotham City. Después de presenciar el asesinato de sus padres, el Dr. Thomas Wayne y Martha Wayne en un violento y fallido asalto cuando era niño, juró venganza contra los criminales, un juramento moderado por el sentido de la justicia.",
    "alterEgo": "Bruce Wayne" 
   
}' \
  $HERO_API_URL | jq

#check get heroes again
curl $HERO_API_URL | jq

# check if villain api is working
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{
    "name": "Octopus",
    "hero":{
        "name": "Spiderman",
        "description": "un joven huérfano neoyorquino que adquiere superpoderes después de ser mordido por una araña radiactiva, y cuya ideología como héroe se ve reflejada primordialmente en la expresión «un gran poder conlleva una gran responsabilidad».20​21​ Suele ser asociado con una personalidad bromista, amable, inventiva y optimista, lo que le ha llevado a ser catalogado como el «vecino amigable» de cualquiera lo cual, aunado a sus vivencias caracterizadas por los problemas cotidianos.",
        "alterEgo": "Peter Parker"     
    },
    "description": "Es un científico loco muy inteligente y algo fornido que tiene cuatro apéndices fuertes que se asemejan a los tentáculos de un pulpo, que se extienden desde la parte posterior de su cuerpo y pueden usarse para varios propósitos."
}' \
  $VILLAIN_API_URL | jq

# check if pub sub is working viewing logs
kubectl logs -l app=tour-of-heroes-api -c tour-of-heroes-api

# check if service to service invocation is working
curl $HERO_API_URL/villain/spiderman | jq

# Forward a port to Dapr dashboard
dapr dashboard -k -p 9999

# Access to zipkin to see traces
http://localhost:30070

# Delete cluster
kind delete cluster --name dapr-k8s