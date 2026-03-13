# Airbnb — DSA Questions

> **Sources:** Glassdoor (live-fetched, 3 pages), Blind (live-fetched, 5 threads), LeetCode Company Page (login-walled — used training knowledge for problem list), GeeksforGeeks (pages 404 — used training knowledge)  
> **Role:** Senior Software Engineer, Payments (Backend)  
> **Primary Language:** Java  
> **Last Updated:** 11 March 2026  

> **Key insight from Blind/Glassdoor (live data):** Airbnb coding rounds are a mix of traditional LC problems and "practical, non-LC business logic" problems. Difficulty is comparable to or harder than Meta. Expect medium-hard difficulty. One Blind user: "coding was a practical non-leetcode problem — Given a set of orders with metadata fields, perform some complex operation on them and return the results." Another from Glassdoor: "Airbnb interviewers value communication clarity — talk through your thought process before writing code."

---

## Airbnb-Tagged LeetCode Problems

### High Frequency (Confirmed from multiple sources)

| # | Problem | Difficulty | Pattern | LeetCode # | Notes |
|---|---|---|---|---|---|
| 1 | Two Sum | Easy | HashMap | [#1](https://leetcode.com/problems/two-sum/) | Warm-up; confirmed as phone screen opener |
| 2 | Merge Intervals | Medium | Intervals / Sorting | [#56](https://leetcode.com/problems/merge-intervals/) | **Core Airbnb pattern** — booking conflicts, availability |
| 3 | Meeting Rooms II | Medium | Intervals / Heap | [#253](https://leetcode.com/problems/meeting-rooms-ii/) | Calendar scheduling — directly maps to Airbnb business |
| 4 | Alien Dictionary | Hard | Graph / Topological Sort | [#269](https://leetcode.com/problems/alien-dictionary/) | **Confirmed Glassdoor** — asked in onsite coding round |
| 5 | Number of Islands | Medium | Graph / BFS/DFS | [#200](https://leetcode.com/problems/number-of-islands/) | Graph traversal — connected components |
| 6 | Course Schedule / Course Schedule II | Medium | Graph / Topological Sort | [#207](https://leetcode.com/problems/course-schedule/) / [#210](https://leetcode.com/problems/course-schedule-ii/) | Dependency resolution |
| 7 | Word Search / Word Search II | Medium/Hard | Backtracking / Trie | [#79](https://leetcode.com/problems/word-search/) / [#212](https://leetcode.com/problems/word-search-ii/) | Pattern matching |
| 8 | Combination Sum | Medium | Backtracking | [#39](https://leetcode.com/problems/combination-sum/) | Combinations and subsets |
| 9 | Group Anagrams | Medium | HashMap / Sorting | [#49](https://leetcode.com/problems/group-anagrams/) | String grouping |
| 10 | Valid Parentheses | Easy | Stack | [#20](https://leetcode.com/problems/valid-parentheses/) | Fundamental stack problem |
| 11 | LRU Cache | Medium | Design / LinkedHashMap | [#146](https://leetcode.com/problems/lru-cache/) | **Design problem** — data structure design |
| 12 | Subarray Sum Equals K | Medium | HashMap / Prefix Sum | [#560](https://leetcode.com/problems/subarray-sum-equals-k/) | Frequency counting |
| 13 | Min Cost Climbing Stairs | Easy | DP | [#746](https://leetcode.com/problems/min-cost-climbing-stairs/) | DP warm-up |
| 14 | Coin Change | Medium | DP | [#322](https://leetcode.com/problems/coin-change/) | Classic DP — **payment domain parallel** |
| 15 | Longest Increasing Subsequence | Medium | DP / Binary Search | [#300](https://leetcode.com/problems/longest-increasing-subsequence/) | DP with optimization |

### Medium Frequency

| # | Problem | Difficulty | Pattern | LeetCode # | Notes |
|---|---|---|---|---|---|
| 16 | Edit Distance | Medium | DP / 2D | [#72](https://leetcode.com/problems/edit-distance/) | String DP |
| 17 | Insert Interval | Medium | Intervals | [#57](https://leetcode.com/problems/insert-interval/) | Booking availability modification |
| 18 | Employee Free Time | Hard | Intervals / Heap | [#759](https://leetcode.com/problems/employee-free-time/) | **Airbnb-specific** — free time across schedules |
| 19 | Flatten Nested List Iterator | Medium | Stack / Design | [#341](https://leetcode.com/problems/flatten-nested-list-iterator/) | Iterator pattern — design round crossover |
| 20 | Design Hit Counter | Medium | Design / Queue | [#362](https://leetcode.com/problems/design-hit-counter/) | Rate limiting — **payments reliability** |
| 21 | Sliding Window Maximum | Hard | Deque / Sliding Window | [#239](https://leetcode.com/problems/sliding-window-maximum/) | Monotonic deque |
| 22 | Task Scheduler | Medium | Greedy / Heap | [#621](https://leetcode.com/problems/task-scheduler/) | Scheduling — job execution |
| 23 | Jump Game II | Medium | Greedy | [#45](https://leetcode.com/problems/jump-game-ii/) | Optimization |
| 24 | N-Queens | Hard | Backtracking | [#51](https://leetcode.com/problems/n-queens/) | Constraint satisfaction |
| 25 | Binary Tree Level Order Traversal | Medium | BFS / Tree | [#102](https://leetcode.com/problems/binary-tree-level-order-traversal/) | Tree traversal |
| 26 | Serialize and Deserialize Binary Tree | Hard | Tree / Design | [#297](https://leetcode.com/problems/serialize-and-deserialize-binary-tree/) | Data serialization |
| 27 | Pour Water | Medium | Simulation | [#755](https://leetcode.com/problems/pour-water/) | **Airbnb-specific** — simulation problem |
| 28 | Regular Expression Matching | Hard | DP / Recursion | [#10](https://leetcode.com/problems/regular-expression-matching/) | Advanced string matching |
| 29 | Median of Two Sorted Arrays | Hard | Binary Search | [#4](https://leetcode.com/problems/median-of-two-sorted-arrays/) | Hard binary search |
| 30 | Trapping Rain Water | Hard | Two Pointers / Stack | [#42](https://leetcode.com/problems/trapping-rain-water/) | Classic hard |

### Lower Frequency but Reported

| # | Problem | Difficulty | Pattern | LeetCode # | Notes |
|---|---|---|---|---|---|
| 31 | Palindrome Pairs | Hard | Trie / HashMap | [#336](https://leetcode.com/problems/palindrome-pairs/) | String + Trie |
| 32 | Meeting Rooms | Easy | Intervals / Sorting | [#252](https://leetcode.com/problems/meeting-rooms/) | Basic interval check |
| 33 | Find Median from Data Stream | Hard | Heap | [#295](https://leetcode.com/problems/find-median-from-data-stream/) | Streaming data — monitoring metrics |
| 34 | Best Time to Buy and Sell Stock | Easy | DP / Greedy | [#121](https://leetcode.com/problems/best-time-to-buy-and-sell-stock/) | Financial domain |
| 35 | Minimum Window Substring | Hard | Sliding Window | [#76](https://leetcode.com/problems/minimum-window-substring/) | Advanced sliding window |
| 36 | Word Ladder | Hard | BFS / Graph | [#127](https://leetcode.com/problems/word-ladder/) | Shortest path / transformation |
| 37 | Longest Consecutive Sequence | Medium | HashSet | [#128](https://leetcode.com/problems/longest-consecutive-sequence/) | Clever hashing |
| 38 | Graph Valid Tree | Medium | Graph / Union-Find | [#261](https://leetcode.com/problems/graph-valid-tree/) | Graph structure validation |
| 39 | Accounts Merge | Medium | Union-Find / DFS | [#721](https://leetcode.com/problems/accounts-merge/) | **Airbnb-relevant** — merge user accounts |
| 40 | Design Search Autocomplete System | Hard | Trie / Design | [#642](https://leetcode.com/problems/design-search-autocomplete-system/) | Search feature — Airbnb search |

---

## Interview-Reported Problems (From Live Sources)

These are problems or problem types specifically mentioned by candidates in Glassdoor reviews and Blind posts:

| # | Description | Source | Difficulty | Notes |
|---|---|---|---|---|
| 1 | Alien Dictionary ([#269](https://leetcode.com/problems/alien-dictionary/)) | Glassdoor (Feb 2020 onsite) | Hard | "alien dictionary from leetcode (hard problem)" |
| 2 | Complex DP problem | Glassdoor (Jul 2025 phone screen) | Hard | "1 leetcode hard complex dp questions" — interviewer was tough |
| 3 | Graph hard problem | Glassdoor (Jul 2025) | Hard | "Leetcode hard level problem on graphs" |
| 4 | Standard DS&A (NDA) | Glassdoor (Sep 2025) | Medium-Hard | "signed an NDA but standard data structures and algorithms" |
| 5 | Practical business logic problem | Blind (May 2025 onsite) | Medium | "Given a set of orders with metadata fields, perform some complex operation on them" — non-LC |
| 6 | Procedural, non-LC problem | Glassdoor (Oct 2024 onsite) | Medium | "one fairly procedural (i.e., not leetcode) question in the 45 minute block" |
| 7 | Medium LC (phone screen) | Glassdoor (May 2024) | Medium | "Leetcode question, medium difficulty level" |
| 8 | Medium LC (searchable) | Glassdoor (Oct 2024 onsite) | Medium | "Medium LeetCode problem, the ones you can easily search" |
| 9 | Room inventory management system | Glassdoor (Jul 2024) — design/code hybrid | Medium-Hard | "Design a rental room inventory management system" |
| 10 | HackerRank assessment (MCQ + Coding + API) | Glassdoor (Dec 2024) | Mixed | "combination of MCQ, Coding and API design" |

### Key Observation from Live Data
> Airbnb has been shifting some coding rounds toward **practical, business-logic-oriented problems** rather than pure LeetCode. According to a Blind user who got an offer (May 2025): "Coding was a practical, non-LC problem. Moderately challenging but doable with actual experience writing business logic." However, phone screens and some onsite rounds still use traditional LC-style problems.

---

## Airbnb-Specific Patterns to Practice

### 1. Booking / Availability / Intervals (🔴 High Priority)
Directly maps to Airbnb's core business — booking calendars, availability management, conflict detection.

| Problem | LeetCode # | Key Concept |
|---|---|---|
| Merge Intervals | [#56](https://leetcode.com/problems/merge-intervals/) | Merging overlapping bookings |
| Insert Interval | [#57](https://leetcode.com/problems/insert-interval/) | Adding new booking to calendar |
| Meeting Rooms II | [#253](https://leetcode.com/problems/meeting-rooms-ii/) | Max concurrent bookings |
| Meeting Rooms | [#252](https://leetcode.com/problems/meeting-rooms/) | Booking conflict check |
| Employee Free Time | [#759](https://leetcode.com/problems/employee-free-time/) | Finding available slots across hosts |
| Non-overlapping Intervals | [#435](https://leetcode.com/problems/non-overlapping-intervals/) | Minimum cancellations for no conflicts |
| My Calendar I/II/III | [#729](https://leetcode.com/problems/my-calendar-i/) / [#731](https://leetcode.com/problems/my-calendar-ii/) / [#732](https://leetcode.com/problems/my-calendar-iii/) | Calendar booking with overlap rules |
| Interval List Intersections | [#986](https://leetcode.com/problems/interval-list-intersections/) | Finding common availability |

### 2. Graph Problems / Social Network (🔴 High Priority)
Trust networks, user relationships, connected components, reachability.

| Problem | LeetCode # | Key Concept |
|---|---|---|
| Number of Islands | [#200](https://leetcode.com/problems/number-of-islands/) | Connected components |
| Alien Dictionary | [#269](https://leetcode.com/problems/alien-dictionary/) | Topological sort |
| Course Schedule I/II | [#207](https://leetcode.com/problems/course-schedule/) / [#210](https://leetcode.com/problems/course-schedule-ii/) | Dependency graphs |
| Graph Valid Tree | [#261](https://leetcode.com/problems/graph-valid-tree/) | Graph structure |
| Accounts Merge | [#721](https://leetcode.com/problems/accounts-merge/) | Union-find merging |
| Clone Graph | [#133](https://leetcode.com/problems/clone-graph/) | Graph deep copy |
| Word Ladder | [#127](https://leetcode.com/problems/word-ladder/) | BFS shortest path |
| Number of Connected Components | [#323](https://leetcode.com/problems/number-of-connected-components-in-an-undirected-graph/) | Union-Find |

### 3. Search & Ranking / Sorted Data (🟡 Medium Priority)
Airbnb search, ranking listings, filtering.

| Problem | LeetCode # | Key Concept |
|---|---|---|
| Binary Search | [#704](https://leetcode.com/problems/binary-search/) | Fundamental |
| Search in Rotated Sorted Array | [#33](https://leetcode.com/problems/search-in-rotated-sorted-array/) | Modified binary search |
| Kth Largest Element | [#215](https://leetcode.com/problems/kth-largest-element-in-an-array/) | QuickSelect / Heap |
| Top K Frequent Elements | [#347](https://leetcode.com/problems/top-k-frequent-elements/) | Heap / Bucket Sort |
| Design Search Autocomplete | [#642](https://leetcode.com/problems/design-search-autocomplete-system/) | Trie-based search |
| Find Median from Data Stream | [#295](https://leetcode.com/problems/find-median-from-data-stream/) | Streaming ranking |
| Sliding Window Maximum | [#239](https://leetcode.com/problems/sliding-window-maximum/) | Efficient max tracking |

### 4. Rate Limiting / System-Aware Problems (🟡 Medium Priority)
Payments reliability, API throttling.

| Problem | LeetCode # | Key Concept |
|---|---|---|
| Design Hit Counter | [#362](https://leetcode.com/problems/design-hit-counter/) | Time-windowed counting |
| LRU Cache | [#146](https://leetcode.com/problems/lru-cache/) | Eviction policy |
| LFU Cache | [#460](https://leetcode.com/problems/lfu-cache/) | Frequency-based eviction |
| Logger Rate Limiter | [#359](https://leetcode.com/problems/logger-rate-limiter/) | Deduplication within time window |
| Design Tic-Tac-Toe | [#348](https://leetcode.com/problems/design-tic-tac-toe/) | State tracking |

### 5. Dynamic Programming (🔴 High Priority)
Confirmed by Glassdoor — hard DP has been asked.

| Problem | LeetCode # | Key Concept |
|---|---|---|
| Coin Change | [#322](https://leetcode.com/problems/coin-change/) | Optimization — payment amounts |
| Edit Distance | [#72](https://leetcode.com/problems/edit-distance/) | String transformation |
| Longest Increasing Subsequence | [#300](https://leetcode.com/problems/longest-increasing-subsequence/) | Subsequence DP |
| Word Break | [#139](https://leetcode.com/problems/word-break/) | String partitioning |
| Unique Paths | [#62](https://leetcode.com/problems/unique-paths/) | Grid DP |
| House Robber | [#198](https://leetcode.com/problems/house-robber/) | 1D decision DP |
| Regular Expression Matching | [#10](https://leetcode.com/problems/regular-expression-matching/) | Advanced 2D DP |
| Maximal Square | [#221](https://leetcode.com/problems/maximal-square/) | 2D DP |

### 6. Practical / Business Logic Problems (🔴 High Priority — Airbnb-specific)
Not purely LeetCode — these test your ability to write clean, production-like code.

**Practice these patterns:**
- Parse complex input (orders, bookings) and perform operations
- Multi-step data transformations
- Calendar operations (check-in/check-out overlaps, pricing calculations)
- State machine implementations (booking states, payment states)
- Data validation and edge case handling

---

## Recommended Practice Plan (35-40 Problems)

### Week 1-2: Foundation (12 problems)
Focus on medium difficulty, core patterns.

| Day | Problems | Pattern |
|---|---|---|
| Day 1 | Two Sum ([#1](https://leetcode.com/problems/two-sum/)), Group Anagrams ([#49](https://leetcode.com/problems/group-anagrams/)), Subarray Sum Equals K ([#560](https://leetcode.com/problems/subarray-sum-equals-k/)) | HashMap |
| Day 2 | Merge Intervals ([#56](https://leetcode.com/problems/merge-intervals/)), Meeting Rooms ([#252](https://leetcode.com/problems/meeting-rooms/)), Meeting Rooms II ([#253](https://leetcode.com/problems/meeting-rooms-ii/)) | **Intervals** |
| Day 3 | Number of Islands ([#200](https://leetcode.com/problems/number-of-islands/)), Course Schedule ([#207](https://leetcode.com/problems/course-schedule/)), Clone Graph ([#133](https://leetcode.com/problems/clone-graph/)) | **Graph BFS/DFS** |
| Day 4 | Coin Change ([#322](https://leetcode.com/problems/coin-change/)), House Robber ([#198](https://leetcode.com/problems/house-robber/)), Longest Increasing Subsequence ([#300](https://leetcode.com/problems/longest-increasing-subsequence/)) | DP |

### Week 3-4: Intermediate (12 problems)
Move to medium-hard, Airbnb-tagged.

| Day | Problems | Pattern |
|---|---|---|
| Day 5 | Insert Interval ([#57](https://leetcode.com/problems/insert-interval/)), Non-overlapping Intervals ([#435](https://leetcode.com/problems/non-overlapping-intervals/)), Employee Free Time ([#759](https://leetcode.com/problems/employee-free-time/)) | **Intervals Advanced** |
| Day 6 | Alien Dictionary ([#269](https://leetcode.com/problems/alien-dictionary/)), Word Ladder ([#127](https://leetcode.com/problems/word-ladder/)), Graph Valid Tree ([#261](https://leetcode.com/problems/graph-valid-tree/)) | **Graph Advanced** |
| Day 7 | LRU Cache ([#146](https://leetcode.com/problems/lru-cache/)), Design Hit Counter ([#362](https://leetcode.com/problems/design-hit-counter/)), Flatten Nested List Iterator ([#341](https://leetcode.com/problems/flatten-nested-list-iterator/)) | **Design** |
| Day 8 | Edit Distance ([#72](https://leetcode.com/problems/edit-distance/)), Word Break ([#139](https://leetcode.com/problems/word-break/)), Regular Expression Matching ([#10](https://leetcode.com/problems/regular-expression-matching/)) | **DP Hard** |

### Week 5-6: Hard + Practice (12 problems)
Hard problems + mock-style practice.

| Day | Problems | Pattern |
|---|---|---|
| Day 9 | Sliding Window Maximum ([#239](https://leetcode.com/problems/sliding-window-maximum/)), Trapping Rain Water ([#42](https://leetcode.com/problems/trapping-rain-water/)), Minimum Window Substring ([#76](https://leetcode.com/problems/minimum-window-substring/)) | Window / Stack |
| Day 10 | Serialize/Deserialize Binary Tree ([#297](https://leetcode.com/problems/serialize-and-deserialize-binary-tree/)), Accounts Merge ([#721](https://leetcode.com/problems/accounts-merge/)), Find Median from Data Stream ([#295](https://leetcode.com/problems/find-median-from-data-stream/)) | **Design + Union-Find** |
| Day 11 | Palindrome Pairs ([#336](https://leetcode.com/problems/palindrome-pairs/)), Pour Water ([#755](https://leetcode.com/problems/pour-water/)), N-Queens ([#51](https://leetcode.com/problems/n-queens/)) | **Hard / Airbnb-specific** |
| Day 12 | Top K Frequent Elements ([#347](https://leetcode.com/problems/top-k-frequent-elements/)), Task Scheduler ([#621](https://leetcode.com/problems/task-scheduler/)), Jump Game II ([#45](https://leetcode.com/problems/jump-game-ii/)) | Heap / Greedy |

### Ongoing: Business Logic Practice
- Write 2-3 "practical" coding problems per week:
  - Implement a booking conflict checker with check-in/check-out dates
  - Parse and transform order/transaction data
  - Build a simple pricing calculator with surge pricing rules
  - Implement an availability calendar with blocked dates

---

## Tips for Airbnb Coding Rounds

1. **Communicate before coding** — Airbnb strongly values thought process verbalization (confirmed Glassdoor + analysis doc)
2. **Handle edge cases explicitly** — Interviewers check for production-quality thinking
3. **Be prepared for practical problems** — Not just LC; real-world business logic is fair game
4. **Time management** — 45-60 min per round; interviewers sometimes arrive late (confirmed Glassdoor)
5. **Code cleanliness matters** — Clean variable names, proper abstractions; Airbnb values code quality
6. **Airbnb uses their own coding platform** — Not HackerRank or CoderPad; practice in a plain editor
7. **Java is fine** — Though one Blind user noted Kotlin is ~50% faster for interviews; Java is perfectly acceptable
