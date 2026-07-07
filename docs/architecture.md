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

## Client Surfaces

Desktop and mobile clients use the same policy order. The desktop path is automated by this repository's macOS scripts. The mobile path is profile/rule reuse through a compatible client.

```mermaid
flowchart LR
  subgraph Desktop["Desktop"]
    DesktopApps["AI tools and normal apps"] --> DesktopRouter["mihomo policy router"]
  end

  subgraph Mobile["Mobile"]
    MobileApps["Mobile apps"] --> MobileRouter["rule-based proxy app"]
  end

  DesktopRouter -- AI provider suffixes --> Relay["Hysteria2 relay"]
  MobileRouter -- same AI provider suffixes --> Relay
  DesktopRouter -- private/corporate/domestic rules --> Direct["DIRECT"]
  MobileRouter -- private/corporate/domestic rules --> Direct
```

Mobile clients should import an equivalent Mihomo/Clash-style profile and keep the same rule order:

1. Loopback, private IP ranges, and redacted corporate/internal suffixes go `DIRECT`.
2. AI provider suffixes go to the stable AI route.
3. Domestic/direct suffixes and CN GeoIP go `DIRECT`.
4. General overseas or unmatched traffic follows the selected proxy group.

See [mobile-clients.md](mobile-clients.md) and [../policy/routing-demo.yaml](../policy/routing-demo.yaml) for a copyable starting point.

## Why a Relay Exists

The relay keeps the client-to-relay path encrypted and gives the project one central place to:

- Forward Claude domains to stable egress.
- Let general overseas traffic use relay direct egress.
- Rotate stable egress providers without changing client policy.
- Add server-side health checks and fallback later.
