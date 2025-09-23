# Changelog

## Unreleased
- Migrated all family data providers to Firestore realtime streams with encrypted payloads and Hive cache.
- Added AES-256-GCM encryption service with secure key storage and Firebase initialization wrapper.
- Implemented encrypted conversations and messages with optimistic updates and offline queue replay.
- Introduced legacy Hive migration helper to push historical data to Firestore.
- Updated Android build configuration to Java 17, AGP 8.5.2, Gradle 8.7, and install location metadata.
- Added Firestore security rules for encrypted family collections.
