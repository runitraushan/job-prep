# PayPal — DSA Questions (Staff Backend Engineer)

> **Sources:** AmbitionBox (fetched), GeeksforGeeks (fetched), Glassdoor (training knowledge — login wall), LeetCode Discuss (training knowledge — login wall)
> **Last Updated:** 9 March 2026

---

## High-Priority Questions (Confirmed / Frequently Asked)

### 1. Merge Intervals
- **Difficulty:** Medium
- **Topics:** Arrays, Intervals, Sorting
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [56. Merge Intervals](https://leetcode.com/problems/merge-intervals/)
- **Notes:** One of the most commonly reported PayPal questions. Karat and onsite.

### 2. Meeting Rooms II
- **Difficulty:** Medium
- **Topics:** Intervals, Heap, Greedy
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [253. Meeting Rooms II](https://leetcode.com/problems/meeting-rooms-ii/)
- **Notes:** Min-heap approach. Asked in Karat screening.

### 3. Insert Interval
- **Difficulty:** Medium
- **Topics:** Intervals, Arrays
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [57. Insert Interval](https://leetcode.com/problems/insert-interval/)
- **Notes:** Frequently tested alongside Merge Intervals.

### 4. Longest Substring Without Repeating Characters
- **Difficulty:** Medium
- **Topics:** Sliding Window, Hash Map, String
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [3. Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/)
- **Notes:** Classic sliding window — frequently reported.

### 5. Minimum Window Substring
- **Difficulty:** Hard
- **Topics:** Sliding Window, Hash Map, String
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [76. Minimum Window Substring](https://leetcode.com/problems/minimum-window-substring/)
- **Notes:** Asked in onsite coding round.

### 6. Spiral Matrix
- **Difficulty:** Medium
- **Topics:** Arrays, Matrix, Simulation
- **Source:** AmbitionBox (Senior SE, 9 months ago), GeeksforGeeks (coding round)
- **LeetCode:** [54. Spiral Matrix](https://leetcode.com/problems/spiral-matrix/)
- **Notes:** Confirmed on multiple sources. Both as a print pattern and traversal.

### 7. Search a 2D Matrix
- **Difficulty:** Medium
- **Topics:** Binary Search, Matrix
- **Source:** AmbitionBox (MTS-1, 8 months ago)
- **LeetCode:** [74. Search a 2D Matrix](https://leetcode.com/problems/search-a-2d-matrix/)
- **Notes:** Treat matrix as flattened sorted array, binary search. O(log(m*n)).

### 8. Number of Islands
- **Difficulty:** Medium
- **Topics:** BFS, DFS, Graph, Matrix
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [200. Number of Islands](https://leetcode.com/problems/number-of-islands/)
- **Notes:** Classic BFS/DFS on grid. Multiple Glassdoor reports.

### 9. Lowest Common Ancestor of a Binary Tree
- **Difficulty:** Medium
- **Topics:** Trees, Recursion, DFS
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [236. Lowest Common Ancestor of a Binary Tree](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-tree/)
- **Notes:** Frequently asked tree problem at PayPal.

### 10. Serialize and Deserialize Binary Tree
- **Difficulty:** Hard
- **Topics:** Trees, BFS, DFS, Design
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [297. Serialize and Deserialize Binary Tree](https://leetcode.com/problems/serialize-and-deserialize-binary-tree/)
- **Notes:** Design-heavy coding problem. May appear in onsite Round 3.

---

## Medium-Priority Questions

### 11. Two Sum
- **Difficulty:** Easy
- **Topics:** Arrays, Hash Map
- **Source:** Common warm-up question
- **LeetCode:** [1. Two Sum](https://leetcode.com/problems/two-sum/)
- **Notes:** Often used as Karat warm-up. Quick 5-min problem.

### 12. Container With Most Water
- **Difficulty:** Medium
- **Topics:** Two Pointers, Arrays
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [11. Container With Most Water](https://leetcode.com/problems/container-with-most-water/)
- **Notes:** Two-pointer greedy approach.

### 13. Group Anagrams
- **Difficulty:** Medium
- **Topics:** Hash Map, String, Sorting
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [49. Group Anagrams](https://leetcode.com/problems/group-anagrams/)
- **Notes:** HashMap-based. Frequency counting pattern.

### 14. Course Schedule (Topological Sort)
- **Difficulty:** Medium
- **Topics:** Graph, BFS, Topological Sort
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [207. Course Schedule](https://leetcode.com/problems/course-schedule/)
- **Notes:** Topological sort using Kahn's algorithm (BFS). Graph question.

### 15. Palindrome Check (String)
- **Difficulty:** Easy
- **Topics:** String, Two Pointers
- **Source:** AmbitionBox (Senior SE, 9 months ago)
- **LeetCode:** [125. Valid Palindrome](https://leetcode.com/problems/valid-palindrome/)
- **Notes:** Asked as a quick coding demonstration.

### 16. "Brain Power" DP Problem
- **Difficulty:** Medium-Hard
- **Topics:** Dynamic Programming
- **Source:** Glassdoor (training knowledge), Analysis Doc
- **LeetCode:** [2140. Solving Questions With Brainpower](https://leetcode.com/problems/solving-questions-with-brainpower/)
- **Notes:** Specific DP problem reported by candidates. Review DP on arrays.

### 17. Subsets
- **Difficulty:** Medium
- **Topics:** Backtracking, Bit Manipulation
- **Source:** GeeksforGeeks (PayPal coding round)
- **LeetCode:** [78. Subsets](https://leetcode.com/problems/subsets/)
- **Notes:** Backtracking pattern. Asked in OA round.

### 18. Shared Interest / Graph Problem
- **Difficulty:** Medium-Hard
- **Topics:** Graph, Hash Map
- **Source:** GeeksforGeeks (PayPal HackerRank round)
- **Notes:** Custom problem — given nodes with shared interests, find pairs with maximum shared tags. Graph + HashMap approach.

---

## PayPal-Specific Coding Patterns

### 19. Payment Transfer Modeling
- **Difficulty:** Medium
- **Topics:** Graph, Hash Map, Design
- **Source:** Analysis Doc (PayPal-specific pattern)
- **Notes:** "Person A sends money to Person B" — model as directed graph, calculate net balances, optimize settlement. Similar to Splitwise simplify debts.

### 20. Expense Splitting / Debt Simplification
- **Difficulty:** Medium-Hard
- **Topics:** Graph, Greedy, Math
- **Source:** Glassdoor (training knowledge)
- **LeetCode:** [465. Optimal Account Balancing](https://leetcode.com/problems/optimal-account-balancing/)
- **Notes:** Directly relevant to PayPal's domain. Minimize number of transactions to settle debts.

### 21. Box Packing / Container Optimization
- **Difficulty:** Medium
- **Topics:** Greedy, Sorting, Bin Packing
- **Source:** Analysis Doc (PayPal-specific pattern)
- **Notes:** Container management / packing optimization. Greedy approach with sorting.

---

## Prep Notes

- **Karat round:** Practice on a plain text editor (no autocomplete). Budget 30 min for 1 medium problem.
- **Onsite:** Write clean, production-quality Java code. Discuss brute force first, then optimize.
- **All rounds:** Always state time and space complexity explicitly.
- **Pair programming style:** Think out loud — some rounds are collaborative.
