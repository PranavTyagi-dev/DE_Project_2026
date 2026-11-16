# Database Schema Design

## 1. Introduction

This document explains the database schema designed for the LinkedIn Professional Networking and Jobs Database project.

The database is designed using PostgreSQL 15 or newer. It stores information about members, companies, career positions, skills, connections, invitations, job postings, applications and profile views.

The main objectives of this design are:

- Store data in a structured and organized manner.
- Maintain data accuracy using primary keys, foreign keys and constraints.
- Avoid unnecessary data duplication through normalization.
- Represent relationships between members, companies, jobs and skills.
- Support the queries required for the project.

All tables will be created inside the `linkedin` schema.

```sql
CREATE SCHEMA linkedin;
SET search_path TO linkedin;
```

## 2. Tables and Data Dictionary

The following data types are proposed based on the CSV column names. They must be checked against the actual seed data before finalizing the SQL schema.

### 2.1 cities

Stores the city information used by members, companies and jobs.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| city_id | INTEGER | PRIMARY KEY | Unique ID of each city |
| city_name | VARCHAR(100) | NOT NULL | Name of the city |
| state | VARCHAR(100) | NOT NULL | State of the city |

### 2.2 members

Stores the personal and professional information of LinkedIn members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| member_id | BIGINT | PRIMARY KEY | Unique ID of each member |
| first_name | VARCHAR(100) | NOT NULL | Member's first name |
| last_name | VARCHAR(100) | NOT NULL | Member's last name |
| headline | TEXT | NULL allowed | Professional headline |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Member's email address |
| city_id | INTEGER | FOREIGN KEY, NULL allowed | Member's city |
| industry | VARCHAR(100) | NULL allowed | Member's industry |
| is_premium | BOOLEAN | NOT NULL | Whether the member has premium access |
| open_to_work | BOOLEAN | NOT NULL | Whether the member is looking for work |
| created_at | TIMESTAMPTZ | NOT NULL | Account creation date and time |

### 2.3 companies

Stores information about companies registered on the platform.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| company_id | BIGINT | PRIMARY KEY | Unique company ID |
| company_name | VARCHAR(255) | NOT NULL | Name of the company |
| industry | VARCHAR(100) | NULL allowed | Company's industry |
| company_size | VARCHAR(50) | NULL allowed | Size of the company |
| hq_city_id | INTEGER | FOREIGN KEY, NULL allowed | Company's headquarters city |
| founded_year | SMALLINT | NULL allowed | Year the company was founded |
| website | TEXT | NULL allowed | Company's website |

### 2.4 positions

Stores the work experience and career history of members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| position_id | BIGINT | PRIMARY KEY | Unique position ID |
| member_id | BIGINT | FOREIGN KEY, NOT NULL | Member holding the position |
| company_id | BIGINT | FOREIGN KEY, NOT NULL | Company where the member worked |
| title | VARCHAR(255) | NOT NULL | Job title |
| employment_type | VARCHAR(50) | NULL allowed | Type of employment |
| start_date | DATE | NOT NULL | Starting date of the position |
| end_date | DATE | NULL allowed | Ending date; NULL may represent a current position |

### 2.5 skills

Stores the available skills on the platform.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| skill_id | INTEGER | PRIMARY KEY | Unique skill ID |
| skill_name | VARCHAR(100) | UNIQUE, NOT NULL | Name of the skill |

### 2.6 member_skills

Connects members with their skills and stores the number of endorsements.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| member_id | BIGINT | FOREIGN KEY, NOT NULL | Member ID |
| skill_id | INTEGER | FOREIGN KEY, NOT NULL | Skill ID |
| endorsements | INTEGER | NOT NULL | Number of endorsements |

The combination of `member_id` and `skill_id` is proposed as the composite primary key.

### 2.7 connections

Stores the connections between two members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| member_a | BIGINT | FOREIGN KEY, NOT NULL | First member |
| member_b | BIGINT | FOREIGN KEY, NOT NULL | Second member |
| connected_at | TIMESTAMPTZ | NOT NULL | Date and time of connection |

The combination of `member_a` and `member_b` is proposed as the composite primary key.

To store a two-way connection only once, the design uses the ordering rule `member_a < member_b`.

### 2.8 invitations

Stores connection invitations sent by members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| invitation_id | BIGINT | PRIMARY KEY | Unique invitation ID |
| sender_id | BIGINT | FOREIGN KEY, NOT NULL | Member who sent the invitation |
| recipient_id | BIGINT | FOREIGN KEY, NOT NULL | Member receiving the invitation |
| note | TEXT | NULL allowed | Optional invitation message |
| sent_at | TIMESTAMPTZ | NOT NULL | Date and time the invitation was sent |
| status | VARCHAR(30) | NOT NULL | Current invitation status |
| responded_at | TIMESTAMPTZ | NULL allowed | Date and time of response |

### 2.9 jobs

Stores job postings created by companies.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| job_id | BIGINT | PRIMARY KEY | Unique job ID |
| company_id | BIGINT | FOREIGN KEY, NOT NULL | Company posting the job |
| title | VARCHAR(255) | NOT NULL | Job title |
| city_id | INTEGER | FOREIGN KEY, NULL allowed | Job location |
| workplace_type | VARCHAR(50) | NOT NULL | Remote, hybrid or on-site type |
| employment_type | VARCHAR(50) | NOT NULL | Type of employment |
| min_experience | SMALLINT | NOT NULL | Minimum required experience |
| min_salary_lpa | NUMERIC(10,2) | NULL allowed | Minimum salary in LPA |
| max_salary_lpa | NUMERIC(10,2) | NULL allowed | Maximum salary in LPA |
| posted_at | TIMESTAMPTZ | NOT NULL | Job posting date and time |
| closes_at | TIMESTAMPTZ | NULL allowed | Job closing date and time |
| status | VARCHAR(30) | NOT NULL | Current job status |

### 2.10 job_skills

Connects jobs with the skills required for those jobs.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| job_id | BIGINT | FOREIGN KEY, NOT NULL | Job ID |
| skill_id | INTEGER | FOREIGN KEY, NOT NULL | Required skill ID |

The combination of `job_id` and `skill_id` is proposed as the composite primary key.

### 2.11 applications

Stores job applications submitted by members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| application_id | BIGINT | PRIMARY KEY | Unique application ID |
| job_id | BIGINT | FOREIGN KEY, NOT NULL | Job being applied for |
| member_id | BIGINT | FOREIGN KEY, NOT NULL | Member applying for the job |
| applied_at | TIMESTAMPTZ | NOT NULL | Application date and time |
| easy_apply | BOOLEAN | NOT NULL | Whether Easy Apply was used |
| status | VARCHAR(30) | NOT NULL | Current application status |
| status_updated_at | TIMESTAMPTZ | NOT NULL | Last status update date and time |

A combination of `job_id` and `member_id` is a proposed UNIQUE constraint to prevent a member from applying to the same job more than once. This must be verified against the CSV data.

### 2.12 profile_views

Stores profile-view activity between members.

| Column | Proposed Data Type | Constraint | Purpose |
|---|---|---|---|
| view_id | BIGINT | PRIMARY KEY | Unique profile-view ID |
| viewer_id | BIGINT | FOREIGN KEY, NULL allowed | Member who viewed the profile |
| viewed_id | BIGINT | FOREIGN KEY, NOT NULL | Member whose profile was viewed |
| viewed_at | TIMESTAMPTZ | NOT NULL | Date and time of the profile view |

`viewer_id` can be NULL when a person views a profile in private mode.

## 3. Primary Keys and Foreign Keys

Primary keys uniquely identify every record in a table. Foreign keys maintain relationships between related tables.

The proposed primary keys are:

| Table | Primary Key |
|---|---|
| cities | city_id |
| members | member_id |
| companies | company_id |
| positions | position_id |
| skills | skill_id |
| member_skills | (member_id, skill_id) |
| connections | (member_a, member_b) |
| invitations | invitation_id |
| jobs | job_id |
| job_skills | (job_id, skill_id) |
| applications | application_id |
| profile_views | view_id |

The proposed foreign-key relationships include:

- `members.city_id` references `cities.city_id`.
- `companies.hq_city_id` references `cities.city_id`.
- `positions.member_id` references `members.member_id`.
- `positions.company_id` references `companies.company_id`.
- `member_skills.member_id` references `members.member_id`.
- `member_skills.skill_id` references `skills.skill_id`.
- `connections.member_a` and `connections.member_b` reference `members.member_id`.
- `invitations.sender_id` and `invitations.recipient_id` reference `members.member_id`.
- `jobs.company_id` references `companies.company_id`.
- `jobs.city_id` references `cities.city_id`.
- `job_skills.job_id` references `jobs.job_id`.
- `job_skills.skill_id` references `skills.skill_id`.
- `applications.job_id` references `jobs.job_id`.
- `applications.member_id` references `members.member_id`.
- `profile_views.viewer_id` and `profile_views.viewed_id` reference `members.member_id`.

## 4. Relationships and Cardinalities

The database contains the following relationships:

| Relationship | Cardinality | Explanation |
|---|---|---|
| Cities – Members | One-to-Many | One city can have many members |
| Cities – Companies | One-to-Many | One city can be the headquarters of many companies |
| Cities – Jobs | One-to-Many | One city can have many job postings |
| Members – Positions | One-to-Many | One member can have multiple positions |
| Companies – Positions | One-to-Many | One company can have multiple positions |
| Members – Skills | Many-to-Many | A member can have multiple skills and a skill can belong to multiple members |
| Members – Connections | Many-to-Many | Members can connect with multiple members |
| Members – Invitations | One-to-Many | A member can send and receive multiple invitations |
| Companies – Jobs | One-to-Many | One company can post multiple jobs |
| Jobs – Skills | Many-to-Many | A job can require multiple skills |
| Members – Applications | One-to-Many | A member can apply to multiple jobs |
| Jobs – Applications | One-to-Many | A job can receive multiple applications |
| Members – Profile Views | One-to-Many | Members can view and receive multiple profile views |

## 5. Functional Dependencies

A functional dependency describes a relationship in which one attribute or a group of attributes determines another attribute.

The proposed functional dependencies are:

| Table | Functional Dependency |
|---|---|
| cities | city_id → city_name, state |
| members | member_id → all other member attributes |
| companies | company_id → all other company attributes |
| positions | position_id → all other position attributes |
| skills | skill_id → skill_name |
| member_skills | (member_id, skill_id) → endorsements |
| connections | (member_a, member_b) → connected_at |
| invitations | invitation_id → all other invitation attributes |
| jobs | job_id → all other job attributes |
| job_skills | (job_id, skill_id) → no additional non-key attributes |
| applications | application_id → all other application attributes |
| profile_views | view_id → all other profile-view attributes |

These dependencies are based on the proposed primary keys. Additional candidate keys, such as unique email addresses and skill names, will also be considered after checking the data.

## 6. Normalization

Normalization is the process of organizing database tables to reduce duplicate data and prevent insertion, deletion and update anomalies.

### First Normal Form (1NF)

All tables are designed to follow 1NF because:

- Each column stores a single value.
- Each record is uniquely identifiable.
- There are no repeating groups or multiple values stored in a single column.

For example, members and their skills are stored separately in `members`, `skills` and `member_skills` instead of storing multiple skills in one member record.

### Second Normal Form (2NF)

All tables are designed to follow 2NF because:

- They first satisfy 1NF.
- Non-key attributes depend on the complete candidate key.
- Tables with composite primary keys do not have partial dependencies.

For example, in `member_skills`, endorsements depend on the combination of `member_id` and `skill_id`, not on either column individually.

### Third Normal Form (3NF)

All tables are designed to follow 3NF because:

- They satisfy 2NF.
- Non-key attributes do not depend on other non-key attributes.
- Information about separate entities is stored in separate tables.

For example, city names are stored in the `cities` table rather than repeatedly storing city details in the `members` table.

### Boyce-Codd Normal Form (BCNF)

The proposed design aims to satisfy BCNF because every determinant in the listed functional dependencies is a candidate key.

The final BCNF conclusion will be confirmed after checking all candidate keys and functional dependencies in the actual data.

## 7. Derived and Redundant Attributes

Some attributes may contain information that can also be obtained from other tables.

### Current company of a member

A member's current company can be obtained from the `positions` table by finding the position where `end_date IS NULL`.

Therefore, storing the current company separately in the `members` table would create unnecessary duplication.

### Member headline

The `headline` column in the `members` table may describe the member's current professional role. However, it is not necessarily identical to the title in the `positions` table.

A headline can be written or updated independently, so it is retained as a separate attribute.

## 8. Constraints and Business Rules

The following checks are planned for the database. Their final expressions and allowed values must be verified against the CSV data.

1. Member email addresses must be unique.
2. Skill names must be unique.
3. A member cannot connect with themselves.
4. `member_a` must be smaller than `member_b` in the connections table.
5. A member cannot send an invitation to themselves.
6. A member cannot view their own profile.
7. Position end dates must not be earlier than their start dates.
8. Endorsement counts must not be negative.
9. Job minimum experience must not be negative.
10. Maximum salary must not be less than minimum salary when both are present.
11. Minimum salary must not be negative when present.
12. Maximum salary must not be negative when present.
13. Job closing time must not be earlier than posting time when a closing time exists.
14. A member should not apply to the same job more than once.
15. A pending invitation should not have a response timestamp.
16. A job's workplace type and employment type must use allowed values.

The exact allowed values and final constraints will be confirmed by inspecting the seed data.

## 9. Referential Integrity and Delete Rules

Foreign keys will be used to ensure that related records refer to existing records.

The proposed delete-rule approach is:

- Use `ON DELETE CASCADE` for dependent records such as `member_skills` and `job_skills`.
- Use `ON DELETE CASCADE` for records that have no independent meaning after their parent is deleted, where appropriate.
- Use `ON DELETE RESTRICT` for important parent records such as companies, members and jobs when deleting them could remove important history.
- Use `ON DELETE SET NULL` for optional references such as a member's city, a company's headquarters city, a job's city or a private profile-view viewer, where appropriate.

The final rules will be selected based on the business meaning of each relationship.

## 10. Data Loading and Integrity Verification

The database will be loaded using the 12 CSV files supplied with the project.

The tables will be loaded in an order that satisfies foreign-key dependencies:

1. cities
2. members
3. companies
4. skills
5. positions
6. member_skills
7. connections
8. invitations
9. jobs
10. job_skills
11. applications
12. profile_views

After loading, the following checks will be performed:

- Verify that the row count of every table matches the supplied CSV row count.
- Check that foreign-key references are valid.
- Check that there are no duplicate primary keys.
- Check that connections do not contain self-connections.
- Check that position dates and salary values follow the business rules.
- Check that accepted invitations and their corresponding connections are consistent.

### Expected CSV Row Counts

| Table | Expected Rows |
|---|---:|
| cities | 10 |
| members | 40,000 |
| companies | 2,000 |
| positions | 99,940 |
| skills | 72 |
| member_skills | 212,417 |
| connections | 219,966 |
| invitations | 60,000 |
| jobs | 15,000 |
| job_skills | 65,719 |
| applications | 149,984 |
| profile_views | 199,996 |

### Integrity Check Results

**To be completed after loading the seed data.**

| Check | Result |
|---|---|
| Row counts match the supplied CSV files | Pending |
| Foreign-key integrity | Pending |
| Duplicate primary-key check | Pending |
| Self-connection check | Pending |
| Position date validation | Pending |
| Salary validation | Pending |

No integrity-check result is claimed until the SQL scripts have been executed.

## 11. Conclusion

The proposed database design separates the major entities of the LinkedIn platform into individual tables and connects them through primary keys and foreign keys.

The design uses normalization to reduce unnecessary duplication and constraints to maintain data consistency. The schema will be finalized after inspecting the seed data, loading all 12 CSV files and verifying that the constraints accept the supplied records.

This database will serve as the foundation for the later phases of query benchmarking, indexing, query optimization and scalability testing.