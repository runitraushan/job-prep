# Soft Suave — ML Concepts Solutions — P1 (🟡 Medium Priority)

> **Role:** AIML Engineer | **Language:** Python | **Date:** 12 March 2026
> **Total Questions:** 34 | **Study Time:** 4-5 hours/week
> **Sections:** GenAI (9), ML Algorithms (6), Model Evaluation (3), Feature Engineering (5), Deep Learning (4), MLOps (4), Statistics (2)

---

## 1. GenAI & LLMs (Continued)

---

### Q3. How does memory work in LangChain? What types of memory are available?

**Answer:**

LLMs are stateless — each call is independent. Memory gives the illusion of continuity by injecting past conversation into the prompt.

**Memory Types:**

| Type | How It Works | Token Usage | Best For |
|---|---|---|---|
| **ConversationBufferMemory** | Stores entire conversation verbatim | Grows linearly — will hit token limit | Short conversations |
| **ConversationBufferWindowMemory** | Keeps last K exchanges | Fixed window | Chat sessions with limited context needs |
| **ConversationSummaryMemory** | LLM summarizes conversation periodically | Stays small | Long conversations |
| **ConversationSummaryBufferMemory** | Recent messages verbatim + summary of older | Balanced | Production chatbots (best trade-off) |
| **VectorStoreMemory** | Stores memories as embeddings, retrieves relevant ones | Only relevant memories | Long-term memory, many topics |
| **EntityMemory** | Tracks entities and facts about them | Structured | Knowledge-heavy conversations |

**Usage Example:**

```python
from langchain.memory import ConversationSummaryBufferMemory
from langchain_openai import ChatOpenAI

llm = ChatOpenAI()
memory = ConversationSummaryBufferMemory(
    llm=llm,
    max_token_limit=1000  # Summarize when buffer exceeds this
)

# Conversation flows naturally
memory.save_context({"input": "My name is Shubhajit"}, {"output": "Hello!"})
memory.save_context({"input": "I work on ML"}, {"output": "Great field!"})

# Memory provides context for next call
memory.load_memory_variables({})
# → {'history': 'The human introduced themselves as Shubhajit who works on ML...'}
```

**Handling long conversations:** Use `ConversationSummaryBufferMemory` — it keeps recent messages verbatim (important for context) and summarizes older messages (saves tokens). This is what I'd use for a production chatbot.

---

### Q4. What are Output Parsers in LangChain and why are they important?

**Answer:**

LLMs return free text. Output parsers enforce **structured outputs** — critical for downstream code that expects JSON, lists, or typed objects.

**Types:**

| Parser | Output Format | Reliability |
|---|---|---|
| `StrOutputParser` | Raw string | Always works |
| `JsonOutputParser` | JSON dict | Good with formatting instructions |
| `PydanticOutputParser` | Pydantic model (typed, validated) | Best — schema enforcement |
| `CommaSeparatedListOutputParser` | Python list | Simple lists |
| `OutputFixingParser` | Wraps another parser + fixes on failure | Retry layer |

**Pydantic Parser (production pattern):**

```python
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field

class TicketClassification(BaseModel):
    category: str = Field(description="Ticket category")
    priority: str = Field(description="low, medium, high, critical")
    summary: str = Field(description="One-line summary")

parser = PydanticOutputParser(pydantic_object=TicketClassification)

prompt = ChatPromptTemplate.from_messages([
    ("system", "Classify the support ticket.\n{format_instructions}"),
    ("human", "{ticket_text}")
]).partial(format_instructions=parser.get_format_instructions())

chain = prompt | llm | parser
result = chain.invoke({"ticket_text": "App keeps crashing on login page"})
# result is a TicketClassification object — typed and validated
```

**Handling failures:** Use `OutputFixingParser` which catches parsing errors and asks the LLM to fix its output:

```python
from langchain.output_parsers import OutputFixingParser

robust_parser = OutputFixingParser.from_llm(parser=parser, llm=llm)
# If first parse fails, sends error + output back to LLM for correction
```

---

### Q7. How do conditional edges work in LangGraph?

**Answer:**

Conditional edges let the graph take **different paths based on the current state** — enabling branching, loops, and dynamic routing.

```python
from langgraph.graph import StateGraph, END

def route_by_intent(state):
    """Router function — returns the name of the next node."""
    intent = state["intent"]
    if intent == "question":
        return "rag_answer"
    elif intent == "action":
        return "execute_action"
    elif intent == "unclear":
        return "clarify"
    else:
        return END

# Add conditional edges
graph.add_conditional_edges(
    "classify_intent",               # Source node
    route_by_intent,                  # Router function
    {                                 # Mapping: return value → target node
        "rag_answer": "rag_answer",
        "execute_action": "execute_action",
        "clarify": "clarify",
        END: END
    }
)
```

**Implementing a retry loop:**

```python
def should_retry(state):
    if state["retry_count"] < 3 and not state["success"]:
        return "retry"       # Loop back
    return "finalize"        # Move on

graph.add_conditional_edges("check_result", should_retry, {
    "retry": "execute_step",   # Loop back to execution
    "finalize": "finalize"
})
```

**Human-in-the-loop:**

```python
# Interrupt before a dangerous action
app = graph.compile(
    checkpointer=memory,
    interrupt_before=["execute_action"]  # Pauses here for human approval
)

# Resume after human approves
app.invoke(None, config)  # Continues from checkpoint
```

---

### Q11. What embedding models would you choose and why?

**Answer:**

| Model | Dimensions | Speed | Quality | Use Case |
|---|---|---|---|---|
| **OpenAI text-embedding-3-small** | 1536 | Fast (API) | Very good | General RAG (cost-effective) |
| **OpenAI text-embedding-3-large** | 3072 | Fast (API) | Best | High-quality retrieval |
| **sentence-transformers/all-MiniLM-L6-v2** | 384 | Very fast (local) | Good | On-premise, low latency |
| **BAAI/bge-large-en-v1.5** | 1024 | Medium (local) | Very good | Best open-source option |
| **Cohere embed-v3** | 1024 | Fast (API) | Very good | Multilingual support |
| **Domain fine-tuned** | Custom | Slow to create | Best for domain | Specialized vocabulary |

**Selection Criteria:**

1. **Privacy:** Can data leave your network? No → local model (sentence-transformers)
2. **Quality vs cost:** High-quality needed → text-embedding-3-large; cost-sensitive → small variant
3. **Multilingual:** Need multiple languages → Cohere v3 or multilingual sentence-transformers
4. **Latency:** Sub-10ms needed → local model on GPU; acceptable 50-100ms → API
5. **Domain:** Very specialized (medical, legal) → fine-tune on domain corpus

**Embedding Drift:** Over time, if your documents change significantly, old embeddings may not align well with new ones. Solutions:
- Re-embed entire corpus periodically
- Track embedding quality metrics (retrieval recall on a test set)
- Version your embedding model alongside your vector store

---

### Q12. Explain vector databases. Which ones have you used and how do they differ?

**Answer:**

Vector databases store high-dimensional embedding vectors and enable fast similarity search (nearest neighbor lookup).

| Database | Type | Hosting | Best For |
|---|---|---|---|
| **FAISS** | Library (not a DB) | Local/self-hosted | Prototyping, batch search, no metadata needs |
| **PGVector** | PostgreSQL extension | Self-hosted / RDS | Already using Postgres, need SQL + vectors |
| **Pinecone** | Managed SaaS | Cloud | Production with zero ops overhead |
| **Chroma** | Embedded / client-server | Local or server | Quick prototyping, lightweight |
| **Weaviate** | Full DB | Self-hosted / cloud | Hybrid search (vector + keyword), GraphQL |
| **Qdrant** | Full DB | Self-hosted / cloud | High performance, rich filtering |

**Search Algorithms:**

| Algorithm | Trade-off | Used By |
|---|---|---|
| **Flat (brute force)** | Exact but slow O(n) | Small datasets, gold standard |
| **IVF (Inverted File Index)** | Clusters vectors, searches nearby clusters | FAISS |
| **HNSW (Hierarchical Navigable Small World)** | Graph-based, very fast approximate | PGVector, Qdrant, Weaviate |
| **Product Quantization** | Compresses vectors, trades accuracy for memory | FAISS |

**In my project (SOP Chatbot):** I used **PGVector** because:
- Already had PostgreSQL (AWS RDS) in the stack
- Needed metadata filtering (filter by SOP category before vector search)
- Didn't want to manage another database
- HNSW index gives good performance for our corpus size (~10K chunks)

```sql
-- PGVector: Create table with embedding column
CREATE TABLE sop_chunks (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536),  -- OpenAI embedding dimensions
    metadata JSONB
);

-- HNSW index for fast similarity search
CREATE INDEX ON sop_chunks USING hnsw (embedding vector_cosine_ops);

-- Query: Find top 5 similar chunks
SELECT content, 1 - (embedding <=> query_embedding) AS similarity
FROM sop_chunks
ORDER BY embedding <=> query_embedding
LIMIT 5;
```

---

### Q15. How would you build a multi-agent system?

**Answer:**

**Patterns:**

| Pattern | How It Works | When to Use |
|---|---|---|
| **Supervisor** | One "manager" agent delegates tasks to worker agents | Clear task decomposition, need coordination |
| **Peer-to-Peer** | Agents communicate directly, each decides when to pass to another | Collaborative tasks, brainstorming |
| **Hierarchical** | Supervisor → sub-supervisors → workers | Complex, nested tasks |
| **Sequential Pipeline** | Agent 1 → Agent 2 → Agent 3 | Each agent specializes in one step |

**Supervisor Pattern (LangGraph):**

```python
from langgraph.graph import StateGraph

class MultiAgentState(TypedDict):
    messages: list
    next_agent: str
    task_status: dict

def supervisor(state):
    """Decide which agent should work next."""
    # LLM analyzes the task and delegates
    response = llm.invoke(
        f"Given the task: {state['messages'][-1]}, "
        f"which agent should handle it? Options: researcher, coder, reviewer"
    )
    return {"next_agent": response.content}

def researcher_agent(state):
    """Searches for information."""
    # Has access to search tools
    ...

def coder_agent(state):
    """Writes code solutions."""
    # Has access to code execution tools
    ...

graph = StateGraph(MultiAgentState)
graph.add_node("supervisor", supervisor)
graph.add_node("researcher", researcher_agent)
graph.add_node("coder", coder_agent)
graph.add_conditional_edges("supervisor", route_to_agent)
```

**Communication between agents:** Via shared state — each agent reads from and writes to the same state object. The supervisor reads all outputs to decide next steps.

**Handling conflicting outputs:** The supervisor or a dedicated "resolver" agent reconciles conflicts. Can also use voting (3 agents classify, majority wins).

---

### Q16. What are tool-use patterns in AI agents?

**Answer:**

Tool use lets agents **take actions** beyond text generation — query databases, call APIs, execute code.

**How It Works (Function Calling):**

```python
# 1. Define tool schema
tools = [{
    "type": "function",
    "function": {
        "name": "query_database",
        "description": "Execute a read-only SQL query against the analytics DB",
        "parameters": {
            "type": "object",
            "properties": {
                "sql": {"type": "string", "description": "SQL query to execute"}
            },
            "required": ["sql"]
        }
    }
}]

# 2. LLM decides to call a tool
response = llm.invoke(messages, tools=tools)
# → tool_call: query_database(sql="SELECT COUNT(*) FROM tickets")

# 3. Execute the tool and return result
result = execute_tool(response.tool_calls[0])

# 4. Feed result back to LLM for final answer
messages.append({"role": "tool", "content": str(result)})
final_response = llm.invoke(messages)
```

**Writing good tool descriptions:** The description is *the most important part* — the LLM uses it to decide WHEN to use the tool.

| Bad | Good |
|---|---|
| `"Query database"` | `"Execute a read-only SQL query against the analytics database. Use for fetching ticket counts, user metrics, or historical data."` |
| `"Send email"` | `"Send an email notification. Use only after the analysis is complete and the user has confirmed the report looks correct."` |

**Error handling:** Wrap tool execution in try-catch, return descriptive errors to the LLM so it can adapt:

```python
try:
    result = execute_tool(tool_call)
except Exception as e:
    result = f"Error: {str(e)}. Try a different approach."
# LLM receives the error and can retry with corrected input
```

---

### Q19. How would you build an MCP server that connects to a database?

**Answer:**

```python
from mcp.server import Server
from mcp.types import Tool, TextContent
import asyncpg  # Async PostgreSQL driver

server = Server("database-mcp-server")

# Connection pool (initialized on startup)
pool = None

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="query",
            description="Execute a read-only SQL query. Returns results as JSON.",
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {
                        "type": "string",
                        "description": "Read-only SQL query (SELECT only)"
                    }
                },
                "required": ["sql"]
            }
        ),
        Tool(
            name="list_tables",
            description="List all tables in the database with their columns.",
            inputSchema={"type": "object", "properties": {}}
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "query":
        sql = arguments["sql"].strip()
        
        # SECURITY: Only allow SELECT statements
        if not sql.upper().startswith("SELECT"):
            return [TextContent(
                type="text",
                text="Error: Only SELECT queries are allowed."
            )]
        
        # SECURITY: Block dangerous patterns
        dangerous = ["DROP", "DELETE", "INSERT", "UPDATE", "ALTER", "TRUNCATE"]
        if any(kw in sql.upper() for kw in dangerous):
            return [TextContent(
                type="text", 
                text="Error: Write operations are not permitted."
            )]
        
        async with pool.acquire() as conn:
            rows = await conn.fetch(sql)
            result = [dict(row) for row in rows]
            return [TextContent(type="text", text=json.dumps(result, default=str))]
    
    elif name == "list_tables":
        async with pool.acquire() as conn:
            tables = await conn.fetch("""
                SELECT table_name, column_name, data_type 
                FROM information_schema.columns 
                WHERE table_schema = 'public'
                ORDER BY table_name, ordinal_position
            """)
            return [TextContent(type="text", text=json.dumps([dict(t) for t in tables]))]
```

**Security best practices:**
- Read-only access (only SELECT)
- Input validation (block write keywords)
- Use parameterized queries where possible
- Connection pool with limited connections
- Rate limiting
- Audit logging for all queries

---

### Q20. Explain the Transformer architecture.

**Answer:**

The Transformer (Vaswani et al., 2017) replaced RNNs with pure **attention mechanisms**, enabling parallelization and better long-range dependency capture.

**Architecture:**

```
Input → Embedding + Positional Encoding
            ↓
   ┌─── Encoder (N layers) ───┐    ┌─── Decoder (N layers) ───┐
   │ Multi-Head Self-Attention │    │ Masked Self-Attention     │
   │ Add & LayerNorm          │    │ Add & LayerNorm           │
   │ Feed-Forward Network     │    │ Encoder-Decoder Attention │
   │ Add & LayerNorm          │    │ Add & LayerNorm           │
   └───────────────────────────┘    │ Feed-Forward Network     │
              ↓                     │ Add & LayerNorm           │
        Encoder Output ──────────► └────────────────────────────┘
                                              ↓
                                        Linear + Softmax
                                              ↓
                                        Output Tokens
```

**Self-Attention Mechanism:**

$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right) V$$

- **Q** (Query): "What am I looking for?"
- **K** (Key): "What do I contain?"
- **V** (Value): "What information do I carry?"
- $\sqrt{d_k}$: Scaling factor to prevent softmax saturation

**Multi-Head Attention:** Run attention h times in parallel (typically h=8 or 12), each head learning different relationships (syntax, semantics, position).

**Positional Encoding:** Since attention is permutation-invariant (no inherent order), positional encodings (sinusoidal or learned) are added to embeddings to preserve token order.

**Why attention is O(n²):** For sequence length n, every token attends to every other token → n×n attention matrix. This is why context windows are limited (solutions: sparse attention, sliding window, FlashAttention).

**Key variants:**
- **Encoder-only:** BERT (classification, embeddings)
- **Decoder-only:** GPT (text generation)
- **Encoder-Decoder:** T5, BART (translation, summarization)

---

## 2. ML Algorithms & Fundamentals (Continued)

---

### Q27. How does a decision tree split data? Explain entropy, information gain, and Gini index.

**Answer:**

Decision trees recursively split data at each node to maximize **purity** (each split should create more homogeneous groups).

**Splitting Criteria:**

**Entropy (Information Theory):**

$$H(S) = -\sum_{i=1}^{c} p_i \log_2(p_i)$$

- H = 0 → perfectly pure (all one class)
- H = 1 → maximum impurity (50/50 binary)

**Information Gain (ID3):**

$$IG(S, A) = H(S) - \sum_{v \in Values(A)} \frac{|S_v|}{|S|} H(S_v)$$

Choose the attribute A that maximizes IG (largest entropy reduction after split).

**Gini Index (CART):**

$$Gini(S) = 1 - \sum_{i=1}^{c} p_i^2$$

- Gini = 0 → perfectly pure
- Gini = 0.5 → maximum impurity (binary)

**Example:**

| Dataset: 10 emails | Spam(6) | Not Spam(4) |
|---|---|---|

```
Entropy = -6/10 * log2(6/10) - 4/10 * log2(4/10) = 0.97
Gini    = 1 - (6/10)² - (4/10)² = 0.48
```

Split on "contains_link":
- Yes(7): Spam=5, NotSpam=2 → Gini = 1-(5/7)²-(2/7)² = 0.41
- No(3): Spam=1, NotSpam=2 → Gini = 1-(1/3)²-(2/3)² = 0.44

Weighted Gini after split = 7/10(0.41) + 3/10(0.44) = 0.42 (lower than 0.48 → good split)

**In practice:** Gini and entropy give almost identical results. Gini is slightly faster (no log computation). Scikit-learn uses Gini by default.

**Pruning:** Without pruning, trees memorize training data (high variance). Solutions:
- **Pre-pruning:** Set max_depth, min_samples_split, min_samples_leaf
- **Post-pruning:** Build full tree, then remove branches that don't improve validation score

---

### Q28. Explain bagging vs boosting. How do Random Forest and XGBoost implement these?

**Answer:**

| Aspect | Bagging | Boosting |
|---|---|---|
| **Strategy** | Train models in **parallel** on random subsets | Train models **sequentially**, each fixing previous errors |
| **Reduces** | **Variance** (overfitting) | **Bias** (underfitting) |
| **Aggregation** | Majority vote / average | Weighted sum |
| **Overfitting risk** | Low | Higher (can overfit noise) |
| **Training speed** | Fast (parallelizable) | Slower (sequential) |

**Random Forest (Bagging):**

```
Training Data → Bootstrap Sample 1 → Tree 1 ─┐
             → Bootstrap Sample 2 → Tree 2 ──├→ Majority Vote → Prediction
             → Bootstrap Sample N → Tree N ──┘
```

Key additions beyond basic bagging:
- **Feature randomness:** Each split considers only √n_features (not all), reducing correlation between trees
- **No pruning needed:** Averaging over many deep trees cancels out individual overfitting

**XGBoost (Boosting):**

```
Training Data → Tree 1 → Residuals → Tree 2 → Residuals → Tree 3 → ...
                 ↓                      ↓                     ↓
              Weighted              Weighted              Weighted
                 └──────────── Sum of all trees ──────────────┘
```

Key additions beyond basic boosting:
- **Gradient-based:** Each tree fits the gradient of the loss function (residuals)
- **Regularization:** L1/L2 penalties on tree weights (prevents overfitting)
- **Row/column subsampling:** Like Random Forest, adds randomness
- **Early stopping:** Stop when validation error stops improving

```python
import xgboost as xgb

model = xgb.XGBClassifier(
    n_estimators=100,       # Number of trees
    learning_rate=0.1,      # Shrinkage (smaller = more trees needed but better generalization)
    max_depth=6,            # Tree depth (lower = less overfitting)
    subsample=0.8,          # Row sampling
    colsample_bytree=0.8,   # Column sampling
    reg_alpha=0.1,          # L1 regularization
    reg_lambda=1.0          # L2 regularization
)
```

---

### Q29. Explain K-Means clustering. What are its limitations?

**Answer:**

**Algorithm:**

1. Choose K random centroids
2. **Assign** each point to nearest centroid
3. **Update** centroids to mean of assigned points
4. Repeat 2-3 until convergence (centroids stop moving)

```python
from sklearn.cluster import KMeans

kmeans = KMeans(n_clusters=3, init='k-means++', random_state=42)
labels = kmeans.fit_predict(X)
```

**Limitations:**

| Limitation | Why | Solution |
|---|---|---|
| Must specify K in advance | Can't auto-detect cluster count | Elbow method, Silhouette score |
| Assumes spherical clusters | Uses distance from centroid | DBSCAN for arbitrary shapes |
| Sensitive to initialization | Different starting points → different results | K-Means++ initialization |
| Sensitive to outliers | Outliers pull centroids | Remove outliers first, or use DBSCAN |
| Scales poorly with dimensions | "Curse of dimensionality" | PCA first, then K-Means |
| Only finds convex clusters | Can't find ring/crescent shapes | DBSCAN, spectral clustering |

**Finding optimal K (Elbow method):**

```python
inertias = []
for k in range(1, 11):
    km = KMeans(n_clusters=k, random_state=42)
    km.fit(X)
    inertias.append(km.inertia_)
# Plot k vs inertia — look for "elbow" point
```

---

### Q30. DBSCAN vs K-Means — when would you choose each?

**Answer:**

| Aspect | K-Means | DBSCAN |
|---|---|---|
| **Cluster shape** | Spherical only | Arbitrary shapes |
| **Number of clusters** | Must specify K | Auto-detected |
| **Outlier handling** | No — assigns everything | Built-in noise detection |
| **Parameters** | K (number of clusters) | eps (distance), min_samples |
| **Scalability** | O(nKt) — fast | O(n²) or O(n log n) with spatial index |
| **Consistent results** | Depends on initialization | Deterministic |
| **Cluster sizes** | Tends toward equal-sized | Handles varying sizes |

**When to use K-Means:**
- You know the number of clusters
- Clusters are roughly spherical and similar-sized
- Need fast training on large data
- Example: Customer segmentation into K tiers

**When to use DBSCAN:**
- Unknown number of clusters
- Clusters have irregular shapes
- Need to detect outliers/anomalies
- Example: Anomaly detection in log data (your AIOps project!)

```python
from sklearn.cluster import DBSCAN

dbscan = DBSCAN(eps=0.5, min_samples=5)
labels = dbscan.fit_predict(X)
# label == -1 means noise/outlier
```

---

### Q31. Explain PCA. Why and when would you use it?

**Answer:**

PCA (Principal Component Analysis) transforms high-dimensional data into a lower-dimensional space by finding the **directions of maximum variance**.

**How It Works:**

1. Standardize data (mean=0, std=1)
2. Compute covariance matrix
3. Find eigenvectors (principal components) and eigenvalues
4. Sort by eigenvalue (highest variance first)
5. Project data onto top-k eigenvectors

$$\text{Variance explained} = \frac{\lambda_k}{\sum_{i=1}^n \lambda_i}$$

**When to use PCA:**

| Use Case | Why PCA Helps |
|---|---|
| Too many features (100+) | Reduces dimensionality, speeds up training |
| Multicollinearity | PCA components are orthogonal (uncorrelated) |
| Visualization | Reduce to 2-3D for plotting |
| Noise reduction | Small components often capture noise |
| Before K-Means | Reduces "curse of dimensionality" |

```python
from sklearn.decomposition import PCA

# Keep 95% of variance
pca = PCA(n_components=0.95)
X_reduced = pca.fit_transform(X)

print(f"Reduced from {X.shape[1]} to {X_reduced.shape[1]} features")
print(f"Variance explained: {sum(pca.explained_variance_ratio_):.2%}")
```

**Limitations:**
- Assumes linear relationships (use t-SNE/UMAP for non-linear)
- Loses interpretability (components are combinations of original features)
- Sensitive to scaling (always standardize first)

---

### Q33. Explain word embeddings — Word2Vec, GloVe, and contextual embeddings.

**Answer:**

| Model | Type | How It Works | Limitation |
|---|---|---|---|
| **Word2Vec (Skip-gram)** | Static | Predict surrounding words from center word | Same vector for "bank" (river vs financial) |
| **Word2Vec (CBOW)** | Static | Predict center word from surrounding words | Same limitation |
| **GloVe** | Static | Factorize global co-occurrence matrix | Same limitation |
| **BERT/GPT Embeddings** | Contextual | Different vector per context | Slower, larger |

**Static vs Contextual:**

```
"I went to the bank to deposit money"  → bank = [0.2, 0.8, 0.1]  (financial)
"I sat on the river bank"              → bank = [0.2, 0.8, 0.1]  (same! ❌)

BERT:
"I went to the bank to deposit money"  → bank = [0.9, 0.1, 0.8]  (financial)
"I sat on the river bank"              → bank = [0.1, 0.9, 0.3]  (river ✅)
```

**Word2Vec Details (Skip-gram):**
- Input: center word → predict context words within window
- Training: shallow neural network (1 hidden layer)
- Famous property: `king - man + woman ≈ queen` (vector arithmetic captures relationships)

**When to use what:**
- **Word2Vec/GloVe:** Legacy systems, very constrained compute, don't need contextual meaning
- **Sentence-transformers:** RAG embeddings, semantic search (recommended default)
- **BERT embeddings:** Classification, NER, when you need token-level contextual representations

---

### Q34. What is the attention mechanism and why is it important?

**Answer:**

Attention lets a model **dynamically focus on relevant parts** of the input when producing each output element — like a human's selective attention.

**Scaled Dot-Product Attention:**

$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right) V$$

**Step by step:**

1. **Compute similarity:** $QK^T$ — dot product of Query with all Keys (which inputs are relevant?)
2. **Scale:** Divide by $\sqrt{d_k}$ (prevents softmax from becoming too peaked for large dimensions)
3. **Normalize:** Softmax converts to probability distribution (weights sum to 1)
4. **Aggregate:** Weighted sum of Values (combine information from relevant inputs)

**Multi-Head Attention:**

Instead of one attention function, run h=8 attention heads in parallel, each learning different relationships:
- Head 1 might learn syntactic relationships (subject-verb)
- Head 2 might learn semantic similarity
- Head 3 might learn positional proximity

```python
# Pseudocode
for head_i in range(num_heads):
    Q_i = X @ W_q_i  # Project to head's query space
    K_i = X @ W_k_i
    V_i = X @ W_v_i
    head_output_i = attention(Q_i, K_i, V_i)

output = concat(all_head_outputs) @ W_o  # Combine heads
```

**Why it's important:**
- Captures **long-range dependencies** (unlike RNNs that struggle with distance)
- **Parallelizable** (unlike RNNs that process sequentially)
- **Interpretable** — attention weights show which input tokens influenced the output

---

## 3. Model Evaluation (Continued)

---

### Q37. What is AUC-ROC? How do you interpret it?

**Answer:**

**ROC Curve:** Plots True Positive Rate (Recall) vs False Positive Rate at every classification threshold.

$$TPR = \frac{TP}{TP + FN} \qquad FPR = \frac{FP}{FP + TN}$$

**AUC (Area Under the ROC Curve):** Single number summarizing the ROC curve.

| AUC Value | Interpretation |
|---|---|
| 1.0 | Perfect classifier |
| 0.9 - 1.0 | Excellent |
| 0.8 - 0.9 | Good |
| 0.7 - 0.8 | Fair |
| 0.5 | Random guessing (no discrimination) |
| < 0.5 | Worse than random (labels likely flipped) |

**Intuitive interpretation:** AUC = probability that the model ranks a randomly chosen positive example higher than a randomly chosen negative example.

```python
from sklearn.metrics import roc_auc_score, roc_curve

# AUC score
auc = roc_auc_score(y_true, y_scores)

# ROC curve data
fpr, tpr, thresholds = roc_curve(y_true, y_scores)

# Find optimal threshold (Youden's J statistic)
optimal_idx = (tpr - fpr).argmax()
optimal_threshold = thresholds[optimal_idx]
```

**When AUC-ROC is NOT ideal:** Heavily imbalanced datasets — use **Precision-Recall AUC** instead. ROC can look optimistic because TN dominates the FPR calculation.

---

### Q39. Explain cross-validation. When would you use stratified k-fold?

**Answer:**

Cross-validation estimates model performance by testing on multiple different held-out subsets.

**K-Fold:**

```
Fold 1: [TRAIN] [TRAIN] [TRAIN] [TEST ]
Fold 2: [TRAIN] [TRAIN] [TEST ] [TRAIN]
Fold 3: [TRAIN] [TEST ] [TRAIN] [TRAIN]
Fold 4: [TEST ] [TRAIN] [TRAIN] [TRAIN]

Final score = average of 4 fold scores
```

**Stratified K-Fold:** Ensures each fold has the **same class distribution** as the full dataset.

| Type | When to Use |
|---|---|
| **K-Fold** | Balanced classes, regression |
| **Stratified K-Fold** | Imbalanced classification (preserves class ratios) |
| **Group K-Fold** | Data has groups (e.g., multiple samples per patient — same patient shouldn't be in train AND test) |
| **Time Series Split** | Temporal data (train on past, test on future — no data leakage) |
| **Leave-One-Out (LOO)** | Very small datasets (<50 samples) |

```python
from sklearn.model_selection import StratifiedKFold

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
for train_idx, test_idx in skf.split(X, y):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    # Train and evaluate
```

---

### Q40. How do you decide between underfitting and overfitting? What's your debugging process?

**Answer:**

**Diagnostic Table:**

| Train Error | Val Error | Diagnosis | Action |
|---|---|---|---|
| ❌ High | ❌ High | **Underfitting** (high bias) | More complex model, more features, less regularization |
| ✅ Low | ❌ High | **Overfitting** (high variance) | More data, regularization, dropout, simpler model |
| ✅ Low | ✅ Low | **Good fit** | Ship it, monitor for drift |
| ❌ High | ✅ Low | **Bug** (impossible normally) | Check for data leakage or code error |

**Debugging Process:**

```
1. Plot learning curves (train + val error vs dataset size)
   → If both still decreasing → Get more data
   → If gap between them → Overfitting → Regularize

2. Check model complexity
   → Decision tree depth, number of features, network layers
   → Start simple, increase complexity gradually

3. Feature analysis
   → Irrelevant features? → Feature selection
   → Missing important features? → Feature engineering

4. Data quality check
   → Duplicates, leakage, labeling errors
   → Train/val distribution mismatch
```

**Learning Curve Cheatsheet:**

- **Underfitting:** Both curves plateau at high error
- **Overfitting:** Training error is low, validation error is high, large gap
- **Ideal:** Both curves converge at low error

---

## 4. Feature Engineering & Data Preprocessing

---

### Q41. What is feature engineering? Give examples from your projects.

**Answer:**

Feature engineering is creating **new input features** from raw data that help the model learn patterns more effectively. It's often the single biggest lever for model performance.

**Examples from projects:**

**AIOps (Anomaly Detection):**
- **Time-based:** Hour of day, day of week, is_business_hours (anomaly patterns differ by time)
- **Rolling statistics:** 5-min rolling mean/std of log volume (detect sudden spikes)
- **Lag features:** Error count at t-1, t-5, t-15 (temporal patterns)
- **Aggregations:** Errors per service per 5-min window

**Ticket Triaging (NLP):**
- **Text length:** Ticket body word count (longer tickets = complex issues)
- **Keyword flags:** Contains "crash", "error", "slow" (binary features)
- **TF-IDF vectors:** Term frequency - inverse document frequency on ticket text
- **BERT embeddings:** 768-dim contextual representation (replaced TF-IDF)

**General patterns:**

| Type | Examples |
|---|---|
| **Mathematical** | Log transform, polynomial features, ratios |
| **Temporal** | Hour, day_of_week, is_weekend, time_since_event |
| **Aggregation** | Group by entity → count, mean, max, std |
| **Interaction** | Feature A × Feature B (captures combined effects) |
| **Encoding** | One-hot, label encoding, target encoding |
| **Text** | TF-IDF, embeddings, character count, regex patterns |

---

### Q42. How do you handle missing values in a dataset?

**Answer:**

| Method | How | When |
|---|---|---|
| **Drop rows** | Remove rows with nulls | <5% missing, randomly distributed |
| **Drop columns** | Remove feature entirely | >50% missing, feature not important |
| **Mean/Median** | Fill with column mean/median | Numerical, assumes normal-ish distribution |
| **Mode** | Fill with most frequent value | Categorical |
| **Forward/Backward fill** | Use previous/next value | Time series data |
| **KNN Imputer** | Use K nearest neighbors to estimate | When features are correlated |
| **Iterative Imputer** | Model each feature with missing values as a function of others | Complex relationships |
| **Flag + Impute** | Add `is_missing` binary column + impute | When missingness itself is informative |

```python
from sklearn.impute import SimpleImputer, KNNImputer

# Simple
imputer = SimpleImputer(strategy='median')
X_filled = imputer.fit_transform(X)

# KNN (considers feature relationships)
knn_imputer = KNNImputer(n_neighbors=5)
X_filled = knn_imputer.fit_transform(X)

# Flag + Impute (missingness as signal)
X['feature_missing'] = X['feature'].isna().astype(int)
X['feature'].fillna(X['feature'].median(), inplace=True)
```

**Important:** Always impute separately on train and test sets (fit on train, transform on test) to prevent data leakage.

---

### Q43. Explain the difference between normalization and standardization. When would you use each?

**Answer:**

| Method | Formula | Result Range | When to Use |
|---|---|---|---|
| **Normalization (Min-Max)** | $\frac{x - x_{min}}{x_{max} - x_{min}}$ | [0, 1] | Feature values have known bounds; neural networks; image pixels |
| **Standardization (Z-score)** | $\frac{x - \mu}{\sigma}$ | Mean=0, Std=1 | Unknown distribution; SVM, logistic regression, PCA |

**Algorithm-Specific Needs:**

| Algorithm | Needs Scaling? | Preferred Method |
|---|---|---|
| Linear/Logistic Regression | ✅ Yes | Standardization |
| SVM | ✅ Yes | Standardization |
| KNN | ✅ Yes | Either (Standardization preferred) |
| Neural Networks | ✅ Yes | Normalization [0,1] or [-1,1] |
| Decision Trees / Random Forest | ❌ No | Scale-invariant |
| XGBoost | ❌ No | Scale-invariant |
| PCA | ✅ Yes | Standardization (variance-based) |

```python
from sklearn.preprocessing import StandardScaler, MinMaxScaler

# Standardization
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)  # Use train's mean/std

# Normalization
normalizer = MinMaxScaler()
X_norm = normalizer.fit_transform(X_train)
```

---

### Q44. How do you detect and handle multicollinearity?

**Answer:**

Multicollinearity = two or more features are **highly correlated**, which inflates variance of regression coefficients and makes them unreliable.

**Detection:**

```python
# 1. Correlation matrix
corr_matrix = df.corr()
high_corr = (corr_matrix.abs() > 0.8) & (corr_matrix != 1.0)

# 2. VIF (Variance Inflation Factor) — better method
from statsmodels.stats.outliers_influence import variance_inflation_factor

vif = pd.DataFrame()
vif['Feature'] = X.columns
vif['VIF'] = [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
# VIF > 5 → moderate multicollinearity
# VIF > 10 → high multicollinearity — take action
```

**Handling:**

| Method | When |
|---|---|
| **Remove one** of correlated pair | Simple, interpretable models |
| **PCA** | Reduce to uncorrelated components |
| **L1 regularization** (Lasso) | Auto-selects one from correlated group |
| **L2 regularization** (Ridge) | Keeps both but reduces impact |
| **Domain knowledge** | Choose the more meaningful feature |

---

### Q45. What feature selection techniques do you use?

**Answer:**

| Category | Technique | Speed | Quality |
|---|---|---|---|
| **Filter** | Correlation, chi-square, mutual information, ANOVA | Fast | Good |
| **Wrapper** | Forward selection, backward elimination, RFE | Slow (trains model repeatedly) | Best |
| **Embedded** | Lasso L1, tree feature importance | Medium | Good |

```python
# Filter: Mutual Information
from sklearn.feature_selection import mutual_info_classif
mi_scores = mutual_info_classif(X, y)

# Wrapper: Recursive Feature Elimination
from sklearn.feature_selection import RFE
from sklearn.ensemble import RandomForestClassifier

rfe = RFE(estimator=RandomForestClassifier(), n_features_to_select=10)
rfe.fit(X, y)
selected = X.columns[rfe.support_]

# Embedded: Tree feature importance
model = RandomForestClassifier().fit(X, y)
importances = pd.Series(model.feature_importances_, index=X.columns)
top_features = importances.nlargest(10)
```

**My approach:** Start with filter (quick), validate with embedded (tree importance or SHAP), use wrapper only if needed for final refinement.

---

## 5. Deep Learning (Continued)

---

### Q46. Explain the architecture of a CNN. Where would you use it?

**Answer:**

```
Input Image → [Conv → ReLU → Pool]×N → Flatten → [FC → ReLU]×M → Softmax → Output
```

| Layer | Purpose | Example |
|---|---|---|
| **Convolutional** | Detect local patterns (edges, textures, shapes) | 32 filters of 3×3 |
| **ReLU** | Non-linearity | max(0, x) |
| **Pooling** | Reduce spatial dimensions, add translation invariance | 2×2 max pooling |
| **Flatten** | Convert 2D feature maps to 1D vector | Before FC layers |
| **Fully Connected** | Classification/regression on extracted features | 256 → num_classes |

**Key insight:** Earlier layers learn **low-level features** (edges, corners), deeper layers learn **high-level concepts** (eyes, faces, objects). This hierarchical feature learning is what makes CNNs powerful.

**Use cases:**
- Image classification, object detection, segmentation
- OCR (your Telugu document project!)
- Medical imaging
- Video analysis

---

### Q48. Explain vanishing and exploding gradients. How do you address them?

**Answer:**

During backpropagation, gradients are multiplied across layers. In deep networks:

- **Vanishing:** Gradients become exponentially smaller → early layers stop learning
- **Exploding:** Gradients become exponentially larger → training diverges

**Why it happens with sigmoid/tanh:**
- Sigmoid derivative max is 0.25
- After 10 layers: 0.25¹⁰ ≈ 0.000001 (gradient vanishes)

**Solutions:**

| Solution | Address | How |
|---|---|---|
| **ReLU activation** | Vanishing | Gradient is 1 for positive inputs (no shrinkage) |
| **Batch Normalization** | Both | Normalizes layer inputs, stabilizes gradients |
| **Residual connections (ResNet)** | Vanishing | Skip connections: y = F(x) + x (gradient flows directly) |
| **Gradient clipping** | Exploding | Cap gradient magnitude: `clip_grad_norm_(params, max_norm=1.0)` |
| **LSTM/GRU** | Vanishing (RNNs) | Gates control information flow, maintain gradient |
| **Careful initialization** | Both | Xavier/He initialization based on layer sizes |
| **Lower learning rate** | Exploding | Reduce step size |

---

### Q49. What optimizers do you know? When would you use Adam vs SGD?

**Answer:**

| Optimizer | Mechanism | Strength |
|---|---|---|
| **SGD** | Basic gradient descent with optional momentum | Better generalization (proven in research) |
| **SGD + Momentum** | Accumulates past gradients to smooth updates | Faster convergence than vanilla SGD |
| **Adam** | Adaptive learning rates per parameter (combines momentum + RMSProp) | Fast convergence, good default |
| **AdamW** | Adam with decoupled weight decay | Better regularization than Adam |
| **RMSProp** | Adaptive LR using running average of squared gradients | Good for RNNs |

**Adam vs SGD:**

| Factor | Adam | SGD + Momentum |
|---|---|---|
| **Convergence speed** | Faster | Slower |
| **Tuning effort** | Low (default LR=1e-3 usually works) | High (LR, momentum, schedule needed) |
| **Generalization** | Slightly worse | Slightly better (sharper minima → flatter minima debate) |
| **Memory** | 2× model params (stores m and v) | 1× model params (stores momentum) |

**Rule of thumb:**
- **Adam/AdamW** for most cases — especially when you want quick results
- **SGD + Momentum + LR schedule** when you need the absolute best generalization (e.g., final competition submission, large-scale training)

```python
# Adam (default choice)
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

# SGD with momentum + cosine LR schedule (for best generalization)
optimizer = torch.optim.SGD(model.parameters(), lr=0.1, momentum=0.9)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=100)
```

---

### Q50. Explain Batch Normalization. Why does it help?

**Answer:**

Batch Normalization normalizes the output of each layer to have **zero mean and unit variance** across the current mini-batch.

$$\hat{x}_i = \frac{x_i - \mu_B}{\sqrt{\sigma_B^2 + \epsilon}}$$
$$y_i = \gamma \hat{x}_i + \beta \quad (\text{learnable scale and shift})$$

**Why it helps:**

1. **Reduces internal covariate shift** — Layer inputs stay in a stable range even as earlier layers update
2. **Allows higher learning rates** — Gradients are more predictable → can take bigger steps
3. **Acts as regularizer** — Mini-batch statistics add noise, reducing overfitting
4. **Faster convergence** — Training typically 2-3× faster

**Where to place it:**
```
Linear → BatchNorm → ReLU   (most common for FC layers)
Conv2d → BatchNorm → ReLU   (standard for CNNs)
```

**BatchNorm vs LayerNorm:**

| | BatchNorm | LayerNorm |
|---|---|---|
| Normalizes across | Batch dimension | Feature dimension |
| Depends on batch size | Yes | No |
| Works with small batches | Poorly | Well |
| Used in | CNNs | Transformers, RNNs |

---

## 6. MLOps & Production ML

---

### Q51. How do you version ML models? What tools do you use?

**Answer:**

Model versioning tracks **code + data + model artifacts** together — because a model is only reproducible if you can recreate all three.

**MLFlow (used in my projects):**

```python
import mlflow

with mlflow.start_run():
    # Log parameters
    mlflow.log_param("model_type", "random_forest")
    mlflow.log_param("n_estimators", 100)
    
    # Log metrics
    mlflow.log_metric("f1_score", 0.87)
    mlflow.log_metric("auc_roc", 0.92)
    
    # Log model artifact
    mlflow.sklearn.log_model(model, "model")
    
    # Register in Model Registry
    mlflow.register_model(
        f"runs:/{mlflow.active_run().info.run_id}/model",
        "ticket-classifier"
    )
```

**Model Registry (MLFlow):**

| Stage | Purpose |
|---|---|
| **None** | Experimental, not promoted |
| **Staging** | Passed automated tests, being validated |
| **Production** | Serving live traffic |
| **Archived** | Previous version, kept for rollback |

**What to version:**

| Component | Tool | Why |
|---|---|---|
| Code | Git | Reproduce preprocessing, training logic |
| Data | DVC, Delta Lake | Reproduce exact training dataset |
| Model artifacts | MLFlow, S3 | Weights, config, tokenizer |
| Environment | Docker, conda.yml | Python version, library versions |
| Experiment config | MLFlow params | Hyperparameters, settings |

---

### Q52. What is model drift? How do you detect and handle it?

**Answer:**

| Type | What Changes | Example |
|---|---|---|
| **Data drift** | Input feature distribution shifts | New ticket categories appear, language patterns change |
| **Concept drift** | The relationship between inputs and outputs changes | What was "high priority" last year is now "medium" |
| **Label drift** | Target variable distribution shifts | Anomaly rate increases from 2% to 8% |

**Detection Methods:**

```python
# Statistical tests for data drift
from scipy.stats import ks_2samp  # Kolmogorov-Smirnov test

for feature in features:
    stat, p_value = ks_2samp(
        training_data[feature],
        production_data[feature]
    )
    if p_value < 0.05:
        print(f"DRIFT detected in {feature}: p={p_value:.4f}")

# Monitor prediction distribution
# If predicted class distribution shifts significantly → concept drift
```

**Monitoring Dashboard:**
- Feature distribution plots (training vs production)
- Prediction confidence distribution (should be stable)
- Performance metrics on labeled samples (if available)
- Alert when KS-statistic exceeds threshold

**Handling:**
1. **Immediate:** Alert on-call team when drift exceeds threshold
2. **Short-term:** Retrain model on recent data
3. **Long-term:** Automate retraining pipeline (scheduled or triggered by drift)

---

### Q53. Explain your CI/CD pipeline for ML models.

**Answer:**

```
Code Push → Tests → Data Validation → Train → Evaluate → Deploy → Monitor
    │          │           │              │         │          │        │
   Git    Unit tests   Schema check   Training   Eval gate  Docker   Drift
          + lint      + drift check   pipeline   (F1>0.85)  + API    alerts
```

**Pipeline Stages:**

| Stage | What Happens | Tools |
|---|---|---|
| **Code Quality** | Lint, type check, unit tests | pytest, flake8, GitHub Actions |
| **Data Validation** | Schema check, stat tests, missing value check | Great Expectations, custom checks |
| **Training** | Train model on latest data (or retrain on schedule) | MLFlow, custom scripts, SageMaker |
| **Evaluation Gate** | Compare against baseline; reject if below threshold | MLFlow metrics, custom assertions |
| **Containerization** | Package model + dependencies in Docker | Docker, ECR |
| **Deployment** | Deploy to staging → canary → production | FastAPI, ECS/Lambda, blue-green |
| **Monitoring** | Track predictions, latency, drift | CloudWatch, custom dashboards |

**Evaluation gate example:**

```python
# In CI pipeline
current_f1 = evaluate_model(new_model, test_set)
baseline_f1 = mlflow.get_metric("production_f1")

if current_f1 < baseline_f1 * 0.95:  # Allow max 5% degradation
    raise Exception(f"Model rejected: F1={current_f1:.3f} < baseline={baseline_f1:.3f}")
```

---

### Q54. How do you monitor ML models in production?

**Answer:**

| What to Monitor | Why | How |
|---|---|---|
| **Prediction latency** | SLA compliance | p50, p95, p99 latency metrics |
| **Throughput** | Capacity planning | Requests per second |
| **Error rate** | System health | 4xx/5xx rate, model loading failures |
| **Prediction distribution** | Concept drift | Distribution of predicted classes over time |
| **Input feature distribution** | Data drift | KS-test on feature distributions vs training |
| **Model confidence** | Quality degradation | Average prediction probability; alert if dropping |
| **Business metrics** | Real-world impact | MTTR, ticket resolution rate, user satisfaction |

**Monitoring Stack (from my projects):**

```
Model (FastAPI on EC2)
    │
    ├── CloudWatch Metrics → Latency, error rate, throughput
    ├── Custom Metrics → Prediction distribution, confidence scores
    └── CloudWatch Alarms → Alert when thresholds breached
```

**Alert Rules Example:**

| Metric | Threshold | Action |
|---|---|---|
| p95 latency > 500ms | 5 min sustained | Page on-call |
| Error rate > 1% | 2 min sustained | Page on-call |
| Prediction confidence avg < 0.7 | 1 hour | Investigate drift |
| Class distribution shift > 20% | 24 hours | Trigger retrain evaluation |

---

## 7. Statistics & Probability

---

### Q55. Explain Bayes' theorem with an example.

**Answer:**

$$P(A|B) = \frac{P(B|A) \times P(A)}{P(B)}$$

- **P(A|B):** Posterior — probability of A given we observed B
- **P(B|A):** Likelihood — probability of B given A is true
- **P(A):** Prior — probability of A before observing B
- **P(B):** Evidence — total probability of observing B

**Spam Detection Example:**

Given:
- P(spam) = 0.3 (30% of emails are spam — **prior**)
- P("free" | spam) = 0.8 (80% of spam emails contain "free" — **likelihood**)
- P("free" | not spam) = 0.1 (10% of legit emails contain "free")
- P("free") = P("free"|spam)×P(spam) + P("free"|not spam)×P(not spam) = 0.8×0.3 + 0.1×0.7 = 0.31

$$P(\text{spam} | \text{"free"}) = \frac{0.8 \times 0.3}{0.31} = 0.77$$

If an email contains "free", there's a 77% chance it's spam.

**Naive Bayes classifier:** Applies this to multiple features, assuming feature independence (which is "naive" — rarely true, but works surprisingly well in practice, especially for text classification).

---

### Q57. Explain A/B testing. How would you use it for model comparison?

**Answer:**

A/B testing compares two variants (control A vs treatment B) by randomly splitting users and measuring statistical significance of the difference.

**For ML Model Comparison:**

```
Users
  ├── 50% → Model A (current production) → Measure metric
  └── 50% → Model B (candidate)          → Measure metric
```

**Steps:**

1. **Define hypothesis:** "Model B improves ticket resolution time by >5%"
2. **Choose metric:** Mean resolution time (business metric, not ML metric)
3. **Calculate sample size:** Based on desired significance (α=0.05), power (β=0.8), and minimum detectable effect
4. **Run experiment:** Route traffic randomly, measure for sufficient duration
5. **Analyze results:**

```python
from scipy.stats import ttest_ind

# Compare resolution times
t_stat, p_value = ttest_ind(model_a_times, model_b_times)

if p_value < 0.05:
    print("Statistically significant difference")
    if model_b_times.mean() < model_a_times.mean():
        print("Model B is better → promote to production")
```

**Pitfalls:**
- **Peeking:** Don't check results too early (inflates false positive rate)
- **Sample size:** Run until pre-calculated size is reached
- **Network effects:** One user's experience affecting another's
- **Multiple metrics:** Correct for multiple comparisons (Bonferroni)

---

## Quick Revision Cheatsheet — P1

| # | Question | Key Answer (1 line) |
|---|---|---|
| 3 | LangChain memory | Buffer(all), Window(last K), Summary(LLM summarizes), VectorStore(embed+retrieve) |
| 4 | Output parsers | PydanticOutputParser for typed schema; OutputFixingParser for retry on failure |
| 7 | LangGraph conditional edges | Router function returns next node name; enables branching, loops, human-in-loop |
| 11 | Embedding models | OpenAI(best API), bge-large(best open), MiniLM(fastest local); choose by privacy/cost/quality |
| 12 | Vector databases | FAISS(local), PGVector(Postgres), Pinecone(managed); HNSW vs IVF indexing |
| 15 | Multi-agent systems | Supervisor, peer-to-peer, hierarchical, pipeline; shared state for communication |
| 16 | Tool-use patterns | Schema definition → LLM selects tool → execute → return result; good descriptions are key |
| 19 | MCP server for DB | Define tool schemas, validate input (SELECT only), use connection pool, audit log |
| 20 | Transformer | Self-attention(QKV), multi-head, positional encoding; O(n²) attention; encoder/decoder variants |
| 27 | Decision tree splitting | Entropy/IG(ID3), Gini(CART); choose feature that maximizes purity; prune to prevent overfitting |
| 28 | Bagging vs boosting | Bagging=parallel,↓variance(RF); Boosting=sequential,↓bias(XGBoost) |
| 29 | K-Means | K centroids, assign, update; limited: need K, spherical clusters, outlier-sensitive |
| 30 | DBSCAN vs K-Means | DBSCAN for unknown K, arbitrary shapes, outliers; K-Means for known K, spherical, speed |
| 31 | PCA | Max variance projection; for dimensionality reduction, decorrelation, visualization |
| 33 | Word embeddings | Static(Word2Vec,GloVe)=same vector always; Contextual(BERT)=different per context |
| 34 | Attention mechanism | QKV dot-product + softmax; multi-head captures different relationships; O(n²) |
| 37 | AUC-ROC | Area under TPR vs FPR curve; 0.5=random, 1.0=perfect; use PR-AUC for imbalanced data |
| 39 | Cross-validation | K-Fold; Stratified for imbalanced classes; TimeSeries for temporal; Group for clustered data |
| 40 | Under vs overfitting | Train↑Val↑ = underfit; Train↓Val↑ = overfit; learning curves diagnose |
| 41 | Feature engineering | Time features, rolling stats, lag, TF-IDF, embeddings, interactions |
| 42 | Missing values | Median/mode impute, KNN imputer, flag+impute; fit on train only |
| 43 | Normalization vs standardization | MinMax[0,1] for NNs; Z-score for SVM/PCA/LR; trees don't need scaling |
| 44 | Multicollinearity | Detect: correlation matrix, VIF>5; Handle: remove one, PCA, L1/L2 |
| 45 | Feature selection | Filter(fast,MI), Wrapper(best,RFE), Embedded(tree importance,Lasso) |
| 46 | CNN | Conv→ReLU→Pool stack; hierarchical feature learning; images, OCR |
| 48 | Vanishing/exploding gradients | ReLU, BatchNorm, skip connections(ResNet), gradient clipping, LSTM/GRU |
| 49 | Adam vs SGD | Adam=fast convergence,easy tuning; SGD=better generalization,needs schedule |
| 50 | Batch Normalization | Normalize layer outputs; allows higher LR, faster convergence, regularization |
| 51 | Model versioning | MLFlow: params+metrics+artifacts; Model Registry: staging→production→archived |
| 52 | Model drift | Data drift(input dist), Concept drift(X→y mapping); detect: KS-test, monitor predictions |
| 53 | CI/CD for ML | Code→Tests→DataValidation→Train→EvalGate→Docker→Deploy→Monitor |
| 54 | ML monitoring | Latency, throughput, error rate, prediction distribution, drift, business metrics |
| 55 | Bayes' theorem | P(A|B) = P(B|A)P(A)/P(B); posterior = likelihood × prior / evidence |
| 57 | A/B testing | Random split, measure metric, statistical significance (p<0.05); don't peek early |
