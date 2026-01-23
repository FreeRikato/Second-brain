Source:
1. https://unstop.com/hackathons/enigma-iit-bhu-1625255

Todo:
# ✅ Phase 0 — Registration + Setup (Today → Jan 30)

### 0.1 Registration & rules safety

* [x] Register on Unstop (done ✅)
* [ ] Join Discord (CodeFest’26 server)
* [ ] Save organizer email + spam-check rules
* [ ] Read rules: **no sharing code/data**, no discussing solutions

### 0.2 Create your “war room”

* [ ] Make 1 folder: `enigma_2026/`
* [ ] Create subfolders:
  * `data/`
  * `notebooks/`
  * `src/`
  * `models/`
  * `submissions/`
  * `logs/`
* [ ] Create a private Git repo (or local git) with:
  * `.gitignore` for `/data`, `/models`
  * clean commit history (helps rollback)

### 0.3 Your baseline ML pipeline (prebuilt)

You want **instant execution** once the dataset drops.

* [ ] Data loader template (CSV/Parquet flexible)
* [ ] Auto feature handling:
  * missing values
  * categorical encoding (one-hot / target encoding)
  * scaling (if needed)
* [ ] Cross-validation template
* [ ] Metrics wrapper (plug any scoring metric)
* [ ] Model training presets ready:
  * LightGBM / XGBoost / CatBoost (whichever you’re fastest with)
  * fast baseline neural net (optional)
* [ ] “Submission generator” script:
  * `train.py` → saves model
  * `predict.py` → creates `submission.csv`
* [ ] Basic experiment tracker (even simple):
  * save params + score + timestamp in `logs/exp.csv`

### 0.4 Hardware + speed checklist

Dynamic leaderboard + tie-breaker means **speed matters**.
* [ ] Ensure you can train quickly (GPU optional)
* [ ] Keep 1 “fast model” that trains in < 5 min
* [ ] Keep 1 “strong model” that trains in 20–45 min

### 0.5 Submission discipline (this wins comps)

* [ ] Prepare naming format:
  * `sub_001_baseline.csv`
  * `sub_002_lgb_opt.csv`
* [ ] Keep a text file: `leaderboard_notes.md`
  * submission name → score → key change

---

# 🚀 Phase 1 — First 2 Hours of Contest (Jan 31 00:00 → 02:00)

Your goal is: **get on the board FAST**, then iterate safely.

### 1.1 Read the problem statement like a judge

* [ ] Identify task type: regression / classification / ranking / time series
* [ ] Look for:
  * leakage traps (IDs, timestamps, “future” info)
  * multiple files (train/test/sample_sub)
  * evaluation metric (AUC/F1/RMSE/LogLoss/etc.)
  * constraints (submission limit / file format)

### 1.2 Make the first valid submission in < 60 minutes

* [ ] Load data
* [ ] Minimal cleaning
* [ ] Train a baseline model (even dumb)
* [ ] Generate submission file correctly
* [ ] Submit immediately ✅

**Why:** tie-breaker rewards early submits *when scores tie*.

### 1.3 Confirm pipeline is correct

* [ ] Verify no row mismatch / sorting mistake
* [ ] Ensure test prediction order matches required IDs
* [ ] Save your best “working baseline commit”

---

# 🧠 Phase 2 — Day 1: Win by Out-Iterating Everyone (Jan 31)

### 2.1 EDA in “competition mode”

Do only what improves score.

* [ ] Column types summary (cat/num/text/date)
* [ ] Missing value patterns
* [ ] Target imbalance / distribution
* [ ] Data size + cardinality (high-card cats?)

### 2.2 Build 3 strong “tracks”

You need at least one that hits hard.

**Track A (fast + strong): Gradient boosting**
* [ ] LightGBM / CatBoost training
* [ ] Target encoding (for high-card categoricals)
* [ ] Robust CV (StratifiedKFold if classification)

**Track B (feature engineering)**
* [ ] Date parts if timestamp exists
* [ ] Groupby aggregates if IDs/entities exist
* [ ] Interaction features only if obvious

**Track C (leakage hunt)**
* [ ] Check if train/test share entities
* [ ] Check if any column directly encodes target
* [ ] Look for near-perfect correlation columns

### 2.3 CV strategy (most people mess this up)

* [ ] Choose CV that matches real evaluation:
  * Time-based split if temporal
  * GroupKFold if groups/IDs repeat
* [ ] Keep a stable validation seed
* [ ] Don’t overfit to public LB too early

### 2.4 Submission cadence

* [ ] Submit only meaningful improvements
* [ ] Keep a “safe best” model untouched
* [ ] Don’t burn time micro-tuning early

---

# ⚙️ Phase 3 — Day 2: Leaderboard Climb + Stability (Feb 1)

### 3.1 Hyperparameter tightening (high ROI)

* [ ] Bayesian/Optuna tuning *only on a good baseline*
* [ ] Early stopping, max depth, learning rate sweeps
* [ ] Regularization tuning (prevents LB shake)

### 3.2 Ensembling (solo-friendly, huge payoff)

* [ ] Train 3–8 diverse models:
  * different seeds
  * slightly different params
  * different feature sets
* [ ] Blend predictions (simple average)
* [ ] Try weighted blend if 1 model dominates

### 3.3 Reduce variance (to survive private eval)

* [ ] Prefer consistent CV improvements over lucky LB jumps
* [ ] Remove suspicious/leaky features unless sure
* [ ] Ensure model generalizes

### 3.4 Keep a “submission bank”

* [ ] Best CV score model
* [ ] Best public LB model
* [ ] Most stable model (least variance across folds)
* [ ] Best ensemble

---

# 🏁 Phase 4 — Final Day: Lock the Win (Feb 2)

This is where winners separate themselves.

### 4.1 Morning: exploit remaining gains

* [ ] Try 1–2 new feature ideas max
* [ ] Try 1 new model family max (don’t go crazy)
* [ ] Re-run ensemble cleanly

### 4.2 6 hours before deadline: stop gambling

* [ ] Freeze your “champion candidate”
* [ ] Re-train cleanly from scratch (reproducible)
* [ ] Generate final submission carefully

### 4.3 Final 60 minutes: submit smart

Because tie-breaker favors earlier file time for equal score:

* [ ] Submit your best final **well before** last minute
* [ ] Keep 1 backup submission ready
* [ ] Do NOT do last-minute risky experiments

---

# 🧩 Bulletproof Winning Checklist (Quick)

If you do only these, you’ll likely place high:

✅ **Submit within first hour**
✅ **Correct CV strategy (time/group aware if needed)**
✅ **Strong baseline (LGBM/CatBoost) + solid features**
✅ **Ensemble 3–8 models**
✅ **Avoid leakage + reduce LB overfitting**
✅ **Final submission early (tie-break advantage)**

---

# 📌 Solo Dev “Operating System” During the Hackathon

### Every 90 minutes repeat:

* [ ] Train → validate → log → submit (if worthy)
* [ ] Write 1-line takeaway in `leaderboard_notes.md`
* [ ] Keep the best model artifact saved

### Avoid these score-killers:

* ❌ random feature spam
* ❌ tuning before baseline is strong
* ❌ trusting public leaderboard too much
* ❌ last-minute submission chaos
* ❌ breaking your pipeline without a checkpoint

---

# 🔥 If you want a true unfair advantage

Do this **before the contest starts**:

* [ ] Build an “AutoML-lite loop” script:
  * trains multiple models
  * logs CV
  * saves top-k predictions
  * blends and outputs best submission automatically

This alone can outpace 80% of teams.

---
