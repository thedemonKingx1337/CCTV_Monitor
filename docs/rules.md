# Gating Rules & Code Modification Guidelines

This document details the strict rules and constraints any developer or agent must follow when editing the codebase.

---

## 1. Quality Guardrails
- **Zero Syntax Warnings**: Always ensure the Flutter frontend has zero compilation errors or warnings. Run `flutter analyze` before shipping.
- **Documentation Integrity**: Do not remove, override, or corrupt comments in code files. Maintain up-to-date documentation links.

---

## 2. Python Backend Constraints
- **Polygon Modification Verification**: If you modify zone polygons or coordinates inside `backend/data/store_layout.json`, you **must** immediately run `python assertions.py`. Detections logic checks must remain 100% correct.
- **WebSocket Frame Bounds**: Keep base64-encoded frame images properly packed within JSON messages. Do not bloat packet frames with excessive structural tags.

---

## 3. Flutter MVC + Riverpod Rules
- **No Views State Leakage**: Dashboard views must *never* maintain private mutable states for Server-sent telemetry or metrics data. All state bindings must leverage Riverpod's `StateNotifierProvider` or `AsyncNotifierProvider` bindings.
- **Responsive Fluid Layouts**: Glassmorphic styling and transparent container layers must adapt fluidly to changes in desktop or viewport dimensions. Do not use absolute widths or pixel overrides.
