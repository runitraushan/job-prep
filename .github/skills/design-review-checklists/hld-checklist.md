# HLD Review Checklist

> Use this checklist to evaluate a High-Level Design document for interview readiness.

| # | Section | What a Strong Answer Includes | Red Flags If Missing |
|---|---------|-------------------------------|----------------------|
| 1 | **Functional Requirements** | Clear P0/P1 prioritization, numbered list, scope boundaries | No prioritization → interviewer thinks you can't scope |
| 2 | **Non-Functional Requirements** | Latency (p50/p95/p99), availability (99.9X%), consistency model, scale targets with actual numbers | Vague NFRs ("fast", "scalable") → shows no systems thinking |
| 3 | **Back-of-Envelope Estimation** | QPS, storage, bandwidth, cache sizing — math shown step by step | No math → can't justify architecture decisions with data |
| 4 | **API Design** | RESTful/gRPC endpoints, request/response schemas, error codes, idempotency keys, auth approach | No API → unclear interface contract between client and server |
| 5 | **Data Model** | Entity-relationship, table schemas with types + indexes, SQL vs NoSQL justification per entity, read/write patterns | No schema → hand-wavy data design won't survive follow-ups |
| 6 | **High-Level Architecture** | All major components, data flow, component diagram (text-based OK), clear separation of concerns | Missing components or unclear data flow → interviewer sees gaps |
| 7 | **Database Choice** | SQL vs NoSQL per store with specific technology + justification, why this over alternatives | Name-dropping without reasoning → "they just picked what they know" |
| 8 | **Caching Strategy** | What to cache, where (L1/L2/CDN), eviction policy, invalidation strategy, stampede prevention | No cache or naive cache → won't handle real-world traffic |
| 9 | **Message Queues / Async** | Why async, technology choice + justification, ordering guarantees, retry/DLQ, consumer groups | Synchronous-only design at scale → bottleneck under load |
| 10 | **Sharding / Partitioning** | Strategy (hash/range/geo), partition key selection + why, hot partition handling, rebalancing | Single-node DB at PayPal scale → unrealistic |
| 11 | **Replication & Consistency** | Leader-follower/multi-leader, replication factor, consistency level, conflict resolution, CAP positioning | No replication → single point of failure |
| 12 | **Load Balancing** | L4 vs L7 + why, algorithm choice, health checks, failover behavior | Missing LB → doesn't understand production traffic management |
| 13 | **Monitoring & Alerting** | Key metrics (latency percentiles, error rate, throughput), logging strategy, dashboards, alerting thresholds | No monitoring → "how would you know it's broken?" |
| 14 | **Trade-offs Discussion** | Every major decision has "chose X over Y because Z". CAP positioning, consistency vs availability, cost vs performance | No trade-offs → biggest red flag at Staff level |
| 15 | **Failure Scenarios** | Component failure handling, circuit breakers, graceful degradation, disaster recovery, cascading failure prevention | No failure modes → design works only in the happy path |

## Scoring Guidance

- **Completeness 1:** Section completely missing
- **Completeness 2:** Mentioned but no substance (one sentence, no reasoning)
- **Completeness 3:** Adequate — covers the basics, some justification
- **Completeness 4:** Good — thorough coverage, clear trade-offs, specific numbers
- **Completeness 5:** Excellent — deep expertise shown, covers edge cases, references real-world systems

## Staff-Level Expectations

At Staff Engineer level, interviewers specifically look for:
- **Trade-off thinking** in every section, not just section 14
- **Numbers and math** to back up decisions (not "we'll use a cache" but "we need 40GB cache, here's why")
- **Failure mode awareness** throughout the design, not just in section 15
- **Domain sensitivity** — if designing for PayPal, expect idempotency, PCI-DSS, reconciliation to come up
