-- Phase 5 design for RANGE partitioning applications by applied_at.
-- Run in a scratch database/schema first: this creates a parallel table and
-- does not replace the populated linkedin.applications table.
-- The range bounds are half-open. Extend these yearly partitions as needed;
-- the DEFAULT partition prevents inserts from failing between maintenance runs.

SET search_path TO linkedin;

CREATE TABLE applications_partitioned (
    application_id BIGINT NOT NULL,
    job_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status VARCHAR(30) NOT NULL,
    status_updated_at TIMESTAMPTZ NOT NULL,

    -- PostgreSQL requires every UNIQUE/PRIMARY KEY on a partitioned table to
    -- include the partition key. application_id alone cannot be globally
    -- constrained unique with this RANGE layout.
    CONSTRAINT applications_partitioned_pk PRIMARY KEY (application_id, applied_at),
    CONSTRAINT applications_partitioned_job_member_uq UNIQUE (job_id, member_id, applied_at),
    CONSTRAINT applications_partitioned_job_fk FOREIGN KEY (job_id)
        REFERENCES jobs(job_id) ON DELETE CASCADE,
    CONSTRAINT applications_partitioned_member_fk FOREIGN KEY (member_id)
        REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT applications_partitioned_status_ck CHECK (
        status IN ('APPLIED','VIEWED','SHORTLISTED','INTERVIEW','OFFER','HIRED','REJECTED','WITHDRAWN')
    ),
    CONSTRAINT applications_partitioned_dates_ck CHECK (status_updated_at >= applied_at)
) PARTITION BY RANGE (applied_at);

CREATE TABLE applications_2025 PARTITION OF applications_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');
CREATE TABLE applications_2026 PARTITION OF applications_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');
CREATE TABLE applications_2027 PARTITION OF applications_partitioned
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');
CREATE TABLE applications_default PARTITION OF applications_partitioned DEFAULT;

-- Support member history, job pipeline queries, and status/time analytics.
CREATE INDEX applications_partitioned_member_time_idx
    ON applications_partitioned (member_id, applied_at DESC);
CREATE INDEX applications_partitioned_job_status_idx
    ON applications_partitioned (job_id, status);
CREATE INDEX applications_partitioned_status_updated_idx
    ON applications_partitioned (status_updated_at, job_id)
    WHERE status = 'HIRED';

-- Example migration after checking row counts and constraints in a test copy:
-- INSERT INTO applications_partitioned
-- SELECT application_id, job_id, member_id, applied_at, easy_apply, status, status_updated_at
-- FROM applications;
-- Compare counts and validate application_id uniqueness before cutover.
-- Do not simply swap tables if other objects or application code rely on the
-- old single-column application_id primary key: retain a global ID registry
-- (or use IDs that encode a partition and verify globally at write time).

-- Partition pruning evidence to capture on the loaded large database:
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT count(*) FROM applications_partitioned
-- WHERE applied_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
--   AND applied_at <  TIMESTAMPTZ '2026-07-01 00:00:00+05:30';
