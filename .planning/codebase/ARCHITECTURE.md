# Architecture

## Current State
- Monolithic `DashboardScreen` in `main.dart`.
- Simple logic layer in `RuleEngine`.
- Direct camera initialization in `FaceCamera`.

## Target Architecture (per implementation.md)
- **Core Layer**: `rule_engine.dart`, `alarm_service.dart`, `tts_service.dart`, `audio_service.dart`.
- **UI Layer**: `alarm_overlay.dart`, `dashboard.dart`.
- **Models Layer**: `drowsiness_state.dart`.
- **Providers Layer**: `drowsiness_provider.dart`.
