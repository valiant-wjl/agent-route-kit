# Mobile Clients

AgentRouteKit's mobile story is policy reuse, not mobile automation. The desktop scripts install and operate mihomo on macOS. A phone or tablet should import an equivalent Mihomo/Clash-style profile into a compatible app and keep the same routing rules.

## Required Shape

A mobile client needs to support:

- The relay protocol used by your rendered profile, such as Hysteria2.
- Rule-based routing with domain suffix, CIDR, GeoIP, and optional rule-provider support.
- Import from a local file, URL, subscription, or the app's profile editor.

The policy order should stay consistent with desktop:

1. Loopback, private IP ranges, and corporate/internal suffixes go `DIRECT`.
2. AI provider suffixes go to the stable AI route.
3. Domestic/direct suffixes and CN GeoIP go `DIRECT`.
4. General overseas or unmatched traffic follows the selected proxy group.

## Client Options

| Platform | Option | When it fits | Link |
|---|---|---|---|
| iOS/iPadOS | Shadowrocket, often called 小火箭 | You want a paid App Store rule-based client with file/rule import support | [App Store](https://apps.apple.com/us/app/shadowrocket/id932747118) |
| iOS/iPadOS | Stash | You want a Clash-style rule client on Apple platforms | [Stash](https://stash.ws/) |
| Android | FlClash | You want an open-source Mihomo/ClashMeta-style client | [GitHub](https://github.com/chen08209/FlClash) |
| Any supported platform | Hysteria 2 third-party app list | You need to verify current Hysteria2 client support before choosing an app | [Hysteria 2 docs](https://v2.hysteria.network/docs/getting-started/3rd-party-apps/) |

For iOS purchases, use the official App Store path for your region. Avoid shared Apple IDs, cracked builds, enterprise-signed packages, and random repackaged downloads; they create account, privacy, and update risks that this project does not control.

## Import Flow

1. Render or prepare a profile that contains the same proxy groups as the desktop profile.
2. Copy the reusable rule order from [../policy/routing-demo.yaml](../policy/routing-demo.yaml).
3. Replace placeholder suffixes such as `corp.example` and `internal.example` with your private list only in your local/private profile.
4. Replace demo group names such as `ai-route` and `MODE` with group names that exist in your mobile profile.
5. Import the profile into the mobile app, then test one URL from each class: internal/direct, domestic/direct, AI/stable route, and general overseas.

If a client does not support MRS rule providers, use the client's supported rule-provider format instead. The same rule order still applies.

## Public Rule Sources

Use maintained public rule sets for broad domain categories, then put sensitive domains in your private policy file:

- Mihomo rules: <https://wiki.metacubex.one/en/config/rules/>
- Mihomo rule providers: <https://wiki.metacubex.one/en/config/rule-providers/>
- MetaCubeX MRS rule sets: <https://github.com/MetaCubeX/meta-rules-dat>
- Loyalsoldier Clash rules: <https://github.com/Loyalsoldier/clash-rules>
- blackmatrix7 iOS rule collections: <https://github.com/blackmatrix7/ios_rule_script>

Do not publish real corporate domains, private DNS suffixes, proxy credentials, relay hostnames, or generated profiles with secrets.
