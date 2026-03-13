# Soft Suave — ML Concepts Questions (AIML Engineer)

> **Sources:** GeeksforGeeks ML interview questions (fetched), general AIML interview patterns (training knowledge)  
> **Soft Suave-specific data:** Not available (Glassdoor, AmbitionBox returned 404)  
> **Last Updated:** 12 March 2026

---

## How to Use This File

- Questions are organized by topic area matching the JD's mandatory skills
- **GenAI section is the largest** — this is the primary differentiator for this role
- For each question: expected depth, follow-ups, and prep tips are included
- Priority: 🔴 High (will be tested) | 🟡 Medium (likely tested) | 🟢 Low (edge case)

---

## 1. Generative AI & LLMs (🔴 Highest Priority)

> JD Mandatory: "Generative AI (LLM, MCP, LangChain, LangGraph, Agentic AI)" — Expect 50%+ of technical questions here.

### LangChain

1. **"What is LangChain and why would you use it instead of calling LLM APIs directly?"**
   - **Expected Depth:** Architecture (chains, agents, memory, tools), abstraction benefits, when NOT to use it
   - **Follow-ups:** "What are the drawbacks?", "When would you use raw API calls instead?"
   - **Source:** Training knowledge
   - **Priority:** 🔴

2. **"Explain the difference between a Chain and an Agent in LangChain."**
   - **Expected Depth:** Chains = deterministic pipeline, Agents = LLM decides which tools to use and in what order
   - **Follow-ups:** "When would you choose one over the other?", "What's ReAct?"
   - **Source:** Training knowledge
   - **Priority:** 🔴

3. **"How does memory work in LangChain? What types of memory are available?"**
   - **Expected Depth:** ConversationBufferMemory, ConversationSummaryMemory, ConversationBufferWindowMemory, VectorStoreMemory
   - **Follow-ups:** "How would you handle memory for long conversations?", "Token limits?"
   - **Source:** Training knowledge
   - **Priority:** 🟡

4. **"What are Output Parsers in LangChain and why are they important?"**
   - **Expected Depth:** Structured output from LLMs, PydanticOutputParser, JSON parser, retry parser
   - **Follow-ups:** "How do you handle parsing failures?"
   - **Source:** Training knowledge
   - **Priority:** 🟡

### LangGraph

5. **"What is LangGraph and how is it different from LangChain?"**
   - **Expected Depth:** Graph-based workflows, stateful agents, conditional edges, cycles, checkpointing vs LangChain's linear chain model
   - **Follow-ups:** "When would you use LangGraph over LangChain?", "Draw a simple graph"
   - **Source:** Training knowledge
   - **Priority:** 🔴

6. **"Explain the concept of state in LangGraph. How is it managed?"**
   - **Expected Depth:** TypedDict state, annotation reducers, state channels, checkpointing for persistence
   - **Follow-ups:** "How do you handle state across multiple agents?", "What about error recovery?"
   - **Source:** Training knowledge
   - **Priority:** 🔴

7. **"How do conditional edges work in LangGraph?"**
   - **Expected Depth:** Router functions, branching based on state, loop conditions, END node
   - **Follow-ups:** "How would you implement a retry loop?", "Human-in-the-loop?"
   - **Source:** Training knowledge
   - **Priority:** 🟡

### RAG (Retrieval-Augmented Generation)

8. **"Explain RAG architecture end-to-end."**
   - **Expected Depth:** Document loading → chunking → embedding → vector store → retrieval → reranking → LLM generation → evaluation
   - **Follow-ups:** "What chunking strategies exist?", "How do you evaluate RAG quality?"
   - **Source:** Training knowledge
   - **Priority:** 🔴

9. **"What chunking strategies would you use for different document types?"**
   - **Expected Depth:** Fixed-size, recursive character, semantic chunking, document-aware (markdown headers, HTML), overlap strategies
   - **Follow-ups:** "How does chunk size affect retrieval quality?", "What about tables in documents?"
   - **Source:** Training knowledge
   - **Priority:** 🔴

10. **"How would you evaluate a RAG system's quality?"**
    - **Expected Depth:** RAGAS metrics (faithfulness, answer relevancy, context precision, context recall), human evaluation, A/B testing
    - **Follow-ups:** "How do you detect hallucinations?", "What if retrieval is good but generation is bad?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

11. **"What embedding models would you choose and why?"**
    - **Expected Depth:** OpenAI embeddings, Sentence Transformers, domain-specific fine-tuning, dimensionality trade-offs, multilingual embeddings
    - **Follow-ups:** "How do you handle embedding drift?", "When to fine-tune vs use off-the-shelf?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

12. **"Explain vector databases. Which ones have you used and how do they differ?"**
    - **Expected Depth:** FAISS, Pinecone, Weaviate, Chroma, PGVector, Qdrant — indexing strategies (HNSW, IVF), metadata filtering, hybrid search
    - **Follow-ups:** "When would you use FAISS vs a managed vector DB?", "How does HNSW work?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

### Agentic AI

13. **"What is an AI Agent? How does it differ from a chatbot?"**
    - **Expected Depth:** Agent = LLM + tools + planning + memory; autonomous decision-making vs scripted responses; ReAct pattern
    - **Follow-ups:** "What planning strategies exist?", "How do you prevent infinite loops?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

14. **"Explain the ReAct (Reasoning + Acting) pattern."**
    - **Expected Depth:** Thought → Action → Observation loop, LLM reasons about which tool to use, executes, observes result, repeats
    - **Follow-ups:** "What are failure modes?", "How does it compare to Plan-and-Execute?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

15. **"How would you build a multi-agent system?"**
    - **Expected Depth:** Agent specialization, supervisor pattern, peer-to-peer, shared state, handoff strategies, CrewAI/AutoGen patterns
    - **Follow-ups:** "How do agents communicate?", "How do you handle conflicting agent outputs?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

16. **"What are tool-use patterns in AI agents?"**
    - **Expected Depth:** Function calling, tool schemas/descriptions, tool selection, error handling, tool composition
    - **Follow-ups:** "How do you write good tool descriptions?", "What if the LLM calls the wrong tool?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

### MCP (Model Context Protocol)

17. **"What is MCP (Model Context Protocol) and why does it matter?"**
    - **Expected Depth:** Open standard for LLM-tool interaction, client-server architecture, standardizes how LLMs connect to data/tools, Anthropic-originated
    - **Follow-ups:** "How does MCP differ from function calling?", "What problems does it solve?"
    - **Source:** Training knowledge
    - **Priority:** 🔴 (Mandatory skill in JD, biggest gap)

18. **"Explain MCP's architecture — server, client, and transport."**
    - **Expected Depth:** MCP Server exposes tools/resources/prompts, MCP Client connects to servers, transport layer (stdio, SSE), JSON-RPC protocol
    - **Follow-ups:** "How would you build an MCP server?", "What's the tool definition schema?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

19. **"How would you build an MCP server that connects to a database?"**
    - **Expected Depth:** Define tool schemas for query/insert/update, handle authentication, input validation (prevent SQL injection), error responses
    - **Follow-ups:** "Security considerations?", "How do you test MCP servers?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

### LLM Fundamentals

20. **"Explain the Transformer architecture."**
    - **Expected Depth:** Self-attention, multi-head attention, positional encoding, encoder-decoder, feed-forward layers, layer normalization
    - **Follow-ups:** "Why is attention O(n²)?", "What's the difference between encoder-only and decoder-only?"
    - **Source:** Training knowledge
    - **Priority:** 🟡

21. **"What is prompt engineering? What techniques do you use?"**
    - **Expected Depth:** Zero-shot, few-shot, chain-of-thought, system prompts, role prompting, output formatting constraints
    - **Follow-ups:** "How do you handle prompt injection?", "How do you test prompts?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

22. **"How do you handle LLM hallucinations in production?"**
    - **Expected Depth:** RAG for grounding, guardrails, output validation, confidence scoring, human-in-the-loop, fact-checking pipelines
    - **Follow-ups:** "How do you measure hallucination rate?", "What guardrail frameworks have you used?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

23. **"Explain fine-tuning vs RAG vs prompt engineering. When would you use each?"**
    - **Expected Depth:** Cost/latency/accuracy trade-offs, RAG for dynamic knowledge, fine-tuning for style/task adaptation, prompt engineering as first approach
    - **Follow-ups:** "When is fine-tuning not worth it?", "Can you combine them?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

---

## 2. ML Algorithms & Fundamentals (🔴 High Priority)

> JD: "Develop ML models using TensorFlow, PyTorch, scikit-learn"

### Supervised Learning

24. **"Explain the bias-variance tradeoff."**
    - **Expected Depth:** Bias = underfitting, Variance = overfitting, Total Error = Bias² + Variance + Irreducible Error, how to balance
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

25. **"When would you use Random Forest vs XGBoost vs neural networks?"**
    - **Expected Depth:** Dataset size, feature types, interpretability needs, training time, overfitting risk
    - **Follow-ups:** "What about CatBoost for categorical features?"
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

26. **"Explain regularization. L1 vs L2 — when would you use each?"**
    - **Expected Depth:** L1 = sparse features / feature selection, L2 = all features matter / reduce magnitude, Elastic Net combines both
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

27. **"How does a decision tree split data? Explain entropy, information gain, and Gini index."**
    - **Expected Depth:** ID3 (entropy + IG) vs CART (Gini), how splits are chosen, pruning to prevent overfitting
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

28. **"Explain bagging vs boosting. How do Random Forest and XGBoost implement these?"**
    - **Expected Depth:** Bagging = parallel, reduces variance; Boosting = sequential, reduces bias; RF uses bagging + feature randomness; XGBoost uses gradient boosting + regularization
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

### Unsupervised Learning

29. **"Explain K-Means clustering. What are its limitations?"**
    - **Expected Depth:** Algorithm steps, K-Means++ initialization, sensitivity to outliers, assumes spherical clusters, elbow method for K
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

30. **"DBSCAN vs K-Means — when would you choose each?"**
    - **Expected Depth:** DBSCAN handles arbitrary shapes, auto-detects outliers, doesn't need K; K-Means faster, spherical clusters
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

31. **"Explain PCA. Why and when would you use it?"**
    - **Expected Depth:** Eigenvalue decomposition, variance maximization, dimensionality reduction, visualization, noise removal
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

### NLP Fundamentals

32. **"How does BERT work? What makes it different from GPT?"**
    - **Expected Depth:** Bidirectional vs autoregressive, masked language modeling vs next token prediction, encoder-only vs decoder-only, fine-tuning for classification
    - **Follow-ups:** "How did you use BERT in your ticket classifier project?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

33. **"Explain word embeddings — Word2Vec, GloVe, and contextual embeddings."**
    - **Expected Depth:** Static vs contextual, skip-gram vs CBOW, co-occurrence matrix (GloVe), why contextual (BERT/GPT) are better
    - **Source:** Training knowledge
    - **Priority:** 🟡

34. **"What is the attention mechanism and why is it important?"**
    - **Expected Depth:** Query-Key-Value, scaled dot-product attention, multi-head attention, self-attention enables capturing long-range dependencies
    - **Source:** Training knowledge
    - **Priority:** 🟡

---

## 3. Model Evaluation & Selection (🔴 High Priority)

> JD: "Evaluate and benchmark different ML models." Analysis doc flags this as a gap area needing explicit articulation.

35. **"Your model has 95% accuracy but stakeholders say it's not working. What could be wrong?"**
    - **Expected Depth:** Class imbalance, wrong metric (need precision/recall), distribution shift, edge cases, business metric vs ML metric mismatch
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

36. **"Explain precision, recall, F1 score. When would you optimize for each?"**
    - **Expected Depth:** Precision = minimize FP (spam detection), Recall = minimize FN (disease detection), F1 = balance, domain-dependent choice
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

37. **"What is AUC-ROC? How do you interpret it?"**
    - **Expected Depth:** TPR vs FPR curve, AUC = probability of ranking positive higher, 0.5 = random, 1.0 = perfect, threshold-independent
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

38. **"How do you handle class imbalance?"**
    - **Expected Depth:** Upsampling (SMOTE), downsampling, class weights, threshold tuning, evaluation metrics (F1, AUC over accuracy)
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🔴

39. **"Explain cross-validation. When would you use stratified k-fold?"**
    - **Expected Depth:** k-fold reduces variance in evaluation, stratified maintains class distribution, LOO for small datasets
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

40. **"How do you decide between underfitting and overfitting? What's your debugging process?"**
    - **Expected Depth:** Train/val gap analysis, learning curves, bias-variance diagnosis, regularization tuning, data augmentation
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

---

## 4. Feature Engineering & Data Preprocessing (🟡 Medium Priority)

41. **"What is feature engineering? Give examples from your projects."**
    - **Expected Depth:** Creating new features from raw data, domain knowledge application, examples from AIOps/NLP projects
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

42. **"How do you handle missing values in a dataset?"**
    - **Expected Depth:** Imputation (mean/median/mode, KNN imputer, prediction-based), dropping, flagging, impact on model
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

43. **"Explain the difference between normalization and standardization. When would you use each?"**
    - **Expected Depth:** Normalization = [0,1] range (Min-Max), Standardization = mean 0, std 1 (Z-score); algorithm-dependent choice
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

44. **"How do you detect and handle multicollinearity?"**
    - **Expected Depth:** Correlation matrix, VIF > 5, PCA, feature removal, regularization
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

45. **"What feature selection techniques do you use?"**
    - **Expected Depth:** Filter (correlation, chi-square), wrapper (forward/backward, RFE), embedded (Lasso, tree importance)
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

---

## 5. Deep Learning (🟡 Medium Priority)

46. **"Explain the architecture of a CNN. Where would you use it?"**
    - **Expected Depth:** Convolutional layers, pooling, activation, feature maps, image classification/object detection
    - **Source:** Training knowledge
    - **Priority:** 🟡

47. **"What is transfer learning and how have you used it?"**
    - **Expected Depth:** Pre-trained models (ResNet, BERT), freezing layers, fine-tuning, domain adaptation, saves training time
    - **Follow-ups:** "How did you fine-tune BERT for ticket classification?"
    - **Source:** Training knowledge
    - **Priority:** 🔴

48. **"Explain vanishing and exploding gradients. How do you address them?"**
    - **Expected Depth:** Deep networks lose gradient signal, solutions: ReLU, batch norm, residual connections, gradient clipping, LSTM/GRU
    - **Source:** Training knowledge
    - **Priority:** 🟡

49. **"What optimizers do you know? When would you use Adam vs SGD?"**
    - **Expected Depth:** SGD, momentum, Adam (adaptive learning rates), learning rate scheduling, Adam for most cases, SGD for better generalization
    - **Source:** Training knowledge
    - **Priority:** 🟡

50. **"Explain Batch Normalization. Why does it help?"**
    - **Expected Depth:** Normalizes layer inputs, reduces internal covariate shift, allows higher learning rates, acts as regularizer
    - **Source:** Training knowledge
    - **Priority:** 🟡

---

## 6. MLOps & Production ML (🟡 Medium Priority)

> JD: "Implement scalable ML infrastructure and productionize models."

51. **"How do you version ML models? What tools do you use?"**
    - **Expected Depth:** MLFlow (model registry, experiment tracking), DVC, model artifacts, code + data + model versioning together
    - **Source:** Training knowledge
    - **Priority:** 🟡

52. **"What is model drift? How do you detect and handle it?"**
    - **Expected Depth:** Data drift (input distribution changes), concept drift (relationship changes), monitoring with statistical tests, retraining triggers
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

53. **"Explain your CI/CD pipeline for ML models."**
    - **Expected Depth:** Code testing, data validation, model training, evaluation gates, containerization (Docker), deployment, monitoring
    - **Source:** Training knowledge
    - **Priority:** 🟡

54. **"How do you monitor ML models in production?"**
    - **Expected Depth:** Prediction quality metrics, latency, throughput, data drift monitoring, alerting, dashboards (CloudWatch, Grafana)
    - **Source:** Training knowledge
    - **Priority:** 🟡

---

## 7. Statistics & Probability (🟢 Lower Priority)

55. **"Explain Bayes' theorem with an example."**
    - **Expected Depth:** Prior, likelihood, posterior, evidence; Naive Bayes application to spam detection
    - **Source:** GeeksforGeeks (fetched)
    - **Priority:** 🟡

56. **"What is the Central Limit Theorem and why does it matter for ML?"**
    - **Expected Depth:** Sample means approach normal distribution, enables confidence intervals, hypothesis testing, guides sample size decisions
    - **Source:** Training knowledge
    - **Priority:** 🟢

57. **"Explain A/B testing. How would you use it for model comparison?"**
    - **Expected Depth:** Hypothesis, control/treatment, statistical significance, sample size, p-value, online model evaluation
    - **Source:** Training knowledge
    - **Priority:** 🟡

---

## Prep Priority Summary

| Section | Questions | Priority | Study Time |
|---|---|---|---|
| GenAI & LLMs (LangChain, LangGraph, RAG, Agents, MCP) | 23 | 🔴 P0 | 3-4 hours/week |
| ML Algorithms & Fundamentals | 11 | 🔴 P0 | 2-3 hours/week |
| Model Evaluation & Selection | 6 | 🔴 P0 | 1-2 hours/week |
| Feature Engineering & Preprocessing | 5 | 🟡 P1 | 1 hour/week |
| Deep Learning | 5 | 🟡 P1 | 1 hour/week |
| MLOps & Production ML | 4 | 🟡 P1 | 1 hour/week |
| Statistics & Probability | 3 | 🟢 P2 | As needed |
