---
name: hld-solution
description: "Generates a complete High-Level Design (HLD) / System Design solution for interview prep. Covers 17 sections: requirements, estimation, API design, data model, architecture, caching, queues, sharding, replication, monitoring, trade-offs, failure scenarios. Use when solving an HLD problem for backend or full-stack roles."
argument-hint: "Company name and HLD problem (e.g., PayPal Design a URL Shortener)"
---

# HLD Solution Skill

## Purpose

Generate a comprehensive, interview-ready High-Level Design (HLD) / System Design solution. The solution follows a strict 17-section format optimized for Staff Engineer interview prep.

## When to Use

- User wants to solve an HLD / system design problem
- User says "design [system] for [company] prep"
- User invokes `/hld-solution`

## Output

Create the solution file at: `Companies/<CompanyName>/HLD/HLD-<ProblemName>.md`
Use kebab-case for the filename (e.g., `HLD-URL-Shortener.md`, `HLD-Payment-Gateway.md`).

## Solution Format

Follow the **exact structure** from the [sample HLD solution](./examples/sample-hld.md). Every solution MUST cover all the following sections in order:

### 1. Functional Requirements
- What the system does — clear, numbered list
- Prioritize: P0 (must-have) vs P1 (nice-to-have)

### 2. Non-Functional Requirements
- Latency expectations
- Availability target (e.g., 99.99%)
- Consistency model (strong vs eventual)
- Durability guarantees
- Scale expectations (users, requests, data volume)

### 3. Back-of-Envelope Estimation
- Traffic estimation (DAU, QPS, peak QPS)
- Storage estimation (per record size × volume × retention)
- Bandwidth estimation
- Cache memory estimation
- Show all math clearly

### 4. API Design
- REST or gRPC endpoints
- For each endpoint: method, path, request body, response body, status codes
- Authentication/authorization approach
- Rate limiting considerations

### 5. Data Model
- Entity-relationship diagram (text-based)
- Table schemas with columns, types, indexes
- SQL vs NoSQL — justify the choice for each entity
- Read/write patterns that influenced the schema

### 6. High-Level Architecture
- All major components and how they connect
- Describe as a structured text diagram showing data flow
- Include: clients, load balancers, API servers, databases, caches, queues, workers, etc.

### 7. Database Choice
- SQL vs NoSQL for each data store — with justification
- Specific technology recommendations (PostgreSQL, Cassandra, Redis, etc.)
- Why this technology over alternatives

### 8. Caching Strategy
- What to cache (hot data, computed results, session data)
- Cache placement (client-side, CDN, application-level, database-level)
- Eviction policy (LRU, LFU, TTL) — justify choice
- Cache invalidation strategy (write-through, write-behind, cache-aside)
- Cache stampede / thundering herd — how to handle

### 9. Message Queues / Async Processing
- What operations should be async and why
- Technology choice (Kafka, RabbitMQ, SQS) — justify
- Consumer groups, ordering guarantees, retry/DLQ strategy
- Skip this section if the system doesn't need async processing

### 10. Data Partitioning / Sharding
- Partitioning strategy (hash-based, range-based, geographic)
- Partition key selection — why this key
- Hot partition problem — how to handle
- Rebalancing strategy
- Skip this section if data volume doesn't warrant sharding

### 11. Replication & Consistency
- Read replicas — how many, placement
- Leader-follower vs multi-leader vs leaderless
- Consistency level (quorum reads/writes)
- Conflict resolution for eventual consistency
- CAP theorem trade-off for this system

### 12. Load Balancing
- Strategy (round-robin, least connections, consistent hashing, weighted)
- L4 vs L7 load balancing — justify choice
- Health checks and failover

### 13. CDN / Blob Storage
- For media, static assets, or large files
- CDN placement and invalidation
- Blob storage choice (S3, GCS, Azure Blob)
- Skip this section if not applicable

### 14. Monitoring & Alerting
- Key metrics to track (latency p50/p95/p99, error rate, throughput, saturation)
- Logging strategy (structured logs, correlation IDs)
- Alerting thresholds
- Dashboards — what to visualize

### 15. Trade-offs
- CAP theorem positioning for this system
- Consistency vs availability — what did we choose and why
- Latency vs throughput trade-offs
- Cost vs performance decisions
- Simplicity vs scalability

### 16. Bottlenecks & Scaling
- Single points of failure — identify and mitigate
- Horizontal vs vertical scaling for each component
- Auto-scaling triggers and strategies
- What breaks at 10x, 100x current scale

### 17. Failure Scenarios
- What happens when each component fails (database down, cache miss storm, queue backlog)
- Circuit breaker patterns
- Graceful degradation strategies
- Disaster recovery and data backup

## Rules

- Check the company's analysis doc for the role's **primary language and stack** — tailor technology choices accordingly
- Explain **why** for every technology choice — don't just name-drop
- Keep the solution at the **target level** from the analysis doc — show appropriate depth and trade-off thinking
- If the problem is ambiguous, state your assumptions clearly at the top
- Reference real-world systems where relevant (e.g., "similar to how Twitter handles fan-out")
