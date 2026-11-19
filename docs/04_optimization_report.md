# Optimization Report

## Benchmark method and result

PostgreSQL 16.16, project seed dataset, `EXPLAIN (ANALYZE, BUFFERS)`, three runs per query. Write queries were executed in transactions and rolled back by the benchmark script. The optimized indexes were applied from `sql/05_indexes.sql`; the workload was `sql/06_optimized_queries.sql`. Raw plans are in `benchmarks/results/optimized/`.

The sum of query averages fell from **529.160 ms** to **192.118 ms** (63.7% lower). Per-query averages vary; queries that still scan broad portions of the data are noted below.

## Before and after averages

| Query | Before (ms) | After (ms) | Improvement | Plan issue and optimization | Result check |
|---|---:|---:|---:|---|---|
| R01 | 5.328 | 0.037 | 99.3% | Member PK lookup plus indexed current-position lookup. | Unchanged SQL |
| R02 | 3.152 | 0.030 | 99.0% | Composite member/start index removes position scan and sorts matching rows. | Unchanged SQL |
| R03 | 5.217 | 0.044 | 99.2% | Split OR into two indexed edge lookups (member_a PK and member_b index). | Verified equivalent |
| R04 | 7.954 | 0.063 | 99.2% | Same two-sided indexed connection lookups for both members. | Verified equivalent |
| R05 | 26.548 | 0.268 | 99.0% | Reverse-edge index supports neighbor expansion; plan still scans mutual adjacency candidates. | Unchanged SQL |
| R06 | 5.497 | 0.141 | 97.4% | Partial open-job indexes narrow city/remote posting candidates; title trigram support. | Unchanged SQL |
| R07 | 4.929 | 4.393 | 10.9% | Job-skill join still scans job_skills; current indexes do not make this plan selective. | Unchanged SQL |
| R08 | 0.235 | 0.063 | 73.2% | Job/status index makes applicant grouping an index-only lookup. | Unchanged SQL |
| R09 | 4.045 | 0.066 | 98.4% | Member/applied index narrows the applicant history before joins. | Unchanged SQL |
| R10 | 2.325 | 0.031 | 98.7% | Partial recipient/sent index finds pending invitations in order. | Unchanged SQL |
| R11 | 4.492 | 0.060 | 98.7% | Viewed_id/time covering index narrows and covers profile-view records. | Unchanged SQL |
| R12 | 4.903 | 0.199 | 95.9% | Company-name and partial current-position indexes narrow employee search. | Unchanged SQL |
| R13 | 19.137 | 18.534 | 3.2% | NOT EXISTS fixes NULL semantics; scans remain cheaper at this dataset size. | Corrected NULL behavior; 6,513 intended members |
| R14 | 8.490 | 3.430 | 59.6% | Partial hired/status-updated index narrows relevant applications. | Unchanged SQL |
| R15 | 8.012 | 8.492 | -6.0% | Most rows qualify; sequential scans remain appropriate for annual aggregation. | Unchanged SQL |
| R16 | 1.991 | 1.579 | 20.7% | Most jobs qualify; sequential scan remains appropriate for grouped salary report. | Unchanged SQL |
| R17 | 33.983 | 34.143 | -0.5% | Member/start index supplies window partition order; whole-history window remains expensive. | Unchanged SQL |
| R18 | 8.072 | 3.035 | 62.4% | Skill/endorsement index aids SQL member ranking; member filters still scan/join. | Unchanged SQL |
| R19 | 198.690 | 5.669 | 97.1% | Company/status and job/status indexes reduce repeated report lookups substantially. | Unchanged SQL |
| R20 | 6.212 | 6.323 | -1.8% | Date cast predicate remains unsargable; sequential scan persists. | Unchanged SQL |
| R21 | 78.136 | 43.376 | 44.5% | Skill/endorsement index supplies rank order; still processes all member skills. | Unchanged SQL |
| R22 | 30.707 | 8.562 | 72.1% | Applied-at index supports newest-first pagination and avoids full sort. | Unchanged SQL |
| R23 | 8.926 | 0.025 | 99.7% | lower(email) expression index matches case-insensitive lookup. | Unchanged SQL |
| R24 | 8.760 | 9.019 | -3.0% | 2026 invitations remain a broad slice; sequential scans are cheaper. | Unchanged SQL |
| R25 | 30.901 | 31.537 | -2.1% | Member/start index orders position window input; whole-history window remains expensive. | Unchanged SQL |
| W01 | 0.842 | 0.697 | 17.2% | Single unique-conflict insert; index additions have little impact. | Unchanged SQL |
| W02 | 2.551 | 0.280 | 89.0% | Partial pending recipient index finds oldest pending invitation quickly. | Unchanged SQL |
| W03 | 2.712 | 0.383 | 85.9% | Partial pending recipient index finds invitation for connection insert quickly. | Unchanged SQL |
| W04 | 2.894 | 2.026 | 30.0% | Partial open-close-date index targets only expired open jobs. | Unchanged SQL |
| W05 | 3.519 | 9.613 | -173.2% | Company, job/status and partial old-application indexes support update joins. | Unchanged SQL |

Improvement is `(before − after) / before × 100`; negative values mean the measured optimized average was slower.

## Largest plan changes

| Query | Before plan observation | Optimized plan observation |
|---|---|---|
| R19 | ->  Seq Scan on companies c  (cost=0.00..213982.85 rows=200 width=43) (actual time=1.788..197.308 rows=200.00 loops=1); ->  Seq Scan on jobs j  (cost=0.00..457.00 rows=1 width=0) (actual time=0.526..0.604 rows=0.82 loops=200); ->  Seq Scan on jobs j_1  (cost=0.00..419.50 rows=8 width=8) (actual time=0.060..0.352 rows=6.97 loops=200); ->   | ->  Seq Scan on companies c  (cost=0.00..46839.11 rows=200 width=43) (actual time=0.606..6.005 rows=200 loops=1); ->  Index Only Scan using idx_jobs_company_status on jobs j  (cost=0.29..8.30 rows=1 width=0) (actual time=0.001..0.001 rows=1 loops=200); ->  Bitmap Heap Scan on jobs j_1  (cost=4.35..32.33 rows=8 width=8) (actual time=0.001. |
| R22 | ->  Seq Scan on applications  (cost=0.00..3043.84 rows=149984 width=40) (actual time=0.006..7.575 rows=149984.00 loops=1); ->  Seq Scan on applications  (cost=0.00..3043.84 rows=149984 width=40) (actual time=0.005..6.829 rows=149984.00 loops=1); ->  Seq Scan on applications  (cost=0.00..3043.84 rows=149984 width=40) (actual time=0.005..6. | ->  Index Scan Backward using idx_applications_applied_at on applications  (cost=0.42..5453.18 rows=149984 width=40) (actual time=0.014..8.654 rows=100025 loops=1); ->  Index Scan Backward using idx_applications_applied_at on applications  (cost=0.42..5453.18 rows=149984 width=40) (actual time=0.008..5.977 rows=100025 loops=1); ->  Index  |
| R03 | ->  Parallel Seq Scan on connections c  (cost=0.00..3396.90 rows=9 width=16) (actual time=1.790..3.905 rows=7.00 loops=2); ->  Parallel Seq Scan on connections c  (cost=0.00..3396.90 rows=9 width=16) (actual time=1.793..3.581 rows=7.00 loops=2); ->  Parallel Seq Scan on connections c  (cost=0.00..3396.90 rows=9 width=16) (actual time=1.78 | ->  Index Scan using pk_connections on connections  (cost=0.42..22.58 rows=9 width=16) (actual time=0.017..0.019 rows=14 loops=1); ->  Index Only Scan using idx_connections_member_b on connections connections_1  (cost=0.42..29.88 rows=7 width=16) (actual time=0.008..0.008 rows=0 loops=1); ->  Index Scan using pk_connections on connections |
| R05 | ->  Parallel Seq Scan on connections  (cost=0.00..3396.90 rows=9 width=8) (actual time=2.295..3.398 rows=7.00 loops=2); ->  CTE Scan on my_conn mc  (cost=0.00..0.30 rows=15 width=8) (actual time=0.820..0.821 rows=14.00 loops=1); ->  Bitmap Heap Scan on connections c  (cost=1881.13..1936.96 rows=8 width=16) (actual time=1.858..1.861 rows=9 | ->  Bitmap Heap Scan on connections  (cost=8.97..64.66 rows=15 width=8) (actual time=0.019..0.021 rows=14 loops=1); ->  Bitmap Index Scan on pk_connections  (cost=0.00..4.49 rows=9 width=0) (actual time=0.012..0.012 rows=14 loops=1); ->  Bitmap Index Scan on idx_connections_member_b  (cost=0.00..4.47 rows=7 width=0) (actual time=0.004..0. |
| R23 | Seq Scan on members  (cost=0.00..1256.00 rows=200 width=21) (actual time=0.241..8.964 rows=1.00 loops=1); Seq Scan on members  (cost=0.00..1256.00 rows=200 width=21) (actual time=0.240..9.024 rows=1.00 loops=1); Seq Scan on members  (cost=0.00..1256.00 rows=200 width=21) (actual time=0.239..8.744 rows=1.00 loops=1) | Bitmap Heap Scan on members  (cost=9.96..440.13 rows=200 width=20) (actual time=0.013..0.013 rows=1 loops=1); ->  Bitmap Index Scan on idx_members_lower_email  (cost=0.00..9.91 rows=200 width=0) (actual time=0.011..0.011 rows=1 loops=1); Bitmap Heap Scan on members  (cost=9.96..440.13 rows=200 width=20) (actual time=0.006..0.006 rows=1 lo |

## Query rewrites and correctness

- R03 and R04 replace `OR` predicates over the two ends of undirected connections with separate `UNION ALL` lookups, allowing the primary-key index on `member_a` and the new `member_b` index to serve their respective branches. Bidirectional `EXCEPT ALL` checks reported **0 differences** for both queries.
- R13 replaces `NOT IN` with `NOT EXISTS`. The source set includes private-mode profile views where `viewer_id` is NULL. A NULL in `NOT IN` makes every unmatched comparison UNKNOWN, so the baseline query incorrectly returned no rows. The corrected query returns **6,513** members who have never viewed anyone’s profile. This is an intentional correction to the erroneous baseline result.

## Index choices

The index file documents the served queries and ordering. Key choices include two-sided connection indexes; partial indexes for open jobs and pending invitations; a trigram GIN index for the contains-pattern job-title search; reverse skill indexes; application indexes for member, job and time lookups; profile-view recipient/time and non-NULL viewer indexes; and an expression index on `lower(email)`. The small seed dataset and broad reporting filters still lead PostgreSQL to choose sequential scans for some analytics, which is expected.
