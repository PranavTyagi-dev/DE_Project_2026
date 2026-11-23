-- Optional Phase 5 support object for R13 on the large dataset.
-- Run after loading linkedin.profile_views and before benchmarking the
-- optimized workload. Refresh after profile-view ingestion batches.
CREATE MATERIALIZED VIEW linkedin.known_profile_viewers AS
SELECT DISTINCT viewer_id
FROM linkedin.profile_views
WHERE viewer_id IS NOT NULL;

CREATE UNIQUE INDEX known_profile_viewers_id_idx
    ON linkedin.known_profile_viewers (viewer_id);

ANALYZE linkedin.known_profile_viewers;
