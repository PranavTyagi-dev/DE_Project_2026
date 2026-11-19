SET search_path TO linkedin;

-- R01, R02, R12: locate a member/company's current or recent positions without scanning all history.
CREATE INDEX IF NOT EXISTS idx_positions_member_start ON positions (member_id, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_positions_current_company ON positions (company_id, member_id, start_date) WHERE end_date IS NULL;
CREATE INDEX IF NOT EXISTS idx_companies_name ON companies (company_name);

-- R03–R05, W03: each side of the undirected edge has its own lookup path; PK covers member_a.
CREATE INDEX IF NOT EXISTS idx_connections_member_b ON connections (member_b, member_a) INCLUDE (connected_at);

-- R06: narrow open job search by city and posting time; trigram index supports the contains-pattern title search.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_jobs_open_city_posted ON jobs (city_id, posted_at DESC) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_jobs_open_title_trgm ON jobs USING gin (title gin_trgm_ops) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_jobs_open_remote_posted ON jobs (posted_at DESC) WHERE status = 'OPEN' AND workplace_type = 'REMOTE';

-- R07, R15, R18, R21: reverse skill lookup and endorsement ranking; current PK starts with member_id.
CREATE INDEX IF NOT EXISTS idx_job_skills_skill_job ON job_skills (skill_id, job_id);
CREATE INDEX IF NOT EXISTS idx_member_skills_skill_endorsements ON member_skills (skill_id, endorsements DESC, member_id);

-- R08, R09, R14, R19, R20, R22, W05: application lookup, time range, ordering and job updates.
CREATE INDEX IF NOT EXISTS idx_applications_job_status ON applications (job_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_member_applied ON applications (member_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at ON applications (applied_at);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at_desc ON applications (applied_at DESC) INCLUDE (application_id, job_id, member_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_hired_status_updated ON applications (status_updated_at, job_id) WHERE status = 'HIRED';
CREATE INDEX IF NOT EXISTS idx_applications_applied_old ON applications (job_id, applied_at) WHERE status = 'APPLIED';

-- R10, W02, W03, R24: recipient/status queue and date-filtered invitation reporting.
CREATE INDEX IF NOT EXISTS idx_invitations_pending_recipient_sent ON invitations (recipient_id, sent_at DESC) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_invitations_pending_recipient_id ON invitations (recipient_id, invitation_id) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_invitations_sent_at ON invitations (sent_at, sender_id) INCLUDE (status);

-- R11, R13: profile-view recipient/time lookup and viewer existence test; NULL private viewers are excluded.
CREATE INDEX IF NOT EXISTS idx_profile_views_viewed_time ON profile_views (viewed_id, viewed_at DESC) INCLUDE (viewer_id);
CREATE INDEX IF NOT EXISTS idx_profile_views_known_viewer ON profile_views (viewer_id) WHERE viewer_id IS NOT NULL;

-- R19, W04: company/status job lookup and closing-date maintenance.
CREATE INDEX IF NOT EXISTS idx_jobs_company_status ON jobs (company_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_open_closes_at ON jobs (closes_at) WHERE status = 'OPEN';

-- R23: exact expression used by the case-insensitive sign-in predicate.
CREATE INDEX IF NOT EXISTS idx_members_lower_email ON members (lower(email));
