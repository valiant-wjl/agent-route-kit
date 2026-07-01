# Policy Model

Policy is evaluated from most specific and safest to broadest.

```mermaid
flowchart TD
  Start[Connection] --> Private[LAN or private IP?]
  Private -- yes --> Direct[DIRECT]
  Private -- no --> AI[AI provider suffix?]
  AI -- yes --> AIRoute[Claude pinned route]
  AI -- no --> Corp[Corporate/internal suffix?]
  Corp -- yes --> CorpDirect[DIRECT + native resolver]
  Corp -- no --> Domestic[Domestic/direct suffix or GeoIP?]
  Domestic -- yes --> Direct
  Domestic -- no --> Mode[Selected mode]
  Mode --> Global[Global: relay]
  Mode --> AIOnly[Claude-only: direct unmatched traffic]
  Mode --> Bypass[Bypass: direct all traffic]
```

## Rule Packs

- `policy/ai-providers.yaml`: domains that require stable AI egress.
- `policy/corporate.example.yaml`: example structure for company/internal domains.
- `policy/domestic.example.yaml`: domains that should stay local/direct.

## Corporate/Internal Domains

Treat company and internal CDN domains as explicit first-class routes:

1. Route them `DIRECT`.
2. Resolve them through the OS resolver when VPN/MDM hooks DNS.
3. Add probes for critical suffixes.
4. Keep the real suffix list private if it identifies internal infrastructure.

The generic template is:

```yaml
nameserver-policy:
  "+.corp.example": system

rules:
  - DOMAIN-SUFFIX,corp.example,DIRECT
```
