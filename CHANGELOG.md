# Changelog

## 0.2.0-alpha.2

- Extracted options UI into dedicated `AuraBars_Options.lua`
- Added custom texture picker with 15 visible rows and stable mouse wheel scrolling
- Added minimap button to open the options panel
- Fixed `Settings.OpenToCategory` usage for modern Settings API compatibility

## 0.2.0-alpha.1

- Refactor into 3 modules (`Config`, `Appearance`, `Behavior`)
- Independent Buff and Debuff frames with separate movement
- Bar texture options
- Right-click buff cancellation
- Visual highlight for Private Auras with configurable border
- Private Aura border color and thickness options
- Hardening against Secret/Taint-related errors
- VS Code deploy script and task to copy automatically to AddOns
