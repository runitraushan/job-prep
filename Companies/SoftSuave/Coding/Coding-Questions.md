# Soft Suave — Coding Questions (AIML Engineer)

> **Sources:** GeeksforGeeks (ML interview questions — fetched), LeetCode (training knowledge), general AIML interview patterns (training knowledge)  
> **Soft Suave-specific data:** Not available (Glassdoor, AmbitionBox returned 404)  
> **Last Updated:** 12 March 2026

---

## How to Use This File

- Questions are grouped by category relevant to the AIML Engineer role
- **Primary language:** Python
- Focus: Data manipulation, ML implementation, API design, string/text processing
- For each coding question, LeetCode mapping is provided where applicable
- Difficulty: 🟢 Easy | 🟡 Medium | 🔴 Hard

---

## 1. Python Data Manipulation (Pandas / NumPy)

> Core skill — JD requires Python proficiency and data pipeline work. IT consulting firms test practical data wrangling.

### 1. Clean and Transform a Messy Dataset
- **Type:** Data Manipulation
- **Difficulty:** 🟡 Medium
- **Topics:** Pandas, missing values, type casting, feature engineering
- **Task:** Given a CSV with mixed types, nulls, and duplicates — clean, impute, and output aggregated summary
- **LeetCode:** Not directly on LeetCode. Practice on Kaggle datasets or HackerRank.
- **Source:** Common ML engineer interview pattern (training knowledge)

### 2. Group-By Aggregation with Window Functions
- **Type:** Data Manipulation
- **Difficulty:** 🟡 Medium
- **Topics:** Pandas groupby, rolling averages, rank
- **Task:** Compute rolling 7-day average and rank users by activity score per group
- **LeetCode:** Similar SQL: [#185. Department Top Three Salaries](https://leetcode.com/problems/department-top-three-salaries/) — practice the logic, implement in Pandas
- **Source:** Common data engineering interview pattern (training knowledge)

### 3. Pivot Table and Cross-Tabulation
- **Type:** Data Manipulation
- **Difficulty:** 🟢 Easy
- **Topics:** Pandas pivot_table, crosstab
- **Task:** Create pivot table from transaction data, compute summary statistics
- **LeetCode:** Not on LeetCode. See: [Pandas exercises on GitHub](https://github.com/guipsamora/pandas_exercises)
- **Source:** Training knowledge

### 4. Merge Multiple DataFrames with Different Keys
- **Type:** Data Manipulation
- **Difficulty:** 🟡 Medium
- **Topics:** Pandas merge, join types, handling key conflicts
- **Task:** Left/right/inner join 3 DataFrames, handle duplicate column names
- **LeetCode:** Similar SQL: [#175. Combine Two Tables](https://leetcode.com/problems/combine-two-tables/)
- **Source:** Training knowledge

### 5. NumPy Array Operations — Vectorized Computation
- **Type:** Data Manipulation
- **Difficulty:** 🟢 Easy
- **Topics:** NumPy broadcasting, vectorization, matrix operations
- **Task:** Compute cosine similarity between all pairs of vectors without loops
- **LeetCode:** Not on LeetCode. Common ML interview coding question.
- **Source:** Training knowledge

---

## 2. ML Implementation (From Scratch)

> Tests understanding of algorithms beyond library calls. Expect at least one "implement from scratch" question.

### 6. Implement Linear Regression from Scratch
- **Type:** ML Implementation
- **Difficulty:** 🟡 Medium
- **Topics:** Gradient descent, loss function, numpy
- **Task:** Implement OLS and gradient descent for linear regression, compute MSE
- **LeetCode:** Not on LeetCode. See: [GeeksforGeeks — Linear Regression from Scratch](https://www.geeksforgeeks.org/linear-regression-implementation-from-scratch-using-python/)
- **Source:** GeeksforGeeks ML interview questions (fetched)

### 7. Implement Logistic Regression from Scratch
- **Type:** ML Implementation
- **Difficulty:** 🟡 Medium
- **Topics:** Sigmoid function, binary cross-entropy, gradient descent
- **Task:** Binary classifier with sigmoid, train using gradient descent on toy dataset
- **LeetCode:** Not on LeetCode. Classic ML interview question.
- **Source:** GeeksforGeeks ML interview questions (fetched)

### 8. Implement K-Means Clustering from Scratch
- **Type:** ML Implementation
- **Difficulty:** 🟡 Medium
- **Topics:** Centroid initialization, distance computation, convergence
- **Task:** Implement K-Means with random init and K-Means++ initialization
- **LeetCode:** Not on LeetCode. See: [GeeksforGeeks — K-Means from Scratch](https://www.geeksforgeeks.org/k-means-clustering-introduction/)
- **Source:** GeeksforGeeks ML interview questions (fetched)

### 9. Implement KNN Classifier from Scratch
- **Type:** ML Implementation
- **Difficulty:** 🟢 Easy
- **Topics:** Distance metrics, sorting, majority voting
- **Task:** Implement KNN with Euclidean distance, predict on test set, vary K
- **LeetCode:** Not on LeetCode. Fundamental ML coding question.
- **Source:** GeeksforGeeks ML interview questions (fetched)

### 10. Implement Decision Tree (ID3 / CART) from Scratch
- **Type:** ML Implementation
- **Difficulty:** 🔴 Hard
- **Topics:** Entropy, information gain, Gini index, recursive splitting
- **Task:** Build decision tree classifier, implement both entropy and Gini splitting criteria
- **LeetCode:** Not on LeetCode. Advanced ML implementation question.
- **Source:** GeeksforGeeks ML interview questions (fetched)

---

## 3. Python Coding & DSA (Interview-Style)

> Practical coding ability matters. Expect Python-flavored algorithmic questions — not pure competitive programming.

### 11. Two Sum
- **Type:** Array / HashMap
- **Difficulty:** 🟢 Easy
- **Topics:** Hash map, array traversal
- **LeetCode:** [#1. Two Sum](https://leetcode.com/problems/two-sum/)
- **Source:** Universal interview question (training knowledge)

### 12. Top K Frequent Elements
- **Type:** HashMap / Heap
- **Difficulty:** 🟡 Medium
- **Topics:** Counter, heapq, bucket sort
- **LeetCode:** [#347. Top K Frequent Elements](https://leetcode.com/problems/top-k-frequent-elements/)
- **Source:** Common in data-heavy roles (training knowledge)

### 13. Group Anagrams
- **Type:** String / HashMap
- **Difficulty:** 🟡 Medium
- **Topics:** Sorting, defaultdict, string manipulation
- **LeetCode:** [#49. Group Anagrams](https://leetcode.com/problems/group-anagrams/)
- **Source:** Training knowledge

### 14. Merge Intervals
- **Type:** Arrays / Sorting
- **Difficulty:** 🟡 Medium
- **Topics:** Sorting, interval merging
- **LeetCode:** [#56. Merge Intervals](https://leetcode.com/problems/merge-intervals/)
- **Source:** Frequently asked at IT services companies (training knowledge)

### 15. Longest Substring Without Repeating Characters
- **Type:** Sliding Window
- **Difficulty:** 🟡 Medium
- **Topics:** Sliding window, hash set
- **LeetCode:** [#3. Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/)
- **Source:** Training knowledge

### 16. Valid Parentheses
- **Type:** Stack
- **Difficulty:** 🟢 Easy
- **Topics:** Stack, character matching
- **LeetCode:** [#20. Valid Parentheses](https://leetcode.com/problems/valid-parentheses/)
- **Source:** Training knowledge

### 17. Product of Array Except Self
- **Type:** Array
- **Difficulty:** 🟡 Medium
- **Topics:** Prefix/suffix products, no division
- **LeetCode:** [#238. Product of Array Except Self](https://leetcode.com/problems/product-of-array-except-self/)
- **Source:** Training knowledge

### 18. LRU Cache
- **Type:** Design / HashMap + Linked List
- **Difficulty:** 🟡 Medium
- **Topics:** OrderedDict, doubly linked list, O(1) operations
- **LeetCode:** [#146. LRU Cache](https://leetcode.com/problems/lru-cache/)
- **Source:** Relevant for caching in ML systems (training knowledge)

---

## 4. Text / NLP Processing

> Matches the NLP experience on resume (BERT classifier, OCR pipeline). IT consulting AIML roles test text processing.

### 19. Implement TF-IDF from Scratch
- **Type:** NLP / Text Processing
- **Difficulty:** 🟡 Medium
- **Topics:** Term frequency, inverse document frequency, vectorization
- **Task:** Given a corpus, compute TF-IDF matrix without sklearn
- **LeetCode:** Not on LeetCode. Common NLP interview coding question.
- **Source:** Training knowledge

### 20. Text Preprocessing Pipeline
- **Type:** NLP / Text Processing
- **Difficulty:** 🟢 Easy
- **Topics:** Regex, tokenization, stopwords, stemming/lemmatization
- **Task:** Build a complete text cleaning pipeline: lowercase, remove punctuation, tokenize, remove stopwords, lemmatize
- **LeetCode:** Not on LeetCode. Practical ML interview question.
- **Source:** Training knowledge

### 21. Implement Word2Vec Skip-Gram (Simplified)
- **Type:** NLP / Embeddings
- **Difficulty:** 🔴 Hard
- **Topics:** Neural network, softmax, negative sampling, word embeddings
- **Task:** Implement simplified skip-gram model to generate word embeddings
- **LeetCode:** Not on LeetCode. Advanced NLP question.
- **Source:** Training knowledge

### 22. Regular Expression Matching for Log Parsing
- **Type:** String / Regex
- **Difficulty:** 🟡 Medium
- **Topics:** Python re module, named groups, pattern extraction
- **Task:** Parse structured log files, extract timestamps, error codes, messages
- **LeetCode:** Similar: [#10. Regular Expression Matching](https://leetcode.com/problems/regular-expression-matching/) — but practical version uses Python `re` module
- **Source:** Matches AIOps log pipeline experience (training knowledge)

---

## 5. API Design & ML Serving

> JD: "Implement scalable ML infrastructure and productionize models." FastAPI experience on resume.

### 23. Build a FastAPI Model Inference Endpoint
- **Type:** API Design
- **Difficulty:** 🟡 Medium
- **Topics:** FastAPI, Pydantic validation, async, model loading
- **Task:** Create POST endpoint that accepts input features, validates with Pydantic, runs sklearn model, returns prediction with confidence
- **LeetCode:** Not on LeetCode. Practical ML engineering question.
- **Source:** Training knowledge

### 24. Implement Batch Prediction API with Rate Limiting
- **Type:** API Design
- **Difficulty:** 🟡 Medium
- **Topics:** Batch processing, asyncio, rate limiting, error handling
- **Task:** API that accepts batch of inputs, processes concurrently, handles failures gracefully
- **LeetCode:** Not on LeetCode. ML production pattern.
- **Source:** Training knowledge

### 25. Design a Simple Feature Store Interface
- **Type:** Design / OOP
- **Difficulty:** 🟡 Medium
- **Topics:** Python classes, caching, lazy loading, versioning
- **Task:** Implement a feature store class that stores/retrieves features by entity ID with caching
- **LeetCode:** Not on LeetCode. ML engineering design question.
- **Source:** Training knowledge

---

## 6. SQL for Data Science

> Analysis doc: SQL is a medium-frequency topic. Window functions and complex joins expected.

### 26. Second Highest Salary
- **Type:** SQL
- **Difficulty:** 🟢 Easy
- **Topics:** Subquery, LIMIT, OFFSET
- **LeetCode:** [#176. Second Highest Salary](https://leetcode.com/problems/second-highest-salary/)
- **Source:** Training knowledge

### 27. Rank Scores
- **Type:** SQL
- **Difficulty:** 🟡 Medium
- **Topics:** Window functions (DENSE_RANK)
- **LeetCode:** [#178. Rank Scores](https://leetcode.com/problems/rank-scores/)
- **Source:** Training knowledge

### 28. Consecutive Numbers
- **Type:** SQL
- **Difficulty:** 🟡 Medium
- **Topics:** Self-join, LAG/LEAD
- **LeetCode:** [#180. Consecutive Numbers](https://leetcode.com/problems/consecutive-numbers/)
- **Source:** Training knowledge

### 29. Department Top Three Salaries
- **Type:** SQL
- **Difficulty:** 🔴 Hard
- **Topics:** Window functions, DENSE_RANK, partition
- **LeetCode:** [#185. Department Top Three Salaries](https://leetcode.com/problems/department-top-three-salaries/)
- **Source:** Training knowledge

### 30. Trips and Users (Cancellation Rate)
- **Type:** SQL
- **Difficulty:** 🔴 Hard
- **Topics:** Conditional aggregation, CASE WHEN, JOIN, filtering
- **LeetCode:** [#262. Trips and Users](https://leetcode.com/problems/trips-and-users/)
- **Source:** Training knowledge

---

## Prep Priority

| Category | Count | Priority | Notes |
|---|---|---|---|
| Data Manipulation (Pandas/NumPy) | 5 | 🔴 P0 | Most likely to be tested — practical skill |
| ML from Scratch | 5 | 🔴 P0 | Demonstrates deep understanding |
| Python DSA | 8 | 🟡 P1 | Medium difficulty, Python-flavored |
| NLP/Text Processing | 4 | 🟡 P1 | Matches resume projects |
| API Design / ML Serving | 3 | 🟡 P1 | Productionization focus in JD |
| SQL | 5 | 🟢 P2 | May or may not be tested |
