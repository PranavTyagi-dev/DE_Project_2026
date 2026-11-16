\set ON_ERROR_STOP on
SET search_path TO linkedin;
BEGIN;


\copy linkedin.cities (city_id, city_name, state) FROM 'seed_data/cities.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.members (member_id, first_name, last_name, headline, email, city_id, industry, is_premium, open_to_work, created_at) FROM 'seed_data/members.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.companies (company_id, company_name, industry, company_size, hq_city_id, founded_year, website) FROM 'seed_data/companies.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.skills (skill_id, skill_name) FROM 'seed_data/skills.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.positions (position_id, member_id, company_id, title, employment_type, start_date, end_date) FROM 'seed_data/positions.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.member_skills (member_id, skill_id, endorsements) FROM 'seed_data/member_skills.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.connections (member_a, member_b, connected_at) FROM 'seed_data/connections.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.invitations (invitation_id, sender_id, recipient_id, note, sent_at, status, responded_at) FROM 'seed_data/invitations.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.jobs (job_id, company_id, title, city_id, workplace_type, employment_type, min_experience, min_salary_lpa, max_salary_lpa, posted_at, closes_at, status) FROM 'seed_data/jobs.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.job_skills (job_id, skill_id) FROM 'seed_data/job_skills.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.applications (application_id, job_id, member_id, applied_at, easy_apply, status, status_updated_at) FROM 'seed_data/applications.csv' WITH (FORMAT CSV, HEADER TRUE);

\copy linkedin.profile_views (view_id, viewer_id, viewed_id, viewed_at) FROM 'seed_data/profile_views.csv' WITH (FORMAT CSV, HEADER TRUE);

ANALYZE linkedin.cities;
ANALYZE linkedin.members;
ANALYZE linkedin.companies;
ANALYZE linkedin.skills;
ANALYZE linkedin.positions;
ANALYZE linkedin.member_skills;
ANALYZE linkedin.connections;
ANALYZE linkedin.invitations;
ANALYZE linkedin.jobs;
ANALYZE linkedin.job_skills;
ANALYZE linkedin.applications;
ANALYZE linkedin.profile_views;
COMMIT;

SELECT 'cities' AS table_name, COUNT(*) AS total_rows FROM linkedin.cities
UNION ALL
SELECT 'members', COUNT(*) FROM linkedin.members
UNION ALL
SELECT 'companies', COUNT(*) FROM linkedin.companies
UNION ALL
SELECT 'positions', COUNT(*) FROM linkedin.positions
UNION ALL
SELECT 'skills', COUNT(*) FROM linkedin.skills
UNION ALL
SELECT 'member_skills', COUNT(*) FROM linkedin.member_skills
UNION ALL
SELECT 'connections', COUNT(*) FROM linkedin.connections
UNION ALL
SELECT 'invitations', COUNT(*) FROM linkedin.invitations
UNION ALL
SELECT 'jobs', COUNT(*) FROM linkedin.jobs
UNION ALL
SELECT 'job_skills', COUNT(*) FROM linkedin.job_skills
UNION ALL
SELECT 'applications', COUNT(*) FROM linkedin.applications
UNION ALL
SELECT 'profile_views', COUNT(*) FROM linkedin.profile_views;
