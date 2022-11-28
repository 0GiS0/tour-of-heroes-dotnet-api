dapr run --app-id tour-of-heroes-api --app-port 5222 -- dotnet run

# Create Jaeger container
docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HOST_PORT=:9412 \
  -p 16686:16686 \
  -p 9412:9412 \
  jaegertracing/all-in-one:1.22

# To view traces
http://localhost:16686