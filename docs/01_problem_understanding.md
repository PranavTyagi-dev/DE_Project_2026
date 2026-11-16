# Problem Understanding

## Project: LinkedIn Professional Networking & Jobs Database

### 1. Introduction

LinkedIn is a professional networking and job marketplace platform. Members can create profiles, add their work experience and skills, connect with other members, send invitations, search for jobs and apply for jobs. Companies can post job openings and recruiters can manage applications through different stages.

The purpose of this project is to design a properly structured PostgreSQL database for these activities and improve its performance using database optimization techniques.

### 2. Business Problems

#### P1: Slow Profiles and Network Page
- **Business need:** Members should be able to view their profiles, work experience, connections and mutual connections quickly.
- **Stakeholder:** Members / Job seekers.
- **Classification:** Customer-facing / Real-time.
- **Related queries:** R01, R02, R03, R04.

#### P2: Slow People You May Know and Invitations
- **Business need:** The platform should quickly identify potential connections and process connection invitations.
- **Stakeholder:** Growth team and Members.
- **Classification:** Customer-facing / Real-time.
- **Related queries:** R05, R10, W02, W03.

#### P3: Slow Job Search and Recommendations
- **Business need:** Members should be able to search for relevant jobs, receive job recommendations and apply without delays.
- **Stakeholder:** Job seekers.
- **Classification:** Customer-facing / Real-time.
- **Related queries:** R06, R07, R09, W01.

#### P4: Slow Recruiter Operations
- **Business need:** Recruiters should be able to search candidates, view applications, manage the recruitment pipeline and perform bulk updates efficiently.
- **Stakeholder:** Recruiters.
- **Classification:** Customer-facing / Interactive.
- **Related queries:** R08, R18, W05.

#### P5: Profile Views and Engagement Issues
- **Business need:** Members should be able to see who viewed their profiles, while private-mode viewers should remain anonymous. The platform should also identify members who have never viewed anyone's profile.
- **Stakeholder:** Members and Engagement team.
- **Classification:** Customer-facing / Real-time.
- **Related queries:** R11, R13.

#### P6: Slow Talent Insights and Reports
- **Business need:** The platform should efficiently generate reports about company tenure, hiring time, skill demand, salaries, talent movement and career breaks.
- **Stakeholder:** Talent insights team and Company page administrators.
- **Classification:** Reporting / Analytics.
- **Related queries:** R12, R14, R15, R16, R17, R25.

#### P7: Slow Platform Reports and Job Maintenance
- **Business need:** Platform reports and job maintenance operations should run efficiently even when the amount of data grows significantly. The database should support an expected 20x growth.
- **Stakeholder:** Platform team and Company page administrators.
- **Classification:** Reporting / Analytics and Batch Processing.
- **Related queries:** R19, R20, R21, R22, R23, R24, W04.

### 3. Assumptions

1. Every member has a unique member ID and email address.
2. Each company has a unique company ID.
3. A member can have multiple work positions and skills.
4. A connection between two members is stored only once.
5. Connection invitations have different statuses such as PENDING, ACCEPTED and IGNORED.
6. A member cannot apply to the same job more than once.
7. A job can require multiple skills, and a skill can be required by multiple jobs.
8. A profile view can have a NULL viewer ID when the viewer uses private mode.
9. A current work position has a NULL end date.
10. Job salary information may be incomplete, and some jobs may not have a city.
11. The database will use PostgreSQL 15 or newer.
12. The seed CSV files provided by the teacher are the source of data for designing and testing the database.

### 4. Conclusion

The project focuses on designing a correct and normalized relational database and improving its performance. The database will first be designed using the provided seed data. After that, the given SQL queries will be tested and optimized using indexing, query rewriting and other database optimization techniques. Finally, scalability will be tested using a dataset that is approximately 20 times larger.