# Merge Intervals

> **Company:** PayPal  
> **Difficulty:** Medium  
> **Topics:** Arrays, Intervals, Sorting  
> **LeetCode:** [56. Merge Intervals](https://leetcode.com/problems/merge-intervals/)

---

## 1. Problem Statement

Given an array of `intervals` where `intervals[i] = [start_i, end_i]`, merge all overlapping intervals, and return an array of the non-overlapping intervals that cover all the intervals in the input.

**Constraints:**
- `1 <= intervals.length <= 10^4`
- `intervals[i].length == 2`
- `0 <= start_i <= end_i <= 10^4`

**Examples:**

```
Input:  [[1,3],[2,6],[8,10],[15,18]]
Output: [[1,6],[8,10],[15,18]]
Explanation: [1,3] and [2,6] overlap → merged to [1,6]

Input:  [[1,4],[4,5]]
Output: [[1,5]]
Explanation: [1,4] and [4,5] are considered overlapping (share boundary)
```

---

## 2. Approach

### Brute Force — Compare Every Pair

Check every pair of intervals for overlap. If they overlap, merge them and restart. Repeat until no more merges happen.

**Why it's bad:** O(n³) — for each pair, you merge and rescan. Wasteful.

### Optimized — Sort + Linear Merge

**Intuition:** If we sort intervals by start time, overlapping intervals will be adjacent. We only need to check if the current interval overlaps with the last merged interval.

**How it works:**
1. Sort by `start` time
2. Start with the first interval as "current"
3. For each subsequent interval:
   - If it overlaps with current (`start <= current.end`), extend current: `current.end = max(current.end, end)`
   - If no overlap, push current to result and start a new current
4. Don't forget to push the last current

**Why sorting works:** After sorting, if interval B doesn't overlap with A, then no interval after B can overlap with A either (they all start even later). So we only need one pass.

---

## 3. Complexity Analysis

| Approach | Time | Space | Notes |
|---|---|---|---|
| Brute Force | O(n³) | O(n) | Compare all pairs, rescan on merge |
| **Sort + Merge** | **O(n log n)** | **O(n)** | Sorting dominates. Merge is O(n) linear scan. Output list takes O(n) space. |

**Pattern match:** This is a classic **sort + greedy** pattern. The sorting step gives structure that enables a single-pass solution.

---

## 4. Java Code

```java
import java.util.*;

public class MergeIntervals {

    // Time: O(n log n), Space: O(n)
    public int[][] merge(int[][] intervals) {
        if (intervals.length <= 1) {
            return intervals;
        }

        // Sort by start time. If starts equal, sort by end time.
        Arrays.sort(intervals, (a, b) -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);

        List<int[]> merged = new ArrayList<>();
        int[] current = intervals[0];
        merged.add(current);

        for (int i = 1; i < intervals.length; i++) {
            if (intervals[i][0] <= current[1]) {
                // Overlapping — extend the current interval
                current[1] = Math.max(current[1], intervals[i][1]);
            } else {
                // No overlap — start a new interval
                current = intervals[i];
                merged.add(current);
            }
        }

        return merged.toArray(new int[merged.size()][]);
    }
}
```

**Why `current[1] = Math.max(...)`?** Because the second interval might be completely inside the first one (e.g., `[1,10]` and `[2,5]`). Taking max ensures we keep the larger end.

**Why add `current` to list before modifying?** Because `current` is a reference to the array. When we modify `current[1]`, the list entry also updates. This is intentional — avoids needing a separate update step.

---

## 5. Dry Run

**Input:** `[[1,3],[2,6],[8,10],[15,18]]`

**After sort:** `[[1,3],[2,6],[8,10],[15,18]]` (already sorted)

| Step | Current Interval | Next Interval | Overlap? | Action | Merged List |
|---|---|---|---|---|---|
| Init | `[1,3]` | — | — | Add to list | `[[1,3]]` |
| i=1 | `[1,3]` | `[2,6]` | ✅ (2 ≤ 3) | Extend: `[1, max(3,6)] = [1,6]` | `[[1,6]]` |
| i=2 | `[1,6]` | `[8,10]` | ❌ (8 > 6) | New interval | `[[1,6],[8,10]]` |
| i=3 | `[8,10]` | `[15,18]` | ❌ (15 > 10) | New interval | `[[1,6],[8,10],[15,18]]` |

**Output:** `[[1,6],[8,10],[15,18]]` ✅

---

## 6. Edge Cases

| Edge Case | Input | Expected Output | How Code Handles It |
|---|---|---|---|
| Single interval | `[[1,3]]` | `[[1,3]]` | Early return (`length <= 1`) |
| No overlap | `[[1,2],[3,4],[5,6]]` | `[[1,2],[3,4],[5,6]]` | Each interval becomes its own entry |
| All overlap | `[[1,10],[2,5],[3,7]]` | `[[1,10]]` | Max keeps extending end |
| Touching boundaries | `[[1,4],[4,5]]` | `[[1,5]]` | `<=` check includes boundary touch |
| Nested interval | `[[1,10],[2,5]]` | `[[1,10]]` | Max(10,5) = 10, no change |
| Unsorted input | `[[3,4],[1,2]]` | `[[1,2],[3,4]]` | Sort step fixes order |

---

## 7. Related Problems

| Problem | Similarity | LeetCode |
|---|---|---|
| Insert Interval | Same merge logic, different trigger | [57](https://leetcode.com/problems/insert-interval/) |
| Meeting Rooms II | Intervals + heap for counting overlaps | [253](https://leetcode.com/problems/meeting-rooms-ii/) |
| Non-overlapping Intervals | Greedy interval removal | [435](https://leetcode.com/problems/non-overlapping-intervals/) |
| Interval List Intersections | Two-pointer on sorted intervals | [986](https://leetcode.com/problems/interval-list-intersections/) |

---

## 8. Interview Tips

- **Start by asking:** "Are the intervals sorted? Can they be empty? Are boundaries inclusive?" — shows you clarify before coding
- **Explain sorting first:** "If I sort by start time, overlapping intervals become adjacent — that lets me do a single pass"
- **Mention the `max` subtlety:** Most candidates forget this. Explicitly say "I need max for the end because one interval might contain another"
- **Complexity last:** State it clearly — "O(n log n) for sorting, O(n) for the merge pass, so O(n log n) overall. Space is O(n) for the output list."
