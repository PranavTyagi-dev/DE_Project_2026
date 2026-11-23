# Phase 5: Scalability report

## Method and dataset

Loaded all 12 supplied `large_data/` CSVs into a fresh `linkedin_large_2026` database, ran `sql/01_schema.sql`, `sql/02_load_data.sql` (using the extracted large-data folder), `sql/05_indexes.sql`, and `ANALYZE`. The loader's row-count check passed: 800,000 members, 40,000 companies, 300,000 jobs, 1,998,792 positions, 4,249,459 member skills, 4,399,965 connections, 1,199,999 invitations, 1,315,149 job skills, 2,999,984 applications, and 3,999,994 profile views (plus 10 cities and 72 skills).

Benchmarked the final optimized workload with PostgreSQL 18.6 on the local machine using `EXPLAIN (ANALYZE, BUFFERS)`, three runs per query, and `benchmarks/run_benchmark.sh`. Writes ran within `BEGIN`/`ROLLBACK`. Final raw plans are in `benchmarks/results/large/<ID>.txt`; `summary.csv` contains the arithmetic mean, median, min, max, and scan nodes. The seed averages below are from the previously committed optimized summary, whose report identifies PostgreSQL 16.16. Since the PostgreSQL versions differ, growth ratios are directional comparisons, not a controlled data-volume-only comparison.

R13 uses the Phase 5 support object in `sql/07_large_scale_support.sql`; it was created after loading and before this final benchmark. This materialized distinct-viewer list is refreshed after each profile-view ingestion batch with `REFRESH MATERIALIZED VIEW CONCURRENTLY linkedin.known_profile_viewers;` (the unique index required for concurrent refresh is created by the support script).

## Results

Targets follow the README: member-facing <5 ms; interactive/search <250 ms; analytics <5,000 ms; W04 <1,000 ms. All 30 queries were run three times. Times below are average milliseconds; scan nodes and exact per-run results are in the corresponding raw plan and summary files.

| Query | Optimized seed (ms) | Optimized large (ms) | Growth | Target | Result |
|---|---:|---:|---:|---:|---|
| R01 | 0.037 | 0.149 | 4.03× | <5 ms | Met |
| R02 | 0.030 | 0.135 | 4.50× | <5 ms | Met |
| R03 | 0.044 | 0.225 | 5.11× | <5 ms | Met |
| R04 | 0.063 | 0.198 | 3.14× | <5 ms | Met |
| R05 | 0.268 | 7.549 | 28.17× | <250 ms | Met |
| R06 | 0.141 | 3.524 | 24.99× | <250 ms | Met |
| R07 | 4.393 | 26.297 | 5.99× | <250 ms | Met |
| R08 | 0.063 | 0.145 | 2.30× | <5 ms | Met |
| R09 | 0.066 | 0.157 | 2.38× | <5 ms | Met |
| R10 | 0.031 | 0.098 | 3.16× | <5 ms | Met |
| R11 | 0.060 | 0.212 | 3.53× | <5 ms | Met |
| R12 | 0.199 | 0.458 | 2.30× | <250 ms | Met |
| R13 | 18.534¹ | 89.507 | —¹ | <250 ms | Met after scale fix |
| R14 | 3.430 | 122.260 | 35.64× | <5,000 ms | Met |
| R15 | 8.492 | 70.583 | 8.31× | <5,000 ms | Met |
| R16 | 1.579 | 14.245 | 9.02× | <5,000 ms | Met |
| R17 | 34.143 | 684.378 | 20.04× | <5,000 ms | Met |
| R18 | 3.035 | 22.713 | 7.48× | <250 ms | Met |
| R19 | 5.669 | 633.471 | 111.74× | <5,000 ms | Met |
| R20 | 6.323 | 74.217 | 11.74× | <5,000 ms | Met |
| R21 | 43.376 | 438.661 | 10.11× | <5,000 ms | Met |
| R22 | 8.562 | 9.932 | 1.16× | <250 ms | Met |
| R23 | 0.025 | 0.140 | 5.60× | <5 ms | Met |
| R24 | 9.019 | 84.228 | 9.34× | <5,000 ms | Met |
| R25 | 31.537 | 651.255 | 20.65× | <5,000 ms | Met |
| W01 | 0.697 | 1.310 | 1.88× | <5 ms | Met |
| W02 | 0.280 | 0.685 | 2.45× | <5 ms | Met |
| W03 | 0.383 | 0.631 | 1.65× | <5 ms | Met |
| W04 | 2.026 | 63.200 | 31.19× | <1,000 ms | Met |
| W05 | 9.613 | 20.610 | 2.14× | <250 ms | Met |
| **Sum of query averages** | **192.118** | **3,021.173** | — | — | — |

The final workload meets every listed latency target. The sum is descriptive only; concurrent product workload and queueing are not represented by this serial benchmark.

## Growth analysis and scale behavior

- **Stayed comparatively stable (under 5×):** R01, R02, R04, R08–R13, R22, W01–W03, W05. Selective key lookups and small outputs remain bounded by index traversal and matching rows. R13 is stable after reducing its input from all view events to one row per known viewer.
- **Grew with broader scans or aggregates (roughly 5×–30×):** R03, R05–R07, R15–R18, R20–R21, R24–R25. These process larger graph neighborhoods, larger yearly slices, or most rows in a window/aggregate. Their measured averages stay within the interactive and analytics budgets.
- **Grew more than 30×:** R14, R19, W04. R14 considers the much larger job/application relation for hired candidates. R19 executes correlated subplans for each of 4,000 IT Services companies; its large-data plan shows about 4,000 executions of the June-application subplan and roughly 29,355 application index searches. It remains below the 5-second report target, but pre-aggregating applications by company/job would avoid the repeated work if volume or concurrency rises. W04 updates expired jobs across a 300,000-row jobs table; it remains below 1 second.

These ratios also include cache state, PostgreSQL-version, and machine-load effects: the Phase 4 seed report identifies PostgreSQL 16.16, while this run used PostgreSQL 18.6. They should not be interpreted as pure scaling exponents.

¹ The seed R13 figure predates the materialized-view scale fix, so its growth ratio is intentionally omitted.

## Scale-only issue found and fixed: R13

Before the fix, large-data R13 averaged **266.385 ms**, just above its 250 ms target. The before plan (`benchmarks/results/large/R13.before_scale_fix.txt`) used a parallel hash anti-join over 3,999,994 profile-view events and 800,000 members. It spilled to temporary files (about 13,700 temp blocks read and written per run) and scanned the full profile-view heap. `idx_profile_views_known_viewer` existed, but the event table still had to be reduced to distinct viewer identities for the anti-join.

Added `linkedin.known_profile_viewers`, a materialized distinct set, in `sql/07_large_scale_support.sql`, and changed only the R13 subquery in `sql/06_optimized_queries.sql` to probe that set. The final plan scans 800,000 members and 669,687 distinct viewers rather than four million events; it averages **89.507 ms**. A bidirectional `EXCEPT ALL` check found 130,313 rows from each version and zero differences. Final three-run plans are in `R13.txt`.

## Storage

Measured after applying the same schema and optimization indexes to local seed and large databases on PostgreSQL 18.6. The large total includes the R13 materialized view. Relation totals are heap plus indexes; database totals include database-level overhead.

| Dataset | Database size | Table/materialized-view heap | Indexes | Relation total |
|---|---:|---:|---:|---:|
| Seed (149,984 applications) | 172 MB | 70 MB | 94 MB | 164 MB |
| Large (2,999,984 applications) | 3,256 MB | 1,357 MB | 1,883 MB | 3,240 MB |

Largest large-data relations: applications 840 MB total (235 MB heap, 606 MB indexes); connections 522 MB (219/302 MB); profile_views 499 MB (223/276 MB); member_skills 435 MB (180/256 MB); positions 298 MB (169/129 MB). These are the current nonpartitioned benchmark tables. The temporary partition test table was dropped before these size measurements.

## Partitioning design and pruning evidence

`sql/08_partitioning.sql` defines yearly RANGE partitions on `applications.applied_at` plus a default partition. This aligns with June/date-range analytics (R19/R20), time-based retention, and archival. On a populated test copy of all 2,999,984 applications, the June 2026 `EXPLAIN (ANALYZE, BUFFERS)` scanned only `applications_2026`; the other yearly/default partitions were pruned. The plan completed in **17.133 ms** for the June range (164,835 rows), showing real pruning. The test copy was dropped afterward; normal workload timings above use the original nonpartitioned table, allowing a fair before-migration baseline.

PostgreSQL requires every primary key or unique constraint on a partitioned table to include the partition key. Thus the existing global `PRIMARY KEY (application_id)` and `UNIQUE (job_id, member_id)` cannot be preserved unchanged with RANGE partitioning by `applied_at`. The sample uses `(application_id, applied_at)` and `(job_id, member_id, applied_at)`, which do not guarantee global uniqueness of the original keys. Before cutover, retain global ID uniqueness through an ID registry or partition-encoded ID strategy, and enforce the one-application-per-job/member rule in a global registry or write service. The file creates a parallel table and does not automatically replace production `applications`.

## Sharding, replicas, caching, and maintenance

- **Sharding:** Member sharding would localize profile and member-application reads, but an undirected connection spans two members. R03 needs a two-sided fan-out or a connection copy on each endpoint's shard; R05 needs cross-shard neighborhood expansion and mutual-count aggregation. Company and platform-wide reports also cross shards. If sharding becomes necessary, duplicate edges by endpoint and make writes idempotent, or keep network edges in a dedicated graph store.
- **Replicas and cache:** Stale-tolerant reporting queries R14–R17, R19–R21, R24–R25 can use a read replica or refreshed summaries. Route writes W01–W05 to the primary. Reads requiring immediate read-after-write consistency should also use the primary or a lag-aware route. Cache reference data and reports only with an explicit freshness policy.
- **Maintenance:** Vacuum and analyze active application partitions after bulk loads and monitor dead tuples under updates. Detach/archive old partitions according to retention policy. Refresh `known_profile_viewers` after profile-view ingestion; refresh reporting summaries after their source data changes. Tune autovacuum from measured churn and vacuum duration.

## Conclusion

The loaded large dataset meets the README latency targets after the R13 scale-specific summary fix. RANGE partitioning on application time prunes to the relevant yearly partition in the populated test. Before calling the platform ready for 100×, benchmark partitioned writes and queries under concurrent load, solve global uniqueness for partitioned application keys, and reassess R19's repeated subplan as volume and company count grow.
