# Architecture

AgentRouteKit separates classification, transport, and operations.

## Layers

```mermaid
flowchart TB
  Intent["Intent<br/>What kind of traffic is this?"] --> Policy["Policy<br/>Which rule owns it?"]
  Policy --> Transport["Transport<br/>direct / relay / stable egress"]
  Transport --> Ops["Operations<br/>switch / diagnose / monitor / recover"]
```

## Runtime

```mermaid
sequenceDiagram
  participant Tool as AI tool
  participant Router as Local mihomo
  participant Relay as Relay sing-box
  participant Stable as Stable AI egress
  participant API as AI provider

  Tool->>Router: HTTPS request to Claude domain
  Router->>Router: match AI provider suffix
  Router->>Relay: encrypted tunnel
  Relay->>Stable: HTTP CONNECT upstream
  Stable->>API: provider request
  API-->>Tool: response over same route
```

Corporate/internal and domestic traffic should not touch the stable AI egress.

```mermaid
flowchart LR
  App["Normal app"] --> Router["Local router"]
  Router -- corporate/internal suffix --> Resolver["native OS resolver"]
  Resolver --> Corp["internal service"]
  Router -- domestic suffix / GeoIP --> Direct["direct network"]
```

## Why a Relay Exists

The relay keeps the client-to-relay path encrypted and gives the project one central place to:

- Forward Claude domains to stable egress.
- Let general overseas traffic use relay direct egress.
- Rotate stable egress providers without changing client policy.
- Add server-side health checks and fallback later.
