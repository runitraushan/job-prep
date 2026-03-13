# Soft Suave — ML Concepts Solutions — P0 (🔴 High Priority)

> **Role:** AIML Engineer | **Language:** Python | **Date:** 12 March 2026
> **Total Questions:** 22 | **Study Time:** 6-9 hours/week
> **Sections:** GenAI & LLMs (14), ML Algorithms (4), Model Evaluation (3), Deep Learning (1)

---

## 1. GenAI & LLMs

---

### Q1. What is LangChain and why would you use it instead of calling LLM APIs directly?

**Answer:**

LangChain is an open-source framework that provides **abstractions and composable building blocks** for building LLM-powered applications. Think of it like Spring Boot for LLMs — you _could_ make raw HTTP calls, but the framework handles boilerplate, patterns, and integrations.

**Core Components:**

| Component | Purpose | Example |
|---|---|---|
| **Models** | Unified interface to LLMs (OpenAI, Anthropic, local) | `ChatOpenAI(model="gpt-4")` |
| **Prompts** | Template management, few-shot examples | `ChatPromptTemplate.from_messages(...)` |
| **Chains** | Composable pipelines of LLM calls | `prompt | llm | output_parser` (LCEL) |
| **Agents** | LLM decides which tools to call | `create_react_agent(llm, tools)` |
| **Memory** | Conversation state persistence | `ConversationBufferMemory()` |
| **Retrievers** | Interface to vector stores for RAG | `vectorstore.as_retriever()` |

**Why LangChain over raw API calls:**

1. **Abstractions** — Swap LLM providers (OpenAI → Anthropic) without rewriting code
2. **Composability** — Chain prompts, parsers, retrievers into pipelines with LCEL (LangChain Expression Language)
3. **Memory management** — Built-in conversation memory strategies
4. **Tool integration** — 100+ pre-built tool integrations (search, databases, APIs)
5. **Structured output** — Output parsers enforce schemas (Pydantic, JSON)
6. **Ecosystem** — LangSmith (observability), LangServe (deployment), LangGraph (complex agents)

**When NOT to use LangChain:**

- Simple one-shot API calls with no chaining
- When you need maximum control over token-level handling
- Performance-critical paths where abstraction overhead matters
- When the framework version churn creates upgrade burden

**Interview Tip:** Frame it as "I use LangChain when the application involves _composition_ — multiple LLM calls, tools, or retrieval. For simple prompt→response, raw API is fine."

---

### Q2. Explain the difference between a Chain and an Agent in LangChain.

**Answer:**

| Aspect | Chain | Agent |
|---|---|---|
| **Control flow** | Deterministic — steps execute in fixed order | Dynamic — LLM decides what to do next |
| **Decision making** | Developer-defined pipeline | LLM-driven at runtime |
| **Predictability** | High — same input → same execution path | Lower — LLM may choose different tools |
| **Use case** | Known workflows (RAG, summarization) | Open-ended tasks (research, data analysis) |
| **Cost** | Predictable token usage | Variable — multiple LLM calls possible |
| **Debugging** | Easier — trace fixed steps | Harder — need observability (LangSmith) |

**Chain Example (LCEL):**

```python
# Deterministic: prompt → LLM → parser, always in this order
chain = prompt | llm | StrOutputParser()
result = chain.invoke({"question": "What is RAG?"})
```

**Agent Example:**

```python
# Dynamic: LLM decides which tool to call and when to stop
tools = [search_tool, calculator_tool, db_tool]
agent = create_react_agent(llm, tools, prompt)
# LLM might call search, then calculator, then answer — or just answer directly
result = agent.invoke({"input": "What's the GDP of India in USD?"})
```

**The ReAct Pattern (how agents work):**

```
Thought: I need to search for India's GDP
Action: search_tool("India GDP 2025")
Observation: India's GDP is $3.94 trillion
Thought: The user asked for USD, I already have it in USD
Final Answer: India's GDP is approximately $3.94 trillion USD
```

**When to choose which:**

- **Chain:** "Summarize this document" — fixed pipeline, no tool needs
- **Agent:** "Research this company and prepare a report" — needs search, reading, synthesis, unknown number of steps

---

### Q5. What is LangGraph and how is it different from LangChain?

**Answer:**

LangGraph is a library for building **stateful, multi-actor applications with LLMs** using a graph-based architecture. It's built on top of LangChain but solves problems that LangChain's linear chain model can't handle well.

**Key Difference:**

| Aspect | LangChain (LCEL) | LangGraph |
|---|---|---|
| **Structure** | Linear chain/pipeline | Directed graph with cycles |
| **State** | Passed through chain, no persistence | First-class stateful object, checkpointed |
| **Control flow** | Sequential (with simple branching) | Conditional edges, loops, parallel branches |
| **Error handling** | Try-catch at chain level | Node-level retry, fallback paths |
| **Human-in-the-loop** | Difficult | Built-in (interrupt_before, interrupt_after) |
| **Multi-agent** | Awkward workarounds | Native multi-agent patterns |
| **Persistence** | Manual | Built-in checkpointing (SQLite, Postgres) |

**LangGraph Core Concepts:**

```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated

# 1. Define State
class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    next_action: str

# 2. Define Nodes (functions that transform state)
def classify_intent(state: AgentState) -> AgentState:
    # LLM classifies user intent
    ...

def handle_query(state: AgentState) -> AgentState:
    # RAG retrieval + answer
    ...

def handle_action(state: AgentState) -> AgentState:
    # Tool use
    ...

# 3. Build Graph
graph = StateGraph(AgentState)
graph.add_node("classify", classify_intent)
graph.add_node("query", handle_query)
graph.add_node("action", handle_action)

# 4. Add Edges (including conditional)
graph.add_edge(START, "classify")
graph.add_conditional_edges("classify", route_by_intent, {
    "question": "query",
    "action": "action"
})
graph.add_edge("query", END)
graph.add_edge("action", END)

app = graph.compile()
```

**When to use LangGraph over LangChain:**

- Agent needs **loops** (retry until success, iterative refinement)
- **Multi-agent** coordination (supervisor + workers)
- Need **human-in-the-loop** approval at specific steps
- Complex **branching logic** based on intermediate results
- Need **persistent state** across conversations (checkpointing)
- Error **recovery** — resume from last successful node

**Interview Tip:** "I think of LangChain for pipelines and LangGraph for workflows. If the flow is linear, LangChain. If it branches, loops, or involves multiple actors, LangGraph."

---

### Q6. Explain the concept of state in LangGraph. How is it managed?

**Answer:**

State in LangGraph is a **typed dictionary** that flows through the graph and gets transformed by each node. It's the single source of truth for the entire workflow.

**How State Works:**

```python
from typing import TypedDict, Annotated
from langgraph.graph import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]  # Reducer: appends new messages
    documents: list[str]                     # Overwritten each time
    retry_count: int                         # Tracks retries
```

**Key Concepts:**

1. **Annotation Reducers** — Define how state fields are updated:
   - `add_messages` — appends new messages to existing list (doesn't overwrite)
   - Default — overwrites the field entirely
   - Custom reducer — any function `(old, new) -> merged`

2. **State Channels** — Each key in the TypedDict is a channel. Nodes read from and write to channels.

3. **Checkpointing** — State is saved after each node execution:
   ```python
   from langgraph.checkpoint.sqlite import SqliteSaver
   memory = SqliteSaver.from_conn_string(":memory:")
   app = graph.compile(checkpointer=memory)
   
   # Resume from checkpoint with thread_id
   config = {"configurable": {"thread_id": "user-123"}}
   result = app.invoke(input, config)
   ```

4. **Multi-agent state** — All agents share the same state object. Each agent reads what it needs and writes its outputs.

**State management across conversations:**

```
Request 1: User asks question → state saved to checkpoint
Request 2: Same thread_id → state restored → conversation continues
```

**Error recovery:** If node 3 of 5 fails, checkpointing means you can resume from node 3's input state — no need to re-run nodes 1 and 2.

---

### Q8. Explain RAG architecture end-to-end.

**Answer:**

RAG (Retrieval-Augmented Generation) grounds LLM responses in factual, up-to-date data by **retrieving relevant documents** before generating answers.

**End-to-End Pipeline:**

```
┌─────────────────── INDEXING (Offline) ───────────────────┐
│                                                           │
│  Documents → Loader → Chunker → Embedder → Vector Store  │
│                                                           │
└───────────────────────────────────────────────────────────┘

┌─────────────────── RETRIEVAL + GENERATION (Online) ──────┐
│                                                           │
│  Query → Embedder → Vector Search → Reranker → Top-K     │
│                          ↓                                │
│  Context + Query → Prompt Template → LLM → Answer         │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

**Step-by-Step:**

| Step | Component | Details |
|---|---|---|
| **1. Load** | Document Loaders | PDF, HTML, Markdown, databases, APIs |
| **2. Chunk** | Text Splitters | Break documents into smaller pieces (see Q9) |
| **3. Embed** | Embedding Model | Convert chunks to vector representations (768-1536 dims) |
| **4. Store** | Vector Database | Store embeddings + metadata (FAISS, PGVector, Pinecone) |
| **5. Query** | User Input | Natural language question |
| **6. Retrieve** | Similarity Search | Find top-K most similar chunks (cosine similarity) |
| **7. Rerank** | Cross-Encoder | Re-score retrieved chunks for relevance (optional but improves quality) |
| **8. Generate** | LLM | Combine retrieved context + question in prompt, generate answer |
| **9. Evaluate** | RAGAS/Custom | Measure faithfulness, relevancy, context quality |

**Python Example (LangChain):**

```python
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain.chains import RetrievalQA

# Indexing
embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_documents(chunks, embeddings)

# Retrieval + Generation
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
llm = ChatOpenAI(model="gpt-4")
qa_chain = RetrievalQA.from_chain_type(llm=llm, retriever=retriever)

answer = qa_chain.invoke("What is our refund policy?")
```

**Production Considerations:**

- **Hybrid search** — Combine vector similarity + keyword (BM25) for better recall
- **Metadata filtering** — Filter by date, source, category before vector search
- **Caching** — Cache frequent queries to reduce LLM calls
- **Guardrails** — Validate answers, detect "I don't know" vs hallucination

**Interview Tip:** Mention your SOP chatbot project — "I built a production RAG system using AWS Bedrock + PGVector that reduced ticket volume by 20%."

---

### Q9. What chunking strategies would you use for different document types?

**Answer:**

Chunking directly affects retrieval quality — chunks too large dilute relevant info, chunks too small lose context.

**Strategies:**

| Strategy | How It Works | Best For |
|---|---|---|
| **Fixed-Size** | Split every N characters/tokens | Simple text, logs |
| **Recursive Character** | Split by `\n\n` → `\n` → `. ` → ` ` → char, recursively | General purpose (LangChain default) |
| **Semantic** | Embed sentences, split where embedding similarity drops | Varied documents with topic shifts |
| **Document-Aware** | Split by structure (markdown headers, HTML tags, code blocks) | Structured docs, code, markdown |
| **Sentence-Based** | Split at sentence boundaries (NLTK/spaCy) | Narrative text, articles |
| **Parent-Child** | Small chunks for retrieval, return parent (larger) for context | When you need both precision and context |

**Document-Type Recommendations:**

| Document Type | Recommended Chunking | Chunk Size | Overlap |
|---|---|---|---|
| SOPs / Policies | Markdown header-based | 500-1000 tokens | 100 tokens |
| Legal documents | Paragraph + section-aware | 800-1200 tokens | 200 tokens |
| Code documentation | Code block-aware | 500-800 tokens | 50 tokens |
| Log files | Line-based / fixed-size | 200-500 tokens | 0 |
| Chat transcripts | Turn-based | Variable | 1-2 turns |
| Tables | Keep table rows together | Whole table | 0 |

**Key Parameters:**

- **Chunk size** — 500-1000 tokens is typical sweet spot. Larger = more context but diluted relevance
- **Overlap** — 10-20% overlap prevents losing info at chunk boundaries
- **Metadata** — Always preserve source file, page number, section header with each chunk

**Handling tables:** Don't chunk through table rows. Either keep the entire table as one chunk or convert to natural language ("Column A: value, Column B: value").

---

### Q10. How would you evaluate a RAG system's quality?

**Answer:**

RAG evaluation is tricky because you're evaluating **retrieval** AND **generation** — a problem can originate in either.

**RAGAS Framework (standard metrics):**

| Metric | What It Measures | Formula (Simplified) |
|---|---|---|
| **Faithfulness** | Is the answer grounded in retrieved context? | % of answer claims supported by context |
| **Answer Relevancy** | Does the answer address the question? | Semantic similarity(answer, question) |
| **Context Precision** | Are the retrieved docs relevant? | % of retrieved docs that are actually useful |
| **Context Recall** | Did retrieval find all relevant docs? | % of ground truth info covered by retrieved docs |

**Evaluation Approach:**

```
                    Context Precision
                    Context Recall
                         ↓
Question → Retrieval → Retrieved Docs → Generation → Answer
                                                       ↓
                                              Faithfulness
                                              Answer Relevancy
```

**Diagnostic Matrix:**

| Retrieval Quality | Generation Quality | Diagnosis |
|---|---|---|
| ✅ Good | ✅ Good | System working well |
| ✅ Good | ❌ Bad | LLM problem — improve prompt, use better model |
| ❌ Bad | ✅ Good | Retrieval problem — improve chunking, embeddings, reranking |
| ❌ Bad | ❌ Bad | Fundamental issues — check data quality first |

**Practical Evaluation Pipeline:**

1. **Build a ground truth dataset** — 50-100 (question, expected_answer, source_docs) triples
2. **Run automated metrics** — RAGAS scores on the dataset
3. **LLM-as-judge** — Use GPT-4 to rate answer quality on a 1-5 scale
4. **Human evaluation** — Subject matter experts rate a sample (expensive but crucial)
5. **A/B testing** — Compare RAG versions in production with user feedback

**Hallucination Detection:**

- Cross-reference answer claims against retrieved context
- Use NLI (Natural Language Inference) model to check entailment
- Flag answers where confidence is low or context is sparse

---

### Q13. What is an AI Agent? How does it differ from a chatbot?

**Answer:**

| Aspect | Chatbot | AI Agent |
|---|---|---|
| **Architecture** | Prompt → LLM → Response | LLM + Tools + Planning + Memory |
| **Decision Making** | Scripted or single LLM call | Autonomous — decides what tools to use |
| **Actions** | Only generates text | Can take real-world actions (API calls, DB writes, web search) |
| **Planning** | None | Breaks complex tasks into steps |
| **Memory** | Session-based (if any) | Long-term + working memory |
| **Loops** | Single turn | Iterative — act, observe, reason, repeat |
| **Error Handling** | Return error message | Retry with different approach |

**Agent Architecture:**

```
                    ┌──────────────┐
                    │   Planning   │  ← Breaks task into sub-tasks
                    └──────┬───────┘
                           │
User Query → ┌─────────────▼──────────────┐
             │       LLM (Brain)          │  ← Reasons about next action
             └─────────────┬──────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────▼───┐  ┌────▼───┐  ┌────▼───┐
         │ Tool 1 │  │ Tool 2 │  │ Tool 3 │   ← Executes actions
         │ Search │  │  DB    │  │  API   │
         └────┬───┘  └────┬───┘  └────┬───┘
              │            │            │
              └────────────┼────────────┘
                           │
                    ┌──────▼───────┐
                    │   Memory     │  ← Remembers past actions & results
                    └──────────────┘
```

**Real Example — Your Ticket Triaging Agent:**

A chatbot approach: "What category is this ticket?" → LLM classifies → done.

An agent approach: 
1. Read ticket → classify category and priority
2. Search knowledge base for similar resolved tickets
3. If SOP exists → suggest resolution
4. If no SOP → route to appropriate team
5. Update ticket metadata in ServiceNow
6. Track resolution time for analytics

---

### Q14. Explain the ReAct (Reasoning + Acting) pattern.

**Answer:**

ReAct combines **chain-of-thought reasoning** with **tool use** in an interleaved loop. The LLM alternates between thinking about what to do and actually doing it.

**The Loop:**

```
Thought  → I need to figure out X         (Reasoning)
Action   → tool_name(arguments)            (Acting)
Observation → result from tool             (Environment feedback)
Thought  → Based on the result, I now know Y
Action   → another_tool(arguments)
Observation → result
Thought  → I have enough info to answer
Final Answer → Here's the answer
```

**Concrete Example:**

```
User: "How much did our RAG chatbot reduce ticket volume last month?"

Thought: I need to query the ticket analytics database for last month's numbers.
Action: query_db("SELECT COUNT(*) FROM tickets WHERE created_at >= '2026-02-01' 
        AND created_at < '2026-03-01' GROUP BY resolution_method")
Observation: {"self_service": 450, "human_agent": 1350, "total": 1800}

Thought: I need to compare with the month before the chatbot was deployed.
Action: query_db("SELECT COUNT(*) FROM tickets WHERE created_at >= '2025-12-01' 
        AND created_at < '2026-01-01'")
Observation: {"total": 2250}

Thought: Before chatbot: 2250 tickets. After: 1800 total, but 450 resolved 
         by self-service. That's a 20% reduction in human-handled tickets.
Final Answer: The RAG chatbot reduced ticket volume by 20% last month 
             (from 2250 to 1800 total, with 450 handled via self-service).
```

**Why ReAct works:**

1. **Reasoning is explicit** — The LLM explains its thinking before acting, reducing errors
2. **Grounded in observations** — Each action produces real data, not hallucinated facts
3. **Iterative refinement** — If one tool fails or gives unexpected results, the LLM can adapt

**Failure modes and mitigations:**

| Failure | Mitigation |
|---|---|
| Infinite loops (keeps calling same tool) | Max iterations limit, loop detection |
| Wrong tool selection | Better tool descriptions, few-shot examples |
| Hallucinated tool names | Strict tool schema validation |
| Expensive loops (many LLM calls) | Budget limit (max tokens/cost) |

**Alternative patterns:**

- **Plan-and-Execute** — Plan all steps first, then execute sequentially. Better for complex multi-step tasks.
- **Reflexion** — Adds a self-reflection step after observation. "Was my approach correct?"

---

### Q17. What is MCP (Model Context Protocol) and why does it matter?

**Answer:**

MCP (Model Context Protocol) is an **open standard** (created by Anthropic) that standardizes how LLM applications connect to external data sources and tools. Think of it like **USB for AI** — a universal interface so any LLM can talk to any tool.

**The Problem MCP Solves:**

Before MCP, every LLM tool integration was custom:
- OpenAI Function Calling → specific JSON schema
- LangChain tools → LangChain-specific wrapper
- Claude tool use → Anthropic-specific format

If you had 10 tools and 5 LLM providers, you needed 50 integrations. With MCP: 10 MCP servers + 5 MCP clients = 15 implementations.

**Architecture:**

```
┌──────────────┐     MCP Protocol      ┌──────────────┐
│  MCP Client  │ ◄──── JSON-RPC ────► │  MCP Server  │
│  (LLM App)   │                       │  (Tool/Data) │
└──────────────┘                       └──────────────┘
     │                                       │
  Connects to                          Exposes:
  any MCP server                       - Tools (functions)
                                       - Resources (data)
                                       - Prompts (templates)
```

**Core Concepts:**

| Concept | What It Is | Example |
|---|---|---|
| **Tool** | A function the LLM can call | `query_database(sql)`, `send_email(to, body)` |
| **Resource** | Data the LLM can read | `file://docs/policy.pdf`, `db://users` |
| **Prompt** | Pre-built prompt templates | `summarize_document(doc_url)` |
| **Transport** | Communication layer | stdio (local), SSE (remote/HTTP) |

**Why MCP matters:**

1. **Interoperability** — Build a tool once, use with any MCP-compatible LLM client
2. **Security** — Standardized auth, scoping, permission model
3. **Discovery** — Clients can discover what tools/resources a server offers
4. **Ecosystem** — Growing library of pre-built MCP servers (GitHub, Slack, databases, file systems)

**MCP vs Function Calling:**

| Aspect | Function Calling | MCP |
|---|---|---|
| Scope | Single LLM provider | Universal standard |
| Discovery | Manual definition | Server advertises capabilities |
| Transport | API-embedded | Separate transport layer |
| State | Stateless | Supports stateful connections |
| Ecosystem | Provider-specific | Shared across all adopters |

---

### Q18. Explain MCP's architecture — server, client, and transport.

**Answer:**

**MCP Server** — Process that exposes tools, resources, and prompts:

```python
# Example: Simple MCP Server (Python SDK)
from mcp.server import Server
from mcp.types import Tool, TextContent

server = Server("my-database-server")

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="query_db",
            description="Execute a read-only SQL query",
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {"type": "string", "description": "SQL query to execute"}
                },
                "required": ["sql"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "query_db":
        # Validate and execute query (read-only, parameterized)
        result = execute_safe_query(arguments["sql"])
        return [TextContent(type="text", text=str(result))]
```

**MCP Client** — The LLM application that connects to servers:

```python
from mcp.client import ClientSession, StdioServerParameters

# Connect to server via stdio
server_params = StdioServerParameters(
    command="python", args=["my_server.py"]
)
async with ClientSession(server_params) as session:
    # Discover available tools
    tools = await session.list_tools()
    
    # Call a tool
    result = await session.call_tool("query_db", {"sql": "SELECT * FROM users LIMIT 5"})
```

**Transport Layer:**

| Transport | Protocol | Use Case |
|---|---|---|
| **stdio** | Standard input/output | Local servers (same machine) |
| **SSE (Server-Sent Events)** | HTTP-based | Remote servers, web deployments |

**Communication: JSON-RPC 2.0**

```json
// Client → Server (request)
{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "query_db", "arguments": {"sql": "..."}}, "id": 1}

// Server → Client (response)
{"jsonrpc": "2.0", "result": {"content": [{"type": "text", "text": "..."}]}, "id": 1}
```

**Lifecycle:**
1. Client spawns/connects to server
2. Client calls `initialize` → server responds with capabilities
3. Client calls `list_tools` / `list_resources` to discover what's available
4. Client calls `call_tool` when the LLM decides to use a tool
5. Connection persists (stateful) until client disconnects

---

### Q21. What is prompt engineering? What techniques do you use?

**Answer:**

Prompt engineering is the practice of **crafting inputs to LLMs** to get reliable, high-quality outputs. It's the first optimization lever before fine-tuning or RAG.

**Techniques (ordered by complexity):**

| Technique | Description | When to Use |
|---|---|---|
| **Zero-Shot** | Just ask the question with no examples | Simple, well-understood tasks |
| **Few-Shot** | Provide 2-5 input/output examples | When format/style needs guidance |
| **Chain-of-Thought (CoT)** | "Think step by step" | Reasoning, math, logic problems |
| **Role Prompting** | "You are an expert ML engineer..." | Setting domain context and tone |
| **System Prompt** | Persistent instructions + constraints | Production apps — safety, format rules |
| **Output Format Constraints** | "Respond in JSON with keys: ..." | Structured output for parsing |
| **Self-Consistency** | Generate N answers, take majority vote | High-stakes decisions |
| **ReAct** | interleave reasoning + tool use | Agents (see Q14) |

**Practical Examples:**

```python
# Zero-shot
"Classify this ticket as bug, feature, or question: {ticket_text}"

# Few-shot
"""Classify tickets:
Ticket: "App crashes on login" → bug
Ticket: "Add dark mode" → feature
Ticket: "How do I reset password?" → question
Ticket: "{ticket_text}" →"""

# Chain-of-thought
"""Analyze this log for anomalies. Think step by step:
1. Identify the normal pattern
2. Find deviations
3. Classify severity
4. Suggest root cause

Log: {log_data}"""

# Structured output
"""Extract entities from this text. Return JSON:
{"persons": [], "organizations": [], "dates": []}
Text: {text}"""
```

**Prompt Injection Prevention:**

- Separate system/user prompts clearly
- Validate and sanitize user input
- Use delimiters (`"""`, `---`) to separate instructions from data
- Never pass user input as system prompt
- Output validation — reject responses that look like prompt leaks

---

### Q22. How do you handle LLM hallucinations in production?

**Answer:**

Hallucination is when the LLM generates confident-sounding but **factually incorrect** or **unsupported** information. In production, this can be catastrophic (wrong medical advice, incorrect financial data).

**Multi-Layer Defense:**

```
┌─── Prevention ───┐    ┌─── Detection ───┐    ┌─── Mitigation ───┐
│ RAG (grounding)  │ →  │ NLI verification │ →  │ Confidence flag   │
│ Constrained gen  │    │ Fact-checking    │    │ Human-in-loop     │
│ Better prompts   │    │ Source citation  │    │ "I don't know"    │
└──────────────────┘    └─────────────────┘    └───────────────────┘
```

**Prevention:**

1. **RAG** — Ground responses in retrieved documents (see Q8)
2. **Constrained generation** — Limit response to information in provided context only: "Answer ONLY based on the context below. If the answer is not in the context, say 'I don't have this information.'"
3. **Temperature = 0** — Reduce randomness for factual queries
4. **Structured output** — Force JSON/schema compliance, harder to hallucinate structure

**Detection:**

1. **Source citation** — Ask LLM to cite specific passages. Verify citations exist.
2. **NLI (Natural Language Inference)** — Use a classifier to check if the answer is entailed by the context
3. **Self-consistency** — Generate answer 3 times; if answers disagree, flag as uncertain
4. **Confidence scoring** — Log-probabilities of tokens (where available)

**Mitigation:**

1. **Graceful "I don't know"** — Train the system to abstain rather than guess
2. **Confidence indicators** — Show users "High/Medium/Low confidence" flags
3. **Human-in-the-loop** — Route low-confidence answers to humans
4. **Feedback loop** — Users report incorrect answers → improve retrieval/prompts

**What I did in production (SOP chatbot):**

- Used RAG with citation-backed responses — every answer includes source SOP reference
- Added a "confidence" field — if retrieval similarity score < 0.7, respond with "I'm not confident, please contact support"
- Monitored hallucination rate through user feedback and sampling

---

### Q23. Explain fine-tuning vs RAG vs prompt engineering. When would you use each?

**Answer:**

| Approach | What It Does | Cost | Latency | Best For |
|---|---|---|---|---|
| **Prompt Engineering** | Craft better prompts | Free | Same | First attempt at any task |
| **RAG** | Add external knowledge at query time | Medium (vector DB, embeddings) | +200-500ms | Dynamic/updated knowledge, factual QA |
| **Fine-Tuning** | Retrain model weights on custom data | High ($, compute, data) | Same/faster | New behavior, style, domain terminology |

**Decision Tree:**

```
Does the model need new KNOWLEDGE?
├── Yes → Is the knowledge static or dynamic?
│   ├── Dynamic (updates frequently) → RAG
│   └── Static (domain vocabulary, style) → Fine-tuning
│       └── Consider: Is fine-tuning data available? (need 100+ examples)
│           ├── Yes → Fine-tune
│           └── No → RAG + few-shot prompting
└── No → Does the model need new BEHAVIOR?
    ├── Yes (different output format, style, reasoning) → Fine-tuning
    └── No → Prompt Engineering (you're probably overthinking it)
```

**When to use each:**

| Scenario | Approach | Why |
|---|---|---|
| "Answer questions about our SOPs" | **RAG** | SOPs update; need grounding in specific docs |
| "Classify tickets into our 50 categories" | **Fine-tuning** | Custom categories the model doesn't know |
| "Summarize this document" | **Prompt engineering** | LLMs already know how to summarize |
| "Write code in our internal DSL" | **Fine-tuning** | Model needs to learn new syntax |
| "Answer using data from last week" | **RAG** | Time-sensitive data |

**Can you combine them? Yes!**

- **RAG + Prompt Engineering** — Most common. Craft retrieval prompts + generation prompts.
- **Fine-tuning + RAG** — Fine-tune for domain style, RAG for factual grounding. Best quality, highest cost.
- **Fine-tuning + Prompt Engineering** — Fine-tune base capability, prompt for specific tasks.

---

### Q24. Explain the bias-variance tradeoff.

**Answer:**

Every model's prediction error has three components:

$$\text{Total Error} = \text{Bias}^2 + \text{Variance} + \text{Irreducible Error}$$

| Component | Meaning | Sign |
|---|---|---|
| **Bias** | Error from wrong assumptions (model too simple) | Underfitting |
| **Variance** | Error from sensitivity to training data (model too complex) | Overfitting |
| **Irreducible Error** | Noise in the data — can't fix | - |

**Visual Analogy:**

Imagine throwing darts at a target:
- **High Bias, Low Variance** — Darts clustered together, but away from center. Consistently wrong.
- **Low Bias, High Variance** — Darts scattered around center. Right on average, but inconsistent.
- **Low Bias, Low Variance** — Darts clustered at center. This is the goal.

**Practical Diagnosis:**

| Symptom | Diagnosis | Fix |
|---|---|---|
| Train error high, val error high | **High bias** (underfitting) | More complex model, more features, less regularization |
| Train error low, val error high | **High variance** (overfitting) | More data, regularization, simpler model, dropout |
| Train error low, val error low | **Sweet spot** | Ship it |

**Example with models:**

| Model | Bias | Variance |
|---|---|---|
| Linear Regression | High | Low |
| Decision Tree (no pruning) | Low | High |
| Random Forest | Low | Lower (bagging reduces variance) |
| XGBoost (tuned) | Low | Low (best balance usually) |

---

### Q25. When would you use Random Forest vs XGBoost vs Neural Networks?

**Answer:**

| Factor | Random Forest | XGBoost | Neural Networks |
|---|---|---|---|
| **Dataset size** | Small-Medium | Small-Large | Large (needs data) |
| **Feature types** | Handles mixed (numerical + categorical) | Handles mixed (needs encoding) | Needs encoding, normalization |
| **Training time** | Fast (parallelizable) | Medium (sequential boosting) | Slow (GPU recommended) |
| **Interpretability** | Feature importance, partial dependence | Feature importance, SHAP | Black box (needs LIME/SHAP) |
| **Hyperparameter tuning** | Forgiving | Sensitive (learning rate, depth, reg) | Very sensitive |
| **Overfitting risk** | Low (bagging reduces variance) | Medium (needs early stopping) | High (needs regularization, dropout) |
| **Tabular data** | ✅ Excellent | ✅ Best in class | 🟡 Not ideal (TabNet emerging) |
| **Unstructured data** | ❌ Not suitable | ❌ Not suitable | ✅ Best (images, text, audio) |

**Decision Guide:**

```
What type of data?
├── Tabular (rows & columns)
│   ├── Small dataset (<10K rows) → Random Forest (robust, less overfitting)
│   ├── Medium dataset (10K-1M) → XGBoost (usually wins Kaggle)
│   └── Large dataset (>1M) → XGBoost or LightGBM (faster training)
│       └── Need interpretability? → XGBoost + SHAP
├── Image → CNN (ResNet, EfficientNet)
├── Text → Transformer (BERT, GPT) or traditional ML with TF-IDF for small data
└── Sequence/Time Series → LSTM/GRU or XGBoost with lag features
```

**Interview Tip:** "For the anomaly detection project at Wabtec, I used Random Forest for classification because the log dataset had mixed feature types and interpretability was important for RCA. For the ticket classifier, I used BERT because it's text data where contextual understanding matters."

---

### Q26. Explain regularization. L1 vs L2 — when would you use each?

**Answer:**

Regularization adds a **penalty term** to the loss function to prevent overfitting by discouraging large weights.

$$\text{Loss} = \text{Original Loss} + \lambda \times \text{Penalty}$$

| Type | Penalty | Effect on Weights | Use Case |
|---|---|---|---|
| **L1 (Lasso)** | $\lambda \sum \|w_i\|$ | Pushes weights to exactly **zero** | Feature selection — sparse models |
| **L2 (Ridge)** | $\lambda \sum w_i^2$ | Pushes weights toward **small values** | Prevent overfitting — all features matter |
| **Elastic Net** | $\alpha L1 + (1-\alpha) L2$ | Combines both | Many correlated features |

**Why L1 gives sparsity:**

The L1 penalty has a "diamond-shaped" constraint region. The optimal point is more likely to hit a corner (where some weight = 0) than a smooth point. L2's circular constraint region has no corners, so weights get small but rarely exactly zero.

**When to use:**

| Scenario | Choice | Reason |
|---|---|---|
| 100 features, suspect only 10 matter | **L1** | Will zero out irrelevant features |
| All features likely important | **L2** | Keeps all, reduces magnitude |
| Many correlated features | **Elastic Net** | L1 alone randomly picks one from a correlated group |
| Neural networks | **L2 (weight decay)** + Dropout | Standard practice |

**In scikit-learn:**

```python
from sklearn.linear_model import Lasso, Ridge, ElasticNet

# L1
lasso = Lasso(alpha=0.1)

# L2
ridge = Ridge(alpha=1.0) 

# Elastic Net
elastic = ElasticNet(alpha=0.1, l1_ratio=0.5)  # 50% L1 + 50% L2
```

---

### Q32. How does BERT work? What makes it different from GPT?

**Answer:**

| Aspect | BERT | GPT |
|---|---|---|
| **Architecture** | Encoder-only Transformer | Decoder-only Transformer |
| **Training** | Masked Language Modeling (MLM) + Next Sentence Prediction (NSP) | Autoregressive (next token prediction) |
| **Direction** | **Bidirectional** — sees left AND right context | Unidirectional — sees only left context |
| **Best for** | Classification, NER, Q&A, embeddings | Text generation, conversation, reasoning |
| **Fine-tuning** | Add task-specific head (e.g., classification layer) | Few-shot prompting or fine-tuning |
| **Output** | Contextual embeddings per token | Next token probabilities |

**How BERT Training Works:**

**1. Masked Language Modeling (MLM):**
```
Input:  "The [MASK] sat on the mat"
Target: "The cat sat on the mat"
```
Randomly mask 15% of tokens, train model to predict them. This forces bidirectional understanding.

**2. Next Sentence Prediction (NSP):**
```
Input:  [CLS] Sentence A [SEP] Sentence B
Label:  IsNextSentence / NotNextSentence
```
Teaches inter-sentence relationships.

**BERT for Classification (Your Ticket Triaging):**

```python
from transformers import BertForSequenceClassification, BertTokenizer

# Load pre-trained BERT
model = BertForSequenceClassification.from_pretrained(
    "bert-base-uncased", num_labels=50  # 50 ticket categories
)
tokenizer = BertTokenizer.from_pretrained("bert-base-uncased")

# Tokenize input
inputs = tokenizer("App crashes on login page", return_tensors="pt")

# Forward pass → classification logits
outputs = model(**inputs)
predicted_class = outputs.logits.argmax(dim=-1)
```

**Why BERT for ticket classification:**
- Bidirectional context captures full meaning ("crash" near "login" vs "crash" near "app")
- Fine-tuning on 50 categories is straightforward with a classification head
- Fast inference — encoder-only is faster than generation

**Why NOT GPT for this task:**
- GPT generates text — overkill for classification
- More expensive (more parameters, autoregressive decoding)
- BERT's bidirectional encoding is better for understanding/classification tasks

---

### Q35. Your model has 95% accuracy but stakeholders say it's not working. What could be wrong?

**Answer:**

This is the **class imbalance trap** — the most common ML evaluation mistake.

**Root Causes:**

**1. Class Imbalance:**
```
Dataset: 95% "Normal", 5% "Anomaly"
Model: Always predicts "Normal"
Accuracy: 95% ✅  ... but catches 0% of anomalies ❌
```

**2. Wrong Metric:**

| Business Need | Right Metric | Not Accuracy |
|---|---|---|
| Fraud detection | **Recall** (catch all fraud, even if some false alarms) | 99.9% accuracy misses rare fraud |
| Spam filter | **Precision** (don't flag real emails as spam) | Accuracy ignores false positive harm |
| Medical diagnosis | **Sensitivity + Specificity** | Missing cancer is worse than false positives |

**3. Distribution Shift:**
- Model trained on data from 6 months ago
- Real-world data has shifted (new patterns, seasonality)
- Accuracy on test set was 95%, but live data is different

**4. Business Metric ≠ ML Metric:**
- Model correctly classifies tickets, but routing is wrong — stakeholders care about resolution time, not classification accuracy

**5. Edge Cases:**
- Model works for 95% of common cases
- Fails on the 5% of critical/complex cases that matter most to stakeholders

**Debugging Checklist:**

```python
# 1. Check class distribution
print(y_test.value_counts(normalize=True))

# 2. Check per-class metrics
from sklearn.metrics import classification_report
print(classification_report(y_true, y_pred))

# 3. Confusion matrix
from sklearn.metrics import confusion_matrix
cm = confusion_matrix(y_true, y_pred)

# 4. Check for distribution shift
# Compare feature distributions: training vs production

# 5. Ask stakeholders: "What specific failures are you seeing?"
```

---

### Q36. Explain precision, recall, F1 score. When would you optimize for each?

**Answer:**

|  | Predicted Positive | Predicted Negative |
|---|---|---|
| **Actually Positive** | TP (True Positive) | FN (False Negative) |
| **Actually Negative** | FP (False Positive) | TN (True Negative) |

$$\text{Precision} = \frac{TP}{TP + FP} \quad \text{("Of predicted positives, how many are correct?")}$$

$$\text{Recall} = \frac{TP}{TP + FN} \quad \text{("Of actual positives, how many did we find?")}$$

$$\text{F1} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} \quad \text{(Harmonic mean)}$$

**When to optimize each:**

| Optimize For | When | Example |
|---|---|---|
| **Precision** | Cost of FP is high (false alarms are expensive) | Spam filter — don't want real emails in spam |
| **Recall** | Cost of FN is high (missing positives is dangerous) | Cancer detection — don't miss any tumors |
| **F1** | Both matter equally, need balance | Ticket classification — need both accuracy and coverage |
| **Custom Fβ** | When one matters more but not exclusively | F2 (recall-heavy) for anomaly detection |

**Threshold Tuning:**

```python
from sklearn.metrics import precision_recall_curve

precisions, recalls, thresholds = precision_recall_curve(y_true, y_scores)

# Find threshold that gives desired recall (e.g., 95%)
target_recall = 0.95
idx = (recalls >= target_recall).nonzero()[0][-1]
optimal_threshold = thresholds[idx]
```

**Ticket triaging example:** "For the BERT classifier, I optimized for F1-macro because we needed balanced performance across all 50 ticket categories. Rare categories couldn't be ignored just because they're rare."

---

### Q38. How do you handle class imbalance?

**Answer:**

**Strategy Matrix:**

| Approach | Technique | When to Use |
|---|---|---|
| **Data-Level** | SMOTE (synthetic oversampling) | Create synthetic minority samples |
| | Random undersampling | When majority class is very large |
| | Augmentation | Text augmentation, image transforms |
| **Algorithm-Level** | Class weights | `class_weight='balanced'` in sklearn |
| | Threshold tuning | Lower threshold for minority class |
| | Focal loss | Deep learning — penalizes easy examples less |
| **Evaluation** | Use F1, AUC, PR-AUC instead of accuracy | **Always do this** |
| **Ensemble** | Balanced Random Forest | Combines undersampling with bagging |

**SMOTE (Synthetic Minority Over-sampling Technique):**

```python
from imblearn.over_sampling import SMOTE

smote = SMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)
# Creates synthetic minority examples by interpolating between existing ones
```

**Class Weights (simplest approach):**

```python
from sklearn.ensemble import RandomForestClassifier

# Automatically adjusts weights inversely proportional to class frequencies
model = RandomForestClassifier(class_weight='balanced')
model.fit(X_train, y_train)
```

**Threshold Tuning (post-training):**

```python
# Default threshold: 0.5
# For minority class detection, lower the threshold:
y_proba = model.predict_proba(X_test)[:, 1]
y_pred = (y_proba >= 0.3).astype(int)  # More sensitive to minority class
```

**What I'd do in practice (ordered):**

1. First: Use **appropriate metrics** (F1, PR-AUC, not accuracy)
2. Second: Try **class weights** (zero code change)
3. Third: Try **threshold tuning** on validation set
4. Fourth: Try **SMOTE** if above isn't enough
5. Fifth: **Collect more data** for minority class if possible

---

### Q47. What is transfer learning and how have you used it?

**Answer:**

Transfer learning reuses a model **trained on a large general dataset** as the starting point for a **specific task**, instead of training from scratch.

**Why it works:**

Early layers learn general features (edges, textures in images; syntax, semantics in text). Later layers specialize. You keep the general knowledge and only retrain the specialist layers.

**Strategies:**

| Strategy | What to Do | When |
|---|---|---|
| **Feature extraction** | Freeze all pre-trained layers, add new classification head | Small dataset, similar domain |
| **Fine-tuning (top layers)** | Freeze early layers, train last few + new head | Medium dataset, related domain |
| **Full fine-tuning** | Train all layers (lower learning rate for pre-trained) | Large dataset, different domain |

**BERT Fine-Tuning for Ticket Classification (your project):**

```python
from transformers import BertForSequenceClassification, Trainer, TrainingArguments

# 1. Load pre-trained BERT (general language understanding)
model = BertForSequenceClassification.from_pretrained(
    "bert-base-uncased",
    num_labels=50  # Your custom ticket categories
)

# 2. Fine-tune on ticket data
training_args = TrainingArguments(
    output_dir="./ticket-classifier",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    learning_rate=2e-5,       # Small LR for fine-tuning (don't destroy pre-trained weights)
    weight_decay=0.01,
    evaluation_strategy="epoch"
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=val_dataset,
)

trainer.train()
```

**Key Fine-Tuning Tips:**

- **Learning rate: 2e-5 to 5e-5** — Much smaller than training from scratch (prevents catastrophic forgetting)
- **Epochs: 2-4** — Fine-tuning converges fast; too many epochs → overfitting
- **Freeze strategy** — Start with feature extraction; if performance is low, gradually unfreeze layers
- **Layer-wise LR decay** — Lower LR for early layers, higher for later layers

**In your interview:** "I used transfer learning with BERT for ticket classification. Pre-trained BERT already understands English syntax and semantics. I just added a classification head for our 50 ticket categories and fine-tuned for 3 epochs. This let us achieve 40% MTTR reduction without needing millions of labeled tickets."

---

## Quick Revision Cheatsheet — P0

| # | Question | Key Answer (1 line) |
|---|---|---|
| 1 | LangChain vs raw API | LangChain for composition (chains, agents, memory, tools); raw API for simple single calls |
| 2 | Chain vs Agent | Chain = deterministic pipeline; Agent = LLM decides tools and order (ReAct) |
| 5 | LangGraph vs LangChain | LangGraph = stateful graphs with cycles, loops, human-in-loop; LangChain = linear pipelines |
| 6 | State in LangGraph | TypedDict with annotation reducers + checkpointing for persistence |
| 8 | RAG end-to-end | Load → Chunk → Embed → Store → Query → Retrieve → Rerank → Generate → Evaluate |
| 9 | Chunking strategies | Recursive char (general), semantic (topic shifts), document-aware (structured), parent-child (precision+context) |
| 10 | RAG evaluation | RAGAS: faithfulness, answer relevancy, context precision, context recall |
| 13 | Agent vs Chatbot | Agent = LLM + tools + planning + memory; autonomous actions, not just text |
| 14 | ReAct pattern | Thought → Action → Observation loop; reasoning interleaved with tool use |
| 17 | MCP | Open standard for LLM-tool interaction; USB for AI; server exposes tools, client connects |
| 18 | MCP architecture | Server (tools/resources/prompts) + Client (LLM app) + Transport (stdio/SSE) + JSON-RPC |
| 21 | Prompt engineering | Zero-shot, few-shot, CoT, role prompting, structured output, self-consistency |
| 22 | Hallucination handling | Prevention (RAG, constrained gen) + Detection (NLI, citation) + Mitigation (confidence, HITL) |
| 23 | Fine-tune vs RAG vs prompting | Prompting first; RAG for dynamic knowledge; fine-tune for new behavior/style |
| 24 | Bias-variance | Bias=underfit, Variance=overfit, Total=Bias²+Variance+Noise |
| 25 | RF vs XGBoost vs NN | RF(robust,tabular,small), XGBoost(best tabular,medium+), NN(images,text,large) |
| 26 | L1 vs L2 | L1=sparsity/feature selection, L2=shrink weights/all features, ElasticNet=correlated features |
| 32 | BERT vs GPT | BERT=bidirectional encoder (classification,embeddings), GPT=autoregressive decoder (generation) |
| 35 | 95% accuracy but broken | Class imbalance, wrong metric, distribution shift, business≠ML metric, edge cases |
| 36 | Precision/Recall/F1 | Precision=FP costly, Recall=FN costly, F1=balance; threshold tuning for trade-off |
| 38 | Class imbalance | Metrics first(F1,AUC) → class weights → threshold tuning → SMOTE → more data |
| 47 | Transfer learning | Reuse pre-trained model; feature extraction or fine-tuning; small LR (2e-5); BERT for ticket classifier |
