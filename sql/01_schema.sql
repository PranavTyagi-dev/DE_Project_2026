-- 1. Create schema
CREATE SCHEMA IF NOT EXISTS linkedin;

SET search_path TO linkedin;

-- 2. CITIES

CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,

    CONSTRAINT chk_city_name
        CHECK (TRIM(city_name) <> ''),

    CONSTRAINT chk_city_state
        CHECK (TRIM(state) <> '')
);

-- 3. MEMBERS

CREATE TABLE members (
    member_id BIGINT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    headline TEXT,
    email VARCHAR(255) NOT NULL UNIQUE,
    city_id INTEGER,
    industry VARCHAR(100),
    is_premium BOOLEAN NOT NULL,
    open_to_work BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_members_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_member_first_name
        CHECK (TRIM(first_name) <> ''),

    CONSTRAINT chk_member_last_name
        CHECK (TRIM(last_name) <> ''),

    CONSTRAINT chk_member_email
        CHECK (TRIM(email) <> '')
);

-- 4. COMPANIES

CREATE TABLE companies (
    company_id BIGINT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    company_size VARCHAR(20),
    hq_city_id INTEGER,
    founded_year SMALLINT,
    website TEXT,

    CONSTRAINT fk_companies_city
        FOREIGN KEY (hq_city_id)
        REFERENCES cities(city_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_company_name
        CHECK (TRIM(company_name) <> ''),

    CONSTRAINT chk_company_size
        CHECK (
            company_size IS NULL
            OR company_size IN (
                '1-10',
                '11-50',
                '51-200',
                '201-1000',
                '1001-5000',
                '5001-10000',
                '10001+'
            )
        ),

    CONSTRAINT chk_founded_year
        CHECK (
            founded_year IS NULL
            OR founded_year BETWEEN 1800 AND 2100
        )
);

-- 5. SKILLS

CREATE TABLE skills (
    skill_id INTEGER PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,

    CONSTRAINT chk_skill_name
        CHECK (TRIM(skill_name) <> '')
);

-- 6. POSITIONS

CREATE TABLE positions (
    position_id BIGINT PRIMARY KEY,
    member_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    employment_type VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,

    CONSTRAINT fk_positions_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_positions_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_position_title
        CHECK (TRIM(title) <> ''),

    CONSTRAINT chk_position_employment_type
        CHECK (
            employment_type IS NULL
            OR employment_type IN (
                'FULL_TIME',
                'CONTRACT',
                'INTERNSHIP'
            )
        ),

    CONSTRAINT chk_position_dates
        CHECK (
            end_date IS NULL
            OR end_date >= start_date
        )
);

-- 7. MEMBER SKILLS

CREATE TABLE member_skills (
    member_id BIGINT NOT NULL,
    skill_id INTEGER NOT NULL,
    endorsements INTEGER NOT NULL,

    CONSTRAINT pk_member_skills
        PRIMARY KEY (member_id, skill_id),

    CONSTRAINT fk_member_skills_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_member_skills_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_endorsements
        CHECK (endorsements >= 0)
);

-- 8. CONNECTIONS

CREATE TABLE connections (
    member_a BIGINT NOT NULL,
    member_b BIGINT NOT NULL,
    connected_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_connections
        PRIMARY KEY (member_a, member_b),

    CONSTRAINT fk_connections_member_a
        FOREIGN KEY (member_a)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_connections_member_b
        FOREIGN KEY (member_b)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_connection_order
        CHECK (member_a < member_b)
);

-- 9. INVITATIONS

CREATE TABLE invitations (
    invitation_id BIGINT PRIMARY KEY,
    sender_id BIGINT NOT NULL,
    recipient_id BIGINT NOT NULL,
    note TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(30) NOT NULL,
    responded_at TIMESTAMPTZ,

    CONSTRAINT fk_invitations_sender
        FOREIGN KEY (sender_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_invitations_recipient
        FOREIGN KEY (recipient_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_invitation_not_self
        CHECK (sender_id <> recipient_id),

    CONSTRAINT chk_invitation_status
        CHECK (
            status IN (
                'ACCEPTED',
                'IGNORED',
                'PENDING',
                'WITHDRAWN'
            )
        ),

    CONSTRAINT chk_invitation_response_time
        CHECK (
            responded_at IS NULL
            OR responded_at >= sent_at
        ),

    CONSTRAINT chk_invitation_pending
        CHECK (
            (status = 'PENDING' AND responded_at IS NULL)
            OR
            (status <> 'PENDING' AND responded_at IS NOT NULL)
        )
);

-- 10. JOBS
 

CREATE TABLE jobs (
    job_id BIGINT PRIMARY KEY,
    company_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    city_id INTEGER,
    workplace_type VARCHAR(50) NOT NULL,
    employment_type VARCHAR(50) NOT NULL,
    min_experience SMALLINT NOT NULL,
    min_salary_lpa NUMERIC(10,2),
    max_salary_lpa NUMERIC(10,2),
    posted_at TIMESTAMPTZ NOT NULL,
    closes_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL,

    CONSTRAINT fk_jobs_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_jobs_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_job_title
        CHECK (TRIM(title) <> ''),

    CONSTRAINT chk_workplace_type
        CHECK (
            workplace_type IN (
                'ONSITE',
                'HYBRID',
                'REMOTE'
            )
        ),

    CONSTRAINT chk_job_employment_type
        CHECK (
            employment_type IN (
                'FULL_TIME',
                'CONTRACT',
                'INTERNSHIP'
            )
        ),

    CONSTRAINT chk_min_experience
        CHECK (min_experience >= 0),

    CONSTRAINT chk_min_salary
        CHECK (
            min_salary_lpa IS NULL
            OR min_salary_lpa >= 0
        ),

    CONSTRAINT chk_max_salary
        CHECK (
            max_salary_lpa IS NULL
            OR max_salary_lpa >= 0
        ),

    CONSTRAINT chk_salary_range
        CHECK (
            min_salary_lpa IS NULL
            OR max_salary_lpa IS NULL
            OR max_salary_lpa >= min_salary_lpa
        ),

    CONSTRAINT chk_job_dates
        CHECK (
            closes_at IS NULL
            OR closes_at >= posted_at
        ),

    CONSTRAINT chk_job_status
        CHECK (status IN ('OPEN', 'CLOSED')),

    CONSTRAINT chk_remote_city
        CHECK (
            (workplace_type = 'REMOTE' AND city_id IS NULL)
            OR
            (workplace_type <> 'REMOTE' AND city_id IS NOT NULL)
        )
);


 
-- 11. JOB SKILLS
 

CREATE TABLE job_skills (
    job_id BIGINT NOT NULL,
    skill_id INTEGER NOT NULL,

    CONSTRAINT pk_job_skills
        PRIMARY KEY (job_id, skill_id),

    CONSTRAINT fk_job_skills_job
        FOREIGN KEY (job_id)
        REFERENCES jobs(job_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_job_skills_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
        ON DELETE CASCADE
);


 
-- 12. APPLICATIONS
 

CREATE TABLE applications (
    application_id BIGINT PRIMARY KEY,
    job_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status VARCHAR(30) NOT NULL,
    status_updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_applications_job
        FOREIGN KEY (job_id)
        REFERENCES jobs(job_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_applications_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_job_member_application
        UNIQUE (job_id, member_id),

    CONSTRAINT chk_application_status
        CHECK (
            status IN (
                'APPLIED',
                'VIEWED',
                'SHORTLISTED',
                'INTERVIEW',
                'OFFER',
                'HIRED',
                'REJECTED',
                'WITHDRAWN'
            )
        ),

    CONSTRAINT chk_application_dates
        CHECK (status_updated_at >= applied_at)
);


 
-- 13. PROFILE VIEWS
 

CREATE TABLE profile_views (
    view_id BIGINT PRIMARY KEY,
    viewer_id BIGINT,
    viewed_id BIGINT NOT NULL,
    viewed_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_profile_views_viewer
        FOREIGN KEY (viewer_id)
        REFERENCES members(member_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_profile_views_viewed
        FOREIGN KEY (viewed_id)
        REFERENCES members(member_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_profile_view_not_self
        CHECK (
            viewer_id IS NULL
            OR viewer_id <> viewed_id
        )
);
 
