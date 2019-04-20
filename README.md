# Kubernetes with Istio

- `alias kc="kubectl"`
- `alias kcl="kc logs -l app="`
- `kc get po`
- `kc get svc`
- `kc get all`

## FAQ

1. Moving to Istio.

There is a helm template generated at `make helm`. Note there is additional configuration using `gateways.istio-ingressgateway.loadBalancerIP=` using a Google Compute Regional IP due to me having no Domain.

Installing the sidecar is automatic, using the instructions provided at https://istio.io/docs/setup/kubernetes/sidecar-injection/.

Service and Pod YAML files should be updated as follows https://istio.io/docs/setup/kubernetes/spec-requirements/.

Istio moves incoming connection support from Ingress to the more powerful Gateways. https://thenewstack.io/why-you-should-care-about-istio-gateways/.

2. Gateway is not routing to my Service.

Unfortunately the gateway needs the non-namespace domain name, even if deployed on same namespace. E.g `wilde.default.svc.cluster.local` instead of `wilde`. See https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

## Adding health check to your gRPC Service.

- https://github.com/grpc-ecosystem/grpc-health-probe

## Debugging connectivity to your gRPC Service.

- `https://github.com/grpc/grpc/blob/master/doc/command_line_tool.md`
- Register reflection service on own gRPC service.

```
//go
s := grpc.NewServer(...)
reflection.Register(s)
```

- make debug
- make ingress-gateway-logs
- kclYOUR_APP
  - Choose Envoy Proxy


## TODO

- Buy and add a Domain and replace Static IP.
- Fluentd Istio Logs to Persistent Storage.
- Multicluster support.
