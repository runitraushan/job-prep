# Soft Suave — ML System Design Questions (AIML Engineer)

> **Sources:** General AIML interview patterns (training knowledge), analysis doc design topics  
> **Soft Suave-specific data:** Not available (Glassdoor, AmbitionBox returned 404)  
> **Last Updated:** 12 March 2026

---

## How to Use This File

- Questions map to the analysis doc's design topics (Section 6)
- Focus areas: RAG systems, ML pipelines, model serving, agentic systems, cloud architecture
- For each question: what to cover, expected depth, and key design decisions
- **Primary cloud:** AWS (matches resume)
- These are open-ended design questions — practice explaining your architecture in 30-45 min

---

## 1. Design a RAG (Retrieval-Augmented Generation) System

> **Why Likely:** Mandatory GenAI skill; directly matches chatbot project on resume. Highest probability question.

- **Type:** ML System Design — GenAI
- **Difficulty:** 🔴 High Priority
- **Source:** Training knowledge (standard GenAI system design question)

### What to Cover:
1. **Requirements:** What documents? How many? Update frequency? Latency requirements?
2. **Document Ingestion Pipeline:** Loading (PDF, HTML, Markdown), parsing, metadata extraction
3. **Chunking Strategy:** Fixed-size vs semantic vs recursive; chunk size vs retrieval quality trade-off; overlap
4. **Embedding:** Model selection (OpenAI, Sentence Transformers), dimensionality, fine-tuning for domain
5. **Vector Store:** FAISS (local), PGVector (PostgreSQL), Pinecone (managed) — choice depends on scale
6. **Retrieval:** Top-K similarity search, hybrid search (keyword + semantic), metadata filtering
7. **Reranking:** Cross-encoder reranker to improve precision of retrieved chunks
8. **Generation:** LLM selection, prompt template with context injection, system prompt for behavior
9. **Evaluation:** RAGAS metrics (faithfulness, relevancy, context precision), human evaluation loop
10. **Production Concerns:** Caching frequent queries, cost optimization, fallback strategies, monitoring

### Key Design Decisions to Discuss:
- Chunk size (256 vs 512 vs 1024 tokens) — how it affects recall vs precision
- When to use hybrid search vs pure vector search
- How to handle multi-turn conversations with RAG (memory + retrieval)
- Cost optimization: embedding cache, LLM response cache, tiered retrieval

---

## 2. Design an ML Pipeline for Anomaly Detection

> **Why Likely:** Matches AIOps experience (Isolation Forest, DBSCAN, PCA at Wabtec). Practical system design.

- **Type:** ML System Design — Classical ML
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge (matches resume projects)

### What to Cover:
1. **Data Ingestion:** Streaming (Kafka, Kinesis) vs batch (S3, Glue), data validation
2. **Feature Engineering:** Time-series features (rolling stats, lag features), dimensionality reduction (PCA)
3. **Model Selection:** Isolation Forest (no labels), DBSCAN (density-based), Autoencoders (deep learning)
4. **Training Pipeline:** Experiment tracking (MLFlow), hyperparameter tuning, cross-validation
5. **Inference Mode:** Online (real-time alerts) vs batch (daily reports) — different architectures
6. **Alerting & Thresholds:** Anomaly score thresholds, alert fatigue prevention, severity levels
7. **Feedback Loop:** Human labels for false positives, retraining schedule, model versioning
8. **Monitoring:** Model drift detection, data quality monitoring, performance dashboards

### Key Design Decisions:
- Supervised vs unsupervised anomaly detection (and when you have no labels)
- Real-time (Lambda/Kinesis) vs batch (Glue/EMR) processing trade-offs
- How to handle seasonal patterns in anomaly detection
- Alert fatigue: how to reduce false positive rate without missing true anomalies

---

## 3. Design a Model Serving Infrastructure

> **Why Likely:** JD says "scalable ML infrastructure and productionize models." Core ML engineering skill.

- **Type:** ML System Design — Infrastructure
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge

### What to Cover:
1. **Model Registry:** MLFlow model registry, versioning, staging/production promotion
2. **Serving Layer:** FastAPI (custom), TFServing (TensorFlow), TorchServe (PyTorch), SageMaker endpoints
3. **Containerization:** Docker, ECR, ECS/EKS for orchestration
4. **Scaling:** Horizontal scaling (multiple replicas), auto-scaling based on request volume, GPU vs CPU inference
5. **A/B Testing:** Traffic splitting (10/90), shadow mode, canary deployments
6. **Caching:** Feature caching, prediction caching for repeated inputs, Redis/ElastiCache
7. **Monitoring:** Prediction latency (p50, p95, p99), throughput, error rates, model quality metrics
8. **Rollback Strategy:** Automatic rollback on quality degradation, model versioning enables quick rollback

### Key Design Decisions:
- When to use serverless (Lambda) vs always-on (ECS) for inference
- Batch prediction (pre-compute) vs online prediction (real-time API)
- GPU inference optimization: batching requests, model quantization, TensorRT
- Cost optimization strategies for model serving at scale

---

## 4. Design an Agentic AI System

> **Why Likely:** Mandatory skill (Agentic AI in JD). Newer but critical topic for this role.

- **Type:** ML System Design — GenAI
- **Difficulty:** 🔴 High Priority
- **Source:** Training knowledge

### What to Cover:
1. **Agent Architecture:** Single agent vs multi-agent, supervisor pattern, peer-to-peer
2. **Planning Strategy:** ReAct (reason + act), Plan-and-Execute, Tree-of-Thought
3. **Tool Registry:** Tool definitions (name, description, parameters), tool discovery, MCP integration
4. **Memory:** Short-term (conversation), long-term (vector store), working memory (scratchpad)
5. **Execution Engine:** LangGraph for stateful workflows, conditional routing, parallel tool execution
6. **Error Handling:** Tool failures, LLM refusal, infinite loops, timeout management, fallback strategies
7. **Guardrails:** Input/output validation, content filtering, cost limits, rate limiting
8. **Evaluation:** Task completion rate, tool usage accuracy, latency, cost per task

### Key Design Decisions:
- Single powerful agent vs specialized multi-agent system (trade-offs)
- How to prevent infinite loops in autonomous agents
- Human-in-the-loop: when to ask for approval vs act autonomously
- MCP vs function calling: when to use standardized protocol vs native integration

---

## 5. Design a Document Intelligence Pipeline

> **Why Likely:** Matches OCR + NLP project on resume. Common in IT consulting (multiple client domains).

- **Type:** ML System Design — NLP
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge (matches resume project)

### What to Cover:
1. **Document Intake:** Multi-format support (PDF, images, scanned docs, Word), S3 storage
2. **Image Preprocessing:** Deskewing, denoising, binarization, resolution normalization
3. **OCR Engine:** Tesseract (open-source), AWS Textract (managed), Google Vision — choice based on accuracy/cost
4. **Post-Processing NLP:** Named Entity Recognition, text classification, key-value extraction, table extraction
5. **Structured Output:** JSON schema for extracted data, confidence scores per field
6. **Translation:** Multi-language support, language detection, machine translation pipeline
7. **Quality Pipeline:** Confidence thresholds, human review queue for low-confidence extractions
8. **Storage & Search:** Elasticsearch for full-text search, structured DB for extracted entities

### Key Design Decisions:
- OCR accuracy vs cost (Tesseract free but less accurate vs Textract paid but better)
- How to handle poor quality scans (preprocessing pipeline)
- Table extraction strategies (different from paragraph text)
- Human-in-the-loop for low-confidence extractions

---

## 6. Design a Feature Store

> **Why Likely:** Data pipeline experience on resume; ML infrastructure focus in JD.

- **Type:** ML System Design — Infrastructure
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge

### What to Cover:
1. **Online vs Offline Store:** Online (Redis, DynamoDB) for real-time; Offline (S3, Parquet) for training
2. **Feature Registry:** Metadata (owner, description, schema, freshness), discovery, reusability
3. **Computation:** Batch features (Spark, Glue) vs streaming features (Flink, Kinesis)
4. **Point-in-Time Correctness:** Prevent data leakage, timestamp-based feature retrieval for training
5. **Serving:** Low-latency lookup by entity ID, batch retrieval for training datasets
6. **Monitoring:** Feature freshness, schema drift, missing values, distribution changes

### Key Design Decisions:
- Build vs buy (Feast open-source vs SageMaker Feature Store vs custom)
- How to ensure training-serving consistency (same features at training and inference)
- Feature freshness requirements for different features
- Cost of maintaining real-time features vs batch-computed features

---

## 7. Design an ML-Powered Ticket Triaging System

> **Why Likely:** Directly matches BERT-based ticket classifier project. They'll likely ask about this system.

- **Type:** ML System Design — NLP + Classification
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge (matches resume project)

### What to Cover:
1. **Data Pipeline:** Ticket ingestion, text preprocessing, label management
2. **Model:** BERT fine-tuned for multi-class classification, tokenization, class imbalance handling
3. **Training:** Transfer learning from pre-trained BERT, hyperparameter tuning, evaluation
4. **Serving:** FastAPI endpoint, model loading, request batching, response time requirements
5. **Feedback Loop:** Track prediction accuracy, misclassification pattern analysis, periodic retraining
6. **Escalation:** Confidence threshold for auto-assignment vs human review
7. **Monitoring:** Prediction distribution shift, new categories appearing, accuracy degradation

### Key Design Decisions:
- BERT vs lighter models (DistilBERT, TF-IDF + LogReg) — accuracy vs latency trade-off
- How to handle new ticket categories not seen during training
- Confidence threshold tuning for automated routing
- A/B testing: ML routing vs manual routing — measuring impact on resolution time

---

## 8. Design an LLM Application with Cost Optimization

> **Why Likely:** Production GenAI at consulting firms = cost matters. Tests practical architectural thinking.

- **Type:** ML System Design — GenAI
- **Difficulty:** 🟡 Medium Priority
- **Source:** Training knowledge

### What to Cover:
1. **Model Tiering:** Route simple queries to cheaper/smaller models, complex to GPT-4/Claude
2. **Caching:** Semantic caching (similar queries → cached response), exact match cache
3. **Prompt Optimization:** Shorter prompts, prompt compression, structured output to reduce tokens
4. **Batching:** Group requests for batch API (cheaper), async processing for non-urgent requests
5. **Guardrails:** Token limits, request rate limiting, cost alerts, usage dashboards
6. **Evaluation:** Cost per query, quality metrics, latency SLAs, ROI measurement

### Key Design Decisions:
- When to use open-source models (Llama, Mistral) vs commercial APIs
- Semantic caching implementation (embedding similarity threshold)
- Cost-quality trade-off framework for choosing model tier
- How to measure if the LLM application is providing business value

---

## Prep Strategy

| Question | Priority | Prep Time | Connection to Resume |
|---|---|---|---|
| 1. RAG System | 🔴 P0 | 3 hours | RAG chatbot (AWS Bedrock + PGVector) |
| 4. Agentic AI System | 🔴 P0 | 3 hours | LangChain + LangGraph on resume |
| 2. Anomaly Detection Pipeline | 🟡 P1 | 2 hours | AIOps analytics project (Wabtec) |
| 3. Model Serving Infrastructure | 🟡 P1 | 2 hours | FastAPI + Docker deployment |
| 7. Ticket Triaging System | 🟡 P1 | 2 hours | BERT classifier project |
| 5. Document Intelligence | 🟡 P1 | 1.5 hours | OCR + NLP pipeline project |
| 8. LLM Cost Optimization | 🟡 P1 | 1.5 hours | Production GenAI experience |
| 6. Feature Store | 🟢 P2 | 1 hour | Data pipeline experience |

**Approach for each question:**
1. Clarify requirements (2 min)
2. High-level architecture diagram (5 min)
3. Deep dive into each component (20 min)
4. Trade-offs and alternatives (5 min)
5. Monitoring and production concerns (5 min)
6. Q&A readiness
