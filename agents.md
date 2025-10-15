FamilyApp Agents Overview (Updated Oct 2025)

FamilyApp is designed using a modular agent‑based architecture. Each major feature of the application is encapsulated in its own agent. Agents expose data to the UI via [providers], store data locally in Hive for offline support, synchronise with Firebase Cloud Firestore for sharing across devices and family members, and use an encryption service to protect personal data. Below is an up‑to‑date overview of each agent and its responsibilities, including the features and packages used in the current version of the Flutter app. This document updates and expands upon the earlier agents.md file.

Common design principles

Provider pattern – Each agent exposes its state and operations via provider classes. Widgets consume the providers to reactively update the UI when data changes.

Offline‑first with Hive – Every agent maintains a local Hive box for fast, offline access. Changes are synced to Firestore when connectivity is available. A conflict‑resolution strategy ensures that local edits eventually reach the cloud.

Firestore & Firebase – Agents use Firestore collections (one per family) to share data across devices. Other Firebase services (Storage, Messaging, Authentication, Analytics, Crashlytics, Remote Config) are integrated as needed
github.com
.

Encryption – Personal data (chat messages, media metadata, profile details) are encrypted using the encrypt package and AES‑256‑GCM. Secret keys are stored securely via flutter_secure_storage; key exchange for chats is handled through a dedicated provider.

Modular and extensible – New agents can be added without affecting existing ones. The architecture favours dependency injection and clear interfaces.

Agents
DataAgent – family data, tasks and events

Purpose. Responsible for storing and synchronising core data: family members, tasks, events and calendar entries. It provides CRUD operations, ensures offline availability, and syncs with Firestore.
Implementation & features:

Maintains Hive boxes for FamilyMember, Task and Event. Each box is encrypted using the encryption service.

Provides providers (FamilyMembersProvider, TaskProvider, etc.) that expose reactive lists of models. These providers load data from local storage and listen to Firestore snapshots for changes.

Supports adding, editing, deleting and filtering tasks/events. Events can include reminders and are integrated into the ScheduleAgent.

New tasks or family members are created locally first and then written to Firestore when connectivity resumes
github.com
.

ChatAgent – chat and calls

Purpose. Handles real‑time messaging and audio/video calling between family members. It ensures secure end‑to‑end encryption, manages message statuses and storage, and integrates push notifications.

Implementation & features:

Messaging: Messages are represented by a ChatMessage model; they are encrypted with AES‑256‑GCM and stored in Hive. The chat provider synchronises with a Firestore subcollection for each conversation. Message statuses (sent/delivered/read) are updated based on Firestore metadata
github.com
.

Encryption: Each conversation has a symmetric key stored in flutter_secure_storage. Keys are exchanged via Firestore using asymmetric encryption during the first handshake.

Media & attachments: Supports sending images and files; uses image_picker, file_picker and mime packages. Files larger than a threshold are uploaded to Firebase Storage and referenced in messages.

Audio/video calls: Integrates flutter_webrtc and video_player to support audio/video calls and playback. Signalling is done through Firestore and WebRTC data channels.

Push notifications: Uses firebase_messaging to send and receive chat notifications. Notifications include message previews and open the correct chat when tapped.

Security: All chat traffic is encrypted; keys are rotated periodically. Optionally supports disappearing messages or message revocation.

ScheduleAgent – calendar and reminders

Purpose. Maintains a family calendar and personal to‑do lists. It manages event scheduling, provides reminders and integrates with the device calendar (planned).

Implementation & features:

Calendar management: Uses the models from DataAgent to build a unified calendar view. Events include start time, end time, location and participants.

Reminders: Schedules local notifications via flutter_local_notifications (pending integration) or uses the NotificationAgent (see below).

Filtering & views: Provides day/week/month views, search and filtering by category or participant.

Integration: Synchronises events with Firestore for multi‑device consistency; optional export/import from the device calendar is planned.

Offline mode: Keeps the local calendar in Hive; changes are synced when online. Event clashes or conflicts are highlighted in the UI
github.com
.

LocationAgent – geolocation and smart reminders

Purpose. Tracks device location (with user permission), enables geofenced reminders and helps families coordinate meet‑ups.

Implementation & features:

Uses the geolocator package to obtain foreground and background location updates
github.com
. A PermissionHandler ensures that location permission is requested gracefully and respects user privacy.

Provides a LocationProvider that exposes current coordinates, speed, and geofence events.

Smart reminders: Allows users to set location‑based reminders (e.g., “remind me to buy milk when near the store”). When the device enters a geofence, a local notification is triggered via NotificationAgent
github.com
.

Family map: Shares current locations with family members (with consent) and displays them on a map (using google_maps_flutter, planned).

Privacy: Locations are encrypted before being stored; sharing can be toggled on/off per user.

GalleryAgent – photos and media

Purpose. Manages family photo and video albums, including uploading, sharing and organising media. Ensures privacy via encryption and access controls.

Implementation & features:

Uses image_picker and video_player to capture and view photos/videos; file_picker for other files.

Uploads media to Firebase Storage; stores encrypted metadata (title, description, album, creation date) in Firestore. Downloads are cached locally for fast preview and offline access.

Supports albums with access control (private/public/friends). Album rights are enforced client‑side and server‑side.

Provides features like favourite marking, comments, and multi‑select deletion.

Future work: integrate AI tagging for automatic organisation.

FriendsAgent – social connections

Purpose. Handles friend requests and relationships between different families using FamilyApp. Allows sharing of events, photos and tasks with friends.

Implementation & features:

Represents a friend as a remote family with a unique identifier. Friends are stored in Firestore and cached locally.

Provides invitation workflows (send request, accept/decline, block) and notifies both parties via NotificationAgent and firebase_messaging.

Controls access rights to shared albums, events or tasks. For example, friends can be invited to events or granted view rights to specific photo albums.

Implements status updates: pending/accepted/rejected/blocked.

Plans integration with contact lists for easier discovery.

AIAgent – smart suggestions and recommendations

Purpose. Offers personalised suggestions such as gift ideas, greetings, trip recommendations and task prioritisation. Uses family profiles, past events, tasks and preferences.

Implementation & features:

Retrieves anonymised data about family members (birthdays, favourite activities) from DataAgent.

Uses cloud AI (via remote HTTP endpoints or future on‑device ML) to generate suggestions. Personalisation parameters are adjustable through settings.

Suggests gift ideas near birthdays, auto‑generates congratulatory messages, and recommends tasks based on priority and schedule.

Plans integration with Firebase Remote Config to update suggestion algorithms without app updates
github.com
.

NotificationAgent – system and push notifications (planned)

Purpose. Centralises local and push notifications for the app. It will unify notifications from chat, calendar, location and other agents.

Implementation & proposed features:

Uses firebase_messaging for push notifications and flutter_local_notifications for local alerts.

Provides a unified notification handler: groups notifications by type, schedules reminders, handles notification taps.

Supports rich notifications (images, actions) and respects quiet hours configured in settings.

Will maintain a log of delivered notifications and allow users to mark them as read or dismissed.

PaymentAgent – in‑app purchases and subscriptions (planned)

Purpose. Handles payments for premium features (e.g., extended storage, AI subscription).
Implementation & proposed features:

Integrate with Google Play Billing / Apple In‑App Purchases.

Manage subscription status, display paywall screens and handle purchase restoration.

Securely process payments and store receipts; coordinate with the server for entitlement checks.

Not yet implemented; design is subject to regulatory compliance.

BackupAgent – backups and recovery (planned)

Purpose. Provides periodic backups of local Hive data and media to external storage (e.g., Google Drive) and allows recovery on a new device.

Implementation & proposed features:

Scheduled background tasks to export encrypted Hive boxes and media to a user‑selected cloud provider.

Secure key management to ensure backup data remains confidential.

Recovery workflow to restore family data on a new device after login.

Future support for cross‑platform backup formats (Android/iOS/Desktop).

Conclusion

The FamilyApp continues to evolve as an ecosystem of self‑contained agents. The current implementation includes DataAgent, ChatAgent, ScheduleAgent, LocationAgent, GalleryAgent, FriendsAgent and AIAgent, while NotificationAgent, PaymentAgent and BackupAgent are planned. By leveraging Flutter, Firebase and modern packages (e.g., flutter_webrtc, geolocator, encrypt, file_picker)
github.com
, the app provides rich family collaboration features with offline support and privacy. This document should be kept up‑to‑date as new agents are implemented and existing ones gain features.
