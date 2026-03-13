# Soft Suave — ML Concepts Solutions — P2 (🟢 Lower Priority)

> **Role:** AIML Engineer | **Language:** Python | **Date:** 12 March 2026
> **Total Questions:** 1 | **Study Time:** 15 minutes

---

### Q56. What is the Central Limit Theorem? Why does it matter in ML?

**Answer:**

**Statement:** Regardless of the original population distribution, the **sampling distribution of the sample mean** approaches a normal distribution as sample size increases (typically n ≥ 30).

$$\bar{X} \sim \mathcal{N}\left(\mu, \frac{\sigma^2}{n}\right)$$

Where:
- $\mu$ = population mean
- $\sigma^2$ = population variance
- $n$ = sample size

**Analogy:** Imagine rolling a die (uniform distribution, not normal at all). If you roll it 50 times and take the average, that average will be close to 3.5. Repeat this experiment 1000 times — the 1000 averages will form a bell curve centered at 3.5. That's CLT.

**Why it matters in ML:**

| Application | How CLT Is Used |
|---|---|
| **A/B testing** | Justify using t-tests/z-tests even if the underlying metric isn't normally distributed |
| **Confidence intervals** | Calculate confidence intervals for model metrics (accuracy, F1) across cross-validation folds |
| **Bootstrap sampling** | Estimate parameter uncertainty by resampling — CLT guarantees the bootstrap mean converges to the true mean |
| **Mini-batch SGD** | The average gradient over a mini-batch approximates the true gradient — CLT ensures this approximation improves with batch size |
| **Feature aggregations** | When aggregating user-level features (average transaction amount), the aggregate is approximately normal |

**Practical example:**

```python
import numpy as np

# Original: exponential distribution (very skewed, not normal)
population = np.random.exponential(scale=2, size=100000)

# Take many samples of size 50, compute their means
sample_means = [np.random.choice(population, 50).mean() for _ in range(1000)]

# sample_means will be approximately normally distributed
# even though the original data is exponential
print(f"Mean of sample means: {np.mean(sample_means):.2f}")  # ≈ 2.0
print(f"Std of sample means:  {np.std(sample_means):.2f}")   # ≈ 2/√50 ≈ 0.28
```

**Key caveat:** CLT requires independent samples. If your data has autocorrelation (time series), the effective sample size is smaller than the actual count, and CLT convergence is slower.

---

## Quick Revision Cheatsheet — P2

| # | Question | Key Answer (1 line) |
|---|---|---|
| 56 | Central Limit Theorem | Sample means → normal distribution as n→∞; justifies t-tests, CIs, bootstrap, mini-batch SGD |
