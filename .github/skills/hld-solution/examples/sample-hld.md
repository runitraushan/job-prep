# HLD — Design a Notification Service

> **Company:** PayPal  
> **Level:** Staff Software Engineer — Backend  
> **Difficulty:** Medium-High  
> **Time Budget:** 45 minutes  

---

## Assumptions

- PayPal-scale: ~430M active accounts, ~25B transactions/year
- Multi-channel: Email, SMS, Push Notification, In-App
- Notifications are triggered by system events (transaction complete, fraud alert, marketing) — not user-initiated
- Global user base across multiple timezones
- Compliance requirements: users must be able to opt-out per channel, certain notifications are legally mandatory (e.g., fraud alerts, regulatory)
- We own the orchestration layer — actual delivery is delegated to external providers (SendGrid/SES for email, Twilio for SMS, FCM/APNs for push)

---

## 1. Functional Requirements

### P0 — Must Have
1. **Send notifications** via email, SMS, push, and in-app channels
2. **Event-driven triggering** — system events (payment success, fraud alert, refund processed) trigger notifications automatically
3. **User preference management** — users opt-in/out per channel and per notification type
4. **Template management** — notifications use pre-defined, parameterized templates (not hardcoded strings)
5. **Delivery tracking** — track whether a notification was sent, delivered, opened, or failed
6. **Rate limiting** — prevent spamming users (e.g., max 5 SMS/hour per user)
7. **Retry on failure** — retry failed deliveries with exponential backoff
8. **Deduplication** — ensure the same notification isn't sent twice for the same event

### P1 — Nice to Have
9. **Scheduling** — send at a preferred time (e.g., respect user's timezone, batch digest)
10. **Priority levels** — fraud alerts send immediately; marketing can be batched
11. **Multi-language support** — templates rendered in user's preferred language
12. **A/B testing** — test different templates for engagement metrics

---

## 2. Non-Functional Requirements

| Attribute | Target | Rationale |
|---|---|---|
| **Latency** | P0 (fraud alerts): < 5s end-to-end; P1 (marketing): < 30min | Fraud alerts are time-critical; marketing can be batched |
| **Availability** | 99.95% | Notification is critical but not payment-critical; brief outages are tolerable with retry |
| **Consistency** | Eventual | It's acceptable if a notification arrives a few seconds late; what's NOT acceptable is duplication or loss |
| **Durability** | No notification loss for P0 events | Fraud alerts and transaction receipts must be delivered; marketing loss is tolerable |
| **Scale** | 1B+ notifications/day at peak | PayPal processes ~70K transactions/minute; each can generate 1-3 notifications |

---

## 3. Back-of-Envelope Estimation

### Traffic
- **DAU:** ~200M users (of 430M total accounts)
- **Transactions/day:** ~70M (25B/year ÷ 365)
- **Notifications per transaction:** ~2 (sender + receiver confirmations)
- **Event-driven notifications/day:** 70M × 2 = **140M transactional**
- **Marketing/promotional/day:** ~50M (batch, lower priority)
- **Total notifications/day:** ~**200M** (can spike to **1B during peak events** like Black Friday)

### QPS
- **Average QPS:** 200M / 86,400 ≈ **2,300 notifications/sec**
- **Peak QPS (5x):** ~**12,000 notifications/sec**

### Storage
- **Notification record:** ~500 bytes (event_id, user_id, channel, template_id, status, timestamps, metadata)
- **Daily storage:** 200M × 500B = **100 GB/day**
- **Retention:** 90 days → **9 TB active storage**
- **Template storage:** ~10K templates × 5KB = **50 MB** (negligible)

### Bandwidth
- **Ingress (events):** 12K events/sec × 1KB avg = **12 MB/s** peak
- **Egress (to providers):** 12K notifications/sec × 2KB (rendered) = **24 MB/s** peak

### Cache
- **User preferences:** 200M users × 200B = **40 GB** (fits in Redis cluster)
- **Templates:** 50 MB → fully cacheable in-memory
- **Rate limit counters:** 200M × 50B = **10 GB** (Redis)

---

## 4. API Design

### Internal APIs (event ingestion — service-to-service)

```
POST /api/v1/notifications/events
```
- **Auth:** mTLS + service API key (internal services only)
- **Request Body:**
```json
{
  "event_type": "PAYMENT_COMPLETED",
  "event_id": "evt_abc123",
  "idempotency_key": "idem_xyz789",
  "priority": "HIGH",
  "recipients": [
    {
      "user_id": "usr_001",
      "role": "SENDER"
    },
    {
      "user_id": "usr_002",
      "role": "RECEIVER"
    }
  ],
  "payload": {
    "amount": 150.00,
    "currency": "USD",
    "transaction_id": "txn_456"
  },
  "timestamp": "2026-03-09T10:30:00Z"
}
```
- **Response:** `202 Accepted` (async processing)
```json
{
  "notification_batch_id": "batch_789",
  "status": "QUEUED"
}
```

### User-Facing APIs

```
GET /api/v1/users/{userId}/notifications?page=1&size=20&read=false
```
- **Auth:** OAuth 2.0 Bearer token
- **Response:** Paginated list of in-app notifications

```
PUT /api/v1/users/{userId}/preferences
```
- **Request Body:**
```json
{
  "channels": {
    "email": true,
    "sms": false,
    "push": true,
    "in_app": true
  },
  "quiet_hours": {
    "enabled": true,
    "start": "22:00",
    "end": "08:00",
    "timezone": "America/Los_Angeles"
  }
}
```
- **Response:** `200 OK`

### Rate Limiting
- Event ingestion: 10K RPM per service (internal)
- User-facing: 100 RPM per user (standard)
- Notifications to user: max 5 SMS/hour, 20 push/hour, 50 email/day per user

---

## 5. Data Model

### Entity-Relationship (Text)

```
Event (1) ──→ (N) NotificationTask (1) ──→ (1) DeliveryAttempt(s)
                     │
                     ├──→ User
                     ├──→ Template
                     └──→ Channel

User (1) ──→ (1) UserPreference
User (1) ──→ (N) DeviceToken (for push)
```

### Table Schemas

#### `notification_events` (Write-heavy, append-only)
| Column | Type | Notes |
|---|---|---|
| event_id | UUID (PK) | Idempotency — dedup key |
| event_type | VARCHAR(50) | PAYMENT_COMPLETED, FRAUD_ALERT, etc. |
| source_service | VARCHAR(50) | Which service emitted |
| payload | JSONB | Event-specific data |
| priority | ENUM | HIGH, MEDIUM, LOW |
| created_at | TIMESTAMP | Indexed for time-range queries |

**Choice: Cassandra (NoSQL)**  
- Write-heavy, append-only, time-series nature
- No complex joins needed
- Partition key: `event_type + date`, clustering key: `created_at DESC`

#### `notification_tasks` (Core work table)
| Column | Type | Notes |
|---|---|---|
| task_id | UUID (PK) | |
| event_id | UUID (FK) | Source event |
| user_id | UUID | Recipient |
| channel | ENUM | EMAIL, SMS, PUSH, IN_APP |
| template_id | VARCHAR(50) | Which template to render |
| status | ENUM | PENDING, SENT, DELIVERED, FAILED, SKIPPED |
| rendered_content | TEXT | After template rendering |
| scheduled_at | TIMESTAMP | For delayed/quiet-hours delivery |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |
| retry_count | INT | Default 0 |
| idempotency_key | VARCHAR(100) | event_id + user_id + channel |

**Choice: PostgreSQL**  
- Status transitions need ACID (PENDING → SENT → DELIVERED)
- Need indexes on (user_id, status) for in-app notification queries
- Need indexes on (status, scheduled_at) for worker polling
- Moderate write volume after fan-out (each task is one record)

#### `user_preferences`
| Column | Type | Notes |
|---|---|---|
| user_id | UUID (PK) | |
| email_enabled | BOOLEAN | Default true |
| sms_enabled | BOOLEAN | Default true |
| push_enabled | BOOLEAN | Default true |
| in_app_enabled | BOOLEAN | Default true (always on for mandatory) |
| quiet_hours_start | TIME | |
| quiet_hours_end | TIME | |
| timezone | VARCHAR(50) | |
| language | VARCHAR(10) | e.g., "en", "es" |
| updated_at | TIMESTAMP | |

**Choice: PostgreSQL** — small dataset, read-heavy, cacheable in Redis

#### `templates`
| Column | Type | Notes |
|---|---|---|
| template_id | VARCHAR(50) PK | e.g., "payment_received_email" |
| channel | ENUM | EMAIL, SMS, PUSH, IN_APP |
| language | VARCHAR(10) | |
| subject | TEXT | For email |
| body | TEXT | Mustache/Handlebars template |
| version | INT | Template versioning |
| active | BOOLEAN | |

**Choice: PostgreSQL** — tiny dataset, fully cached in memory

---

## 6. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        EVENT PRODUCERS                              │
│  Payment Service │ Fraud Service │ Account Service │ Marketing Svc  │
└────────┬────────────────┬──────────────────┬──────────────┬─────────┘
         │                │                  │              │
         ▼                ▼                  ▼              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     EVENT BUS (Kafka)                                │
│   Topics: payment.events │ fraud.events │ account.events │ ...      │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  NOTIFICATION SERVICE (Core)                         │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐    │
│  │ Event        │──▶│ Router /     │──▶│ Template Renderer    │    │
│  │ Consumer     │   │ Preference   │   │ (Mustache)           │    │
│  │              │   │ Filter       │   │                      │    │
│  └──────────────┘   └──────┬───────┘   └──────────┬───────────┘    │
│                            │                      │                 │
│                   ┌────────▼────────┐    ┌────────▼────────┐       │
│                   │ Redis           │    │ Dedup &         │       │
│                   │ (Preferences +  │    │ Rate Limiter    │       │
│                   │  Rate Limits)   │    │ (Redis)         │       │
│                   └─────────────────┘    └────────┬────────┘       │
│                                                   │                 │
└───────────────────────────────────────────────────┼─────────────────┘
                                                    │
                                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│               CHANNEL DISPATCH QUEUES (Kafka)                       │
│   email.send │ sms.send │ push.send │ in_app.send                  │
└───┬──────────────┬──────────────┬─────────────────┬─────────────────┘
    │              │              │                  │
    ▼              ▼              ▼                  ▼
┌────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐
│ Email  │  │ SMS      │  │ Push     │  │ In-App Writer    │
│ Worker │  │ Worker   │  │ Worker   │  │ (DB + WebSocket) │
│        │  │          │  │          │  │                  │
│SendGrid│  │ Twilio   │  │FCM/APNs │  │ PostgreSQL +     │
│  /SES  │  │          │  │          │  │ WebSocket GW     │
└───┬────┘  └────┬─────┘  └────┬─────┘  └───────┬──────────┘
    │            │              │                 │
    ▼            ▼              ▼                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│               DELIVERY STATUS (Webhooks / Callbacks)                │
│   Provider callbacks ──▶ Status Updater ──▶ notification_tasks DB   │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow (Happy Path — Payment Notification)

1. **Payment Service** publishes `PAYMENT_COMPLETED` event to Kafka `payment.events` topic
2. **Event Consumer** picks up the event, validates schema, writes to `notification_events` table
3. **Router** resolves recipients (sender + receiver), fetches preferences from Redis cache
4. **Preference Filter** checks: Is email enabled for this user? Is it quiet hours? → produces one `notification_task` per eligible (user, channel) pair
5. **Dedup check** — uses `idempotency_key = event_id + user_id + channel` in Redis SET to reject duplicates
6. **Rate Limiter** — checks Redis counter (sliding window). If breached, schedules for later
7. **Template Renderer** — fetches template from cache, renders with event payload data
8. **Channel Dispatch** — publishes rendered task to the appropriate channel queue (`email.send`, `sms.send`, etc.)
9. **Channel Worker** — picks task, calls external provider (SendGrid, Twilio, FCM), updates task status to `SENT`
10. **Provider Callback** — SendGrid/Twilio sends delivery webhook → Status Updater marks as `DELIVERED` or `FAILED`
11. If `FAILED` — Retry Worker picks it up (exponential backoff, max 3 retries → then DLQ)

---

## 7. Database Choice

| Data Store | Technology | Justification |
|---|---|---|
| **Event log** | Apache Cassandra | Write-heavy, append-only, time-series. No joins needed. Scales horizontally. Partition by `(event_type, date)` |
| **Notification tasks** | PostgreSQL | Status transitions need ACID. Need index-based queries for in-app notifications (`user_id + status`). Moderate volume after fan-out |
| **User preferences** | PostgreSQL + Redis cache | Small dataset (430M rows), read-heavy (checked on every notification). Cache-aside with Redis for sub-ms lookups |
| **Templates** | PostgreSQL + in-memory cache | Tiny dataset (~10K rows). Fully loaded in JVM heap. Refreshed on update via cache invalidation event |
| **Rate limit counters** | Redis | Sliding window counters. Atomic operations via Lua scripts. TTL-based auto-expiry |
| **Dedup set** | Redis | SET with TTL (24h). Key = idempotency_key. O(1) lookup |

### Why Not a Unified NoSQL Store?

The notification task table has transactional status updates (PENDING → SENT → DELIVERED) and indexed queries for the in-app notification feed. PostgreSQL handles this well. Cassandra would make status updates and secondary index queries painful.

### Why Cassandra for Events?

Events are immutable, append-only, and queried by time range for debugging/analytics. This is Cassandra's sweet spot — writes at any scale with time-bucketed partitions.

---

## 8. Caching Strategy

### What to Cache

| Data | Cache Layer | TTL | Size |
|---|---|---|---|
| User preferences | Redis (cache-aside) | 5 min | 40 GB cluster |
| Templates | JVM heap (Caffeine) | Until invalidation event | ~50 MB |
| Rate limit counters | Redis | Sliding window (1h) | 10 GB |
| Dedup keys | Redis | 24 hours | Varies |
| Recent in-app notifications | Redis (sorted set per user) | 1 hour | Hot users only |

### Eviction Policy

- **Preferences:** TTL-based (5 min) + event-driven invalidation on preference update
- **Templates:** Event-driven only (publish `template.updated` Kafka event → all instances reload)
- **Rate limits:** Sliding window with automatic TTL expiry

### Cache Invalidation Strategy

- **Preferences:** Cache-aside pattern. On read miss → fetch from DB → populate Redis. On write → update DB → delete Redis key (next read repopulates). This avoids stale-write issues.
- **Templates:** Write-through with Kafka broadcast. Admin updates template → DB write → publish `template.updated` → all service instances flush local cache and reload.

### Cache Stampede Prevention

- **Preferences:** Use Redis `SETNX` with short lock TTL for "single-flight" loading. Only one thread fetches from DB; others wait on the cache key.
- **Templates:** Not a concern — only ~10K entries, reloaded in bulk on invalidation.

---

## 9. Message Queues / Async Processing

### Why Async is Essential

Notification delivery is inherently async. The event producer (Payment Service) should NOT wait for email/SMS to be sent. Benefits:
- **Decouples producers from delivery** — Payment Service doesn't know or care about notification channels
- **Absorbs traffic spikes** — Black Friday spike gets buffered in Kafka, processed at worker capacity
- **Enables independent scaling** — Scale email workers independently from SMS workers
- **Retry isolation** — A failing SMS provider doesn't affect email delivery

### Technology: Apache Kafka

**Why Kafka over RabbitMQ/SQS:**
- **Ordering guarantees** — Kafka partitions maintain order per key. Important: notifications for the same user should be ordered (don't send "refund processed" before "refund initiated")
- **Replay capability** — Can replay events for debugging or backfill
- **High throughput** — 12K+ messages/sec is comfortable for Kafka
- **Consumer groups** — Multiple workers in a group for parallel processing with automatic rebalancing
- **Durability** — Replication factor 3, messages persisted to disk

### Topic Design

| Topic | Partition Key | Consumers | Purpose |
|---|---|---|---|
| `notification.events` | `event_id` | Notification Service | Raw events from producers |
| `email.send` | `user_id` | Email Workers | Rendered emails ready to send |
| `sms.send` | `user_id` | SMS Workers | Rendered SMS ready to send |
| `push.send` | `user_id` | Push Workers | Rendered push notifications |
| `in_app.send` | `user_id` | In-App Workers | Rendered in-app notifications |
| `notification.status` | `task_id` | Status Updater | Delivery callbacks from providers |
| `notification.dlq` | — | DLQ Processor | Failed after max retries |

**Partition key = `user_id`** on channel topics ensures all notifications for a user go to the same partition → ordered delivery.

### Retry / DLQ Strategy

```
Attempt 1 → fail → wait 1s → Attempt 2 → fail → wait 5s → Attempt 3 → fail → DLQ
```

- Max 3 retries with exponential backoff (1s, 5s, 25s)
- On DLQ: alert ops team, store for manual inspection
- Separate retry topic per channel (e.g., `email.retry`) to not block the main queue

---

## 10. Data Partitioning / Sharding

### notification_events (Cassandra)

- **Partition key:** `(event_type, date_bucket)` — e.g., `(PAYMENT_COMPLETED, 2026-03-09)`
- **Clustering key:** `created_at DESC, event_id`
- **Why:** Evenly distributes writes across nodes. Date-bucketing prevents unbounded partition growth. Queries are always scoped by event_type + date range.
- **Retention:** TTL = 90 days. Cassandra handles auto-compaction.

### notification_tasks (PostgreSQL)

- **Sharding strategy:** Range-based by `created_at` (monthly partitions using PostgreSQL declarative partitioning)
- **Why range over hash:** Queries are time-scoped ("show me recent notifications for user X"). Monthly partitions allow dropping old data efficiently.
- **Index:** `(user_id, created_at DESC)` for in-app notification feed
- **Partition pruning:** Queries with date range hit only relevant partitions

### Hot Partition Handling

- **Cassandra:** High-traffic event types (e.g., `PAYMENT_COMPLETED`) are spread across multiple date buckets. If a single day gets too hot, add a random salt bucket (0-9) to the partition key.
- **PostgreSQL:** In-app feed queries for power users → add Redis sorted set as a cache layer for the 100 most recent notifications per user.

### Rebalancing

- **Cassandra:** Automatic with virtual nodes (vnodes). Adding a new node triggers automatic data streaming.
- **PostgreSQL:** Monthly partitions. No rebalancing needed — new month = new partition. Old partitions archived or dropped.

---

## 11. Replication & Consistency

### Event Store (Cassandra)

- **Replication factor:** 3 (across 3 racks / availability zones)
- **Write consistency:** `LOCAL_QUORUM` (2 of 3 replicas acknowledge)
- **Read consistency:** `LOCAL_ONE` for event browsing (speed over strong consistency)
- **Why:** Events are immutable. Once written with quorum, there's no conflict. Reading with ONE is fine since stale reads on immutable data are impossible.

### Task DB (PostgreSQL)

- **Primary + 2 read replicas**
- **Writes:** Go to primary only
- **Reads:** In-app notification feed → read replica (slight lag acceptable). Status queries for delivery tracking → primary
- **Replication:** Synchronous to one replica (zero data loss), async to second (for read scaling)
- **Failover:** Patroni or AWS RDS Multi-AZ for automatic primary failover

### Redis

- **Cluster mode:** 6 nodes (3 primary + 3 replicas) across AZs
- **Replication:** Async (Redis default). Slight data loss acceptable for rate-limit counters and preferences cache.
- **On failover:** Sentinel-based promotion. Brief window where rate limits may reset — acceptable (sends a few extra notifications, not a catastrophe)

### CAP Positioning

This system chooses **AP (Availability + Partition-tolerance)** over strong consistency:
- A delayed or slightly duplicate notification is far better than a lost notification or system downtime
- Dedup layer provides "effectively once" semantics even with eventual consistency

---

## 12. Load Balancing

### API Gateway (User-Facing)

- **L7 Load Balancer** (AWS ALB or Envoy)
- **Strategy:** Least connections — user-facing API traffic varies; some requests are quick (fetch notifications) while others are heavier (update preferences)
- **Why L7:** Need path-based routing (`/notifications/*` → notification service, `/preferences/*` → preference service), SSL termination, and request-level health checks

### Internal Services (Notification Workers)

- **Kafka consumer groups** handle load balancing naturally — each partition assigned to one consumer in the group. No external LB needed.
- **If using HTTP between services:** gRPC with client-side load balancing (round-robin across service instances via service discovery)

### Health Checks

- **Liveness:** `/health/live` — JVM is up and responding
- **Readiness:** `/health/ready` — Kafka consumer is connected, Redis is reachable, DB connections are healthy
- **Interval:** 10s, unhealthy threshold: 3 consecutive failures → remove from pool

---

## 13. CDN / Blob Storage

### Applicability

Limited applicability — notifications are mostly text. However:

- **Email templates with images:** Static assets (logos, banners) stored in **S3** and served via **CloudFront CDN**
  - TTL: 24 hours
  - Invalidation: On template asset update, publish CloudFront invalidation
- **Rich push notification images:** Thumbnails stored in S3, URL embedded in push payload. FCM/APNs fetch the image from CloudFront.
- **Attachment-based notifications** (e.g., monthly statement PDF): Generated by a separate service, stored in S3 with pre-signed URLs (24h expiry). Link embedded in email.

---

## 14. Monitoring & Alerting

### Key Metrics

| Metric | Source | Alert Threshold |
|---|---|---|
| **Notification throughput** (sent/sec per channel) | Kafka consumer lag + custom metric | < 50% of expected baseline |
| **End-to-end latency** (event → delivered) | Custom timer metric | P99 > 30s for HIGH priority |
| **Delivery success rate** per channel | Provider callbacks | < 95% over 5 min window |
| **Kafka consumer lag** per topic | Kafka metrics | > 100K messages |
| **DLQ size** | Kafka DLQ topic | > 0 (any message in DLQ → alert) |
| **Rate limit hit rate** | Redis counter | Spike > 2x normal → possible abuse |
| **Template rendering errors** | Application logs | > 0.1% |
| **Redis cache hit rate** | Redis INFO stats | < 90% → cache warming issue |

### Logging Strategy

- **Structured JSON logs** with fields: `event_id`, `task_id`, `user_id`, `channel`, `status`, `duration_ms`
- **Correlation ID:** Every notification carries a `trace_id` from the originating event through all stages → enables end-to-end tracing
- **PII masking:** User email, phone number masked in logs (`r***@gmail.com`)
- **Log aggregation:** ELK stack or Datadog Logs

### Dashboards

1. **Operations dashboard:** Throughput per channel, consumer lag, error rate, DLQ depth
2. **User experience dashboard:** Delivery latency distribution, bounce rate, unsubscribe rate
3. **Provider health dashboard:** Per-provider success rate, latency, error codes

---

## 15. Trade-offs

### 1. Availability > Consistency (AP)

**Chose:** Eventual consistency with dedup  
**Trade-off:** A user might receive a notification ~seconds late during a partition event, or in rare edge cases, get a duplicate. But the system stays up and keeps delivering.  
**Why:** For PayPal, failing to notify a user about a fraud alert is far worse than sending it twice. The user can tolerate a duplicate; they can't tolerate a missed alert.

### 2. Throughput > Latency for Bulk Channels

**Chose:** Kafka-based async pipeline with batching for email/SMS  
**Trade-off:** Individual emails might take 5-10 seconds to send (queued → processed → delivered). But the system can handle 12K+ notifications/sec.  
**Why:** Notification delivery is not a real-time interactive operation. Users don't sit watching for a notification. Throughput matters more.

### 3. External Providers > In-House Delivery

**Chose:** Delegate to SendGrid, Twilio, FCM  
**Trade-off:** Vendor lock-in, cost per message, less control over deliverability  
**Why:** Building an email server with IP warming, reputation management, DKIM/SPF setup, and ISP relationships is a massive undifferentiated effort. SendGrid solves this at scale. The notification service focuses on orchestration, not delivery.

### 4. Per-Channel Queues > Single Queue

**Chose:** Separate Kafka topic per channel (email.send, sms.send, push.send)  
**Trade-off:** More infrastructure to manage (4 topics + consumer groups)  
**Why:** Channels have dramatically different throughput and failure characteristics. SMS provider outage shouldn't block email delivery. Independent scaling — email may need 20 workers while push needs 5.

### 5. Idempotency + Dedup > Exactly-Once

**Chose:** At-least-once delivery with application-level dedup  
**Trade-off:** Slightly more complexity in the dedup layer. Small window where Redis TTL could expire and allow a duplicate.  
**Why:** True exactly-once in a distributed system is extremely expensive (two-phase commit across Kafka + DB + external provider). At-least-once + dedup gives us "effectively once" at a fraction of the cost and complexity.

---

## 16. Bottlenecks & Scaling

### Single Points of Failure

| SPOF | Mitigation |
|---|---|
| **Kafka cluster** | Multi-broker (5+), rack-aware replication, MirrorMaker for cross-DC |
| **PostgreSQL primary** | Synchronous replica + Patroni auto-failover |
| **Redis** | Cluster mode (3 primary + 3 replicas), Sentinel failover |
| **External providers** | Multi-provider fallback (SendGrid primary → SES fallback for email) |
| **Notification Service itself** | Stateless — scale horizontally behind LB. Kafka consumers auto-rebalance |

### Scaling Strategy

| Component | Current | At 10x | At 100x |
|---|---|---|---|
| **Kafka** | 5 brokers, 12 partitions/topic | 10 brokers, 24 partitions | 20 brokers, 48 partitions, dedicated clusters per channel |
| **Email Workers** | 10 instances | 50 instances | 200 instances + batch API (SendGrid batch) |
| **SMS Workers** | 5 instances | 20 instances | 50 instances + multi-provider LB (Twilio + Vonage) |
| **PostgreSQL** | Primary + 2 replicas | Horizontal sharding by user_id | Migrate hot-path (in-app feed) to Cassandra, keep PG for task tracking |
| **Redis** | 6 nodes | 12 nodes | 24 nodes + local L1 cache (Caffeine) to reduce Redis load |

### Auto-Scaling Triggers

- **Workers:** Scale on Kafka consumer lag. If lag > 10K for 2 min → add 2 workers. If lag < 100 for 10 min → remove 1 worker.
- **API servers:** Scale on CPU (> 70%) or request latency (P95 > 500ms)

### What Breaks at 100x

- **PostgreSQL becomes the bottleneck** for in-app notification feed (200M users × high read rate). Mitigation: Move in-app feed to Cassandra or ScyllaDB with a dedicated read model.
- **Redis cluster memory** for rate limiting. Mitigation: Switch to approximate algorithms (HyperLogLog for dedup, approximate sliding window).
- **External provider rate limits.** Mitigation: negotiate enterprise quotas, implement multi-provider routing with weighted distribution.

---

## 17. Failure Scenarios

### Kafka Down

- **Impact:** Events queue up in producers' memory/local buffer. No new notifications processed.
- **Mitigation:** Producers use Kafka's built-in retry buffer (configurable `buffer.memory`). If Kafka is down for > 5 min, producers start writing to a local fallback queue (filesystem-backed) and replay when Kafka recovers.
- **Graceful degradation:** In-app notifications can fall back to direct DB writes (bypass Kafka for HIGH priority fraud alerts).

### PostgreSQL Down

- **Impact:** Can't write new notification tasks. Can't serve in-app notification feed.
- **Mitigation:** Auto-failover to sync replica (< 30s). During failover, Kafka consumers pause and resume automatically (consumer group rebalance).
- **In-app feed:** Serve from Redis cache (stale but available). Show "notifications may be delayed" banner.

### External Provider Down (e.g., SendGrid outage)

- **Impact:** Email delivery fails.
- **Mitigation:** Circuit breaker (Resilience4j) trips after 5 consecutive failures. Automatic failover to backup provider (SES). Messages remain in Kafka queue—nothing is lost.
- **Recovery:** When primary recovers, circuit breaker half-opens, gradually routes traffic back.

### Redis Down

- **Impact:** Preference lookups fall back to DB (slower but functional). Rate limiting disabled temporarily. Dedup not enforced.
- **Mitigation:** Acceptable temporarily. Rate limit bypass means some users might get a few extra notifications — annoying but not dangerous. Dedup bypass means potential duplicates — covered by provider-level dedup (SendGrid dedup by message-id header).
- **Recovery:** Cache repopulates on read (cache-aside pattern).

### Cache Stampede on Redis Recovery

- **Impact:** After Redis restart, all preference lookups miss cache simultaneously → DB overwhelmed.
- **Mitigation:** Staggered TTL (base TTL + random jitter 0-60s). Combined with single-flight loading (only one thread per key fetches from DB).

### Message Ordering Violation

- **Impact:** User sees "Refund processed" before "Refund initiated."
- **Mitigation:** Kafka partition key = `user_id` on channel topics guarantees per-user ordering within a partition. Single consumer per partition maintains order. If we scale consumers, use cooperative sticky assignment to minimize partition shuffling.

### Poison Message (Unparseable Event)

- **Impact:** Consumer crashes in a loop trying to process bad message.
- **Mitigation:** Dead letter on deserialization failure — skip and alert. Don't let one bad message block the partition. Use a schema registry (Avro + Confluent Schema Registry) to validate events at ingestion.

---

## Appendix: Technology Stack Summary

| Layer | Technology | Notes |
|---|---|---|
| Language/Framework | Java 21 + Spring Boot 3.x | Consistent with PayPal's stack |
| Event Bus | Apache Kafka | Ordering, replay, high throughput |
| Task DB | PostgreSQL 16 | ACID for status transitions |
| Event Log | Apache Cassandra | Write-heavy, append-only |
| Cache / Rate Limit | Redis Cluster | Sub-ms reads, Lua scripting |
| Local Cache | Caffeine | In-JVM L1 cache for templates |
| Template Engine | Mustache / Handlebars | Logic-less templates, safe for user-facing content |
| Email Provider | SendGrid (primary) / SES (fallback) | High deliverability, webhook support |
| SMS Provider | Twilio (primary) / Vonage (fallback) | Global coverage, delivery receipts |
| Push | Firebase Cloud Messaging + APNs | Android + iOS |
| Circuit Breaker | Resilience4j | Standard in Spring Boot ecosystem |
| Monitoring | Prometheus + Grafana | Metrics |
| Logging | ELK (Elasticsearch + Logstash + Kibana) | Structured logs with correlation IDs |
| Tracing | OpenTelemetry + Jaeger | End-to-end distributed tracing |
| Orchestration | Kubernetes | Auto-scaling, health checks, rolling deploys |
