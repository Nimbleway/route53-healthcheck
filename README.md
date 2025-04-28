# route53-healthcheck

GitHub Action to create and manage AWS Route53 health checks for Kubernetes services.

## Features
- Create or update Route53 health checks for Kubernetes services
- Support for both Ingress and Service resources
- Can return health check ID for use in workflows
- Supports direct domain specification or extraction from Kubernetes resources

## Usage

### Basic usage with CONFIG_FILE
```yaml
- name: Setup Route53 Healthcheck
  uses: Nimbleway/route53-healthcheck@v1
  env:
    CONFIG_FILE: path/to/kubernetes/manifest.yaml
    USE_INGRESS: "true"
    NAMESPACE: "my-namespace"
```

### Direct domain specification
```yaml
- name: Setup Route53 Healthcheck
  uses: Nimbleway/route53-healthcheck@v1
  env:
    DOMAIN: "example.com"
    RETURN_ID_ONLY: "true"
```

## Outputs
When `RETURN_ID_ONLY` is set to `true`, the health check ID will be available as output.

```yaml
- name: Get Healthcheck ID
  id: healthcheck
  uses: Nimbleway/route53-healthcheck@v1
  env:
    DOMAIN: "example.com"
    RETURN_ID_ONLY: "true"

- name: Use Healthcheck ID
  run: echo "The health check ID is ${{ steps.healthcheck.outputs.HEALTH_CHECK_ID }}"
```

## Development

```bash
git tag 1.0.28
git push --tags
```