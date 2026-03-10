# Complexity Cheatsheet — Common Patterns

> Quick reference for time/space complexity of common DSA patterns.
> Use this when analyzing complexity of a solution — pattern-match, don't derive from scratch.

---

## Sorting-Based

| Pattern | Time | Space | Example |
|---|---|---|---|
| Sort + linear scan | O(n log n) | O(1) or O(n) | Merge Intervals, Two Sum (sorted) |
| Sort + two pointers | O(n log n) | O(1) | 3Sum, Container With Most Water |
| Sort + binary search | O(n log n) | O(1) | Search in rotated array (after sort conceptually) |

## Two Pointers

| Pattern | Time | Space | Example |
|---|---|---|---|
| Opposite ends | O(n) | O(1) | Two Sum II, Valid Palindrome |
| Same direction (slow/fast) | O(n) | O(1) | Remove Duplicates, Linked List Cycle |
| Sliding window (fixed) | O(n) | O(1) | Max Sum Subarray of size K |
| Sliding window (variable) | O(n) | O(k) where k = charset | Longest Substring Without Repeating |

## HashMap / HashSet

| Pattern | Time | Space | Example |
|---|---|---|---|
| Frequency counting | O(n) | O(n) | Two Sum, Group Anagrams |
| Seen set | O(n) | O(n) | Contains Duplicate |
| Index tracking | O(n) | O(n) | First Unique Character |

## Binary Search

| Pattern | Time | Space | Example |
|---|---|---|---|
| Classic binary search | O(log n) | O(1) | Search in sorted array |
| Binary search on answer | O(n log M) where M = answer range | O(1) | Koko Eating Bananas, Capacity to Ship |
| Search in 2D matrix | O(log(m×n)) | O(1) | Search a 2D Matrix |

## Trees

| Pattern | Time | Space | Example |
|---|---|---|---|
| DFS (recursive) | O(n) | O(h) where h = height | Max Depth, Path Sum |
| BFS (level order) | O(n) | O(w) where w = max width | Level Order Traversal |
| BST search | O(h) | O(1) iterative / O(h) recursive | Validate BST, LCA in BST |

## Graphs

| Pattern | Time | Space | Example |
|---|---|---|---|
| BFS/DFS traversal | O(V + E) | O(V) | Number of Islands, Clone Graph |
| Topological sort (Kahn's) | O(V + E) | O(V) | Course Schedule |
| Dijkstra's | O((V + E) log V) | O(V) | Network Delay Time |
| Union-Find | O(n × α(n)) ≈ O(n) | O(n) | Number of Connected Components |

## Dynamic Programming

| Pattern | Time | Space | Example |
|---|---|---|---|
| 1D DP | O(n) | O(n) or O(1) | Climbing Stairs, House Robber |
| 2D DP | O(m × n) | O(m × n) or O(n) | Longest Common Subsequence, Edit Distance |
| DP on intervals | O(n²) or O(n³) | O(n²) | Burst Balloons, Matrix Chain |
| Knapsack | O(n × W) | O(n × W) or O(W) | 0/1 Knapsack, Coin Change |
| Bitmask DP | O(2^n × n) | O(2^n) | TSP, Partition Equal Subset (small n) |

## Heap / Priority Queue

| Pattern | Time | Space | Example |
|---|---|---|---|
| Top K elements | O(n log k) | O(k) | Kth Largest, Top K Frequent |
| Merge K sorted | O(N log k) where N = total elements | O(k) | Merge K Sorted Lists |
| Streaming median | O(n log n) total | O(n) | Find Median from Data Stream |

## Stack

| Pattern | Time | Space | Example |
|---|---|---|---|
| Monotonic stack | O(n) | O(n) | Next Greater Element, Largest Rectangle |
| Balanced parentheses | O(n) | O(n) | Valid Parentheses |
| Expression evaluation | O(n) | O(n) | Basic Calculator |

## String

| Pattern | Time | Space | Example |
|---|---|---|---|
| KMP pattern matching | O(n + m) | O(m) | strStr() |
| Trie operations | O(L) per operation where L = word length | O(total chars) | Implement Trie, Word Search II |
| Rabin-Karp | O(n) average, O(nm) worst | O(1) | Repeated DNA Sequences |

## Backtracking

| Pattern | Time | Space | Example |
|---|---|---|---|
| Subsets | O(2^n) | O(n) | Subsets, Combination Sum |
| Permutations | O(n!) | O(n) | Permutations |
| Board/grid search | O(m × n × 4^L) | O(L) | Word Search |

---

## Quick Rules

- **Sorting always adds O(n log n)** — if your approach sorts, the floor is O(n log n)
- **HashMap lookup is O(1) amortized** — but adds O(n) space
- **Recursive DFS space = tree height** — O(log n) balanced, O(n) worst (skewed)
- **BFS space = max width of level** — for binary tree, up to O(n/2)
- **DP can often reduce space** — if you only look at previous row, go from O(m×n) to O(n)
- **"For each element, do O(log n) work"** = O(n log n) total
- **"For each element, do O(n) work"** = O(n²) total — look for optimization
