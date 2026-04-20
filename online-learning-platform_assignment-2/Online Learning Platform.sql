-- Online Learning Platform — Assignment 2
-- Re-runnable script: IF NOT EXISTS + TRUNCATE + CASCADE


-- DATABASE & SCHEMA

CREATE DATABASE online_learning;

-- Connect to online_learning in DBeaver before running the rest


-- TABLES

-- Users: stores learner accounts; email validated with LIKE pattern
CREATE TABLE IF NOT EXISTS users (
    user_id    SERIAL       PRIMARY KEY,
    last_name  VARCHAR(50)  NOT NULL,
    first_name VARCHAR(50)  NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE
                            CHECK (email LIKE '%@%')
);

-- Instructors: separate entity from users; rating defaults to 0.00 for new instructors
CREATE TABLE IF NOT EXISTS instructors (
    instructor_id   SERIAL       PRIMARY KEY,
    bio             TEXT,
    experience_area VARCHAR(100),
    rating          DECIMAL(3,2) DEFAULT 0.00
                                 CHECK (rating >= 0.00)
);

-- Courses: linked to one instructor; price defaults to 0.00 for free courses
CREATE TABLE IF NOT EXISTS courses (
    course_id     SERIAL        PRIMARY KEY,
    instructor_id INT           NOT NULL UNIQUE,
    description   TEXT,
    price         DECIMAL(10,2) DEFAULT 0.00
                                CHECK (price >= 0),
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id) REFERENCES instructors (instructor_id)
);

-- Enrollments: tracks which user enrolled in which course; date must be after 2026-01-01
CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    course_id     INT    NOT NULL,
    user_id       INT    NOT NULL UNIQUE,
    enroll_date   DATE   CHECK (enroll_date > '2026-01-01'),
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id),
    CONSTRAINT fk_enrollments_user
        FOREIGN KEY (user_id)   REFERENCES users (user_id)
);

-- Progress: tracks completion percentage per user per course; value must be 0–100
CREATE TABLE IF NOT EXISTS progress (
    progress_id        SERIAL PRIMARY KEY,
    user_id            INT    NOT NULL,
    course_id          INT    NOT NULL,
    completion_percent INT    NOT NULL
                              CHECK (completion_percent BETWEEN 0 AND 100),
    CONSTRAINT fk_progress_user
        FOREIGN KEY (user_id)   REFERENCES users (user_id),
    CONSTRAINT fk_progress_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
);

-- Feedback: one entry per user per course; rating restricted to 1–5
CREATE TABLE IF NOT EXISTS feedback (
    feedback_id SERIAL PRIMARY KEY,
    user_id     INT    NOT NULL UNIQUE,
    course_id   INT    NOT NULL UNIQUE,
    rating      INT    CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    CONSTRAINT fk_feedback_user
        FOREIGN KEY (user_id)   REFERENCES users (user_id),
    CONSTRAINT fk_feedback_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
);

-- Certifications: issued on course completion; issue_date must be after 2026-01-01
CREATE TABLE IF NOT EXISTS certifications (
    certificate_id SERIAL PRIMARY KEY,
    user_id        INT    NOT NULL UNIQUE,
    course_id      INT    NOT NULL UNIQUE,
    issue_date     DATE   CHECK (issue_date > '2026-01-01'),
    CONSTRAINT fk_certifications_user
        FOREIGN KEY (user_id)   REFERENCES users (user_id),
    CONSTRAINT fk_certifications_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
);

-- Groups: study or cohort groups with unique names
CREATE TABLE IF NOT EXISTS groups (
    group_id     SERIAL       PRIMARY KEY,
    group_name   VARCHAR(100) NOT NULL UNIQUE,
    created_date DATE
);

-- GroupUsers: junction table linking groups and users
CREATE TABLE IF NOT EXISTS group_users (
    group_id    INT  NOT NULL,
    user_id     INT  NOT NULL UNIQUE,
    joined_date DATE,
    PRIMARY KEY (group_id, user_id),
    CONSTRAINT fk_groupusers_group
        FOREIGN KEY (group_id) REFERENCES groups (group_id),
    CONSTRAINT fk_groupusers_user
        FOREIGN KEY (user_id)  REFERENCES users (user_id)
);

-- GroupCourses: junction table linking groups and courses
CREATE TABLE IF NOT EXISTS group_courses (
    group_id      INT  NOT NULL,
    course_id     INT  NOT NULL UNIQUE,
    assigned_date DATE,
    PRIMARY KEY (group_id, course_id),
    CONSTRAINT fk_groupcourses_group
        FOREIGN KEY (group_id)  REFERENCES groups (group_id),
    CONSTRAINT fk_groupcourses_course
        FOREIGN KEY (course_id) REFERENCES courses (course_id)
);


-- ALTER TABLE

-- email was VARCHAR(100); some SSO providers issue longer addresses
ALTER TABLE users
    ALTER COLUMN email TYPE VARCHAR(150);

-- bio changed to VARCHAR(1000) for consistent display length limits
ALTER TABLE instructors
    ALTER COLUMN bio TYPE VARCHAR(1000);

-- title column was missing from the initial design; added as required field
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS title VARCHAR(200) NOT NULL DEFAULT 'Untitled Course';

-- every instructor must declare a specialty; enforcing NOT NULL after initial creation
ALTER TABLE instructors
    ALTER COLUMN experience_area SET NOT NULL;

-- created_date should never be empty; defaulting to today's date
ALTER TABLE groups
    ALTER COLUMN created_date SET DEFAULT CURRENT_DATE;

-- status column added to track enrollment lifecycle: active, dropped, or completed
ALTER TABLE enrollments
    ADD COLUMN IF NOT EXISTS status VARCHAR(20)
        DEFAULT 'active'
        CHECK (status IN ('active', 'dropped', 'completed'));

-- renaming joined_date to join_date for consistent naming across the schema
ALTER TABLE group_users
    RENAME COLUMN joined_date TO join_date;


-- TRUNCATE (children first to respect FK order)

TRUNCATE TABLE group_courses   CASCADE;
TRUNCATE TABLE group_users     CASCADE;
TRUNCATE TABLE certifications  CASCADE;
TRUNCATE TABLE feedback        CASCADE;
TRUNCATE TABLE progress        CASCADE;
TRUNCATE TABLE enrollments     CASCADE;
TRUNCATE TABLE courses         CASCADE;
TRUNCATE TABLE groups          CASCADE;
TRUNCATE TABLE instructors     CASCADE;
TRUNCATE TABLE users           CASCADE;


-- INSERT SAMPLE DATA

-- Users
INSERT INTO users (last_name, first_name, email) VALUES
    ('Ivanova',  'Maria',   'maria.ivanova@gmail.com'),
    ('Bekova',   'Aisha',   'aisha.bekova@mail.ru'),
    ('Seitkali', 'Daniyar', 'daniyar.seitkali@edu.kz');

-- Instructors
INSERT INTO instructors (bio, experience_area, rating) VALUES
    ('10 years in backend engineering and database architecture.', 'Database Engineering', 4.80),
    ('Frontend developer specialising in React and UX design.',   'Frontend Development', 4.50),
    ('Data scientist with focus on ML pipelines and Python.',     'Data Science',         4.65);

-- Groups
INSERT INTO groups (group_name) VALUES
    ('SQL Beginners Cohort'),
    ('Web Dev Bootcamp'),
    ('Data Science Track');

-- Courses (instructor_id resolved via subquery)
INSERT INTO courses (instructor_id, description, price, title) VALUES
    (
        (SELECT instructor_id FROM instructors WHERE experience_area = 'Database Engineering'),
        'Comprehensive introduction to PostgreSQL and relational databases.',
        49.99,
        'PostgreSQL Fundamentals'
    ),
    (
        (SELECT instructor_id FROM instructors WHERE experience_area = 'Frontend Development'),
        'Build modern web applications with React and Tailwind CSS.',
        59.99,
        'React & Modern CSS'
    ),
    (
        (SELECT instructor_id FROM instructors WHERE experience_area = 'Data Science'),
        'End-to-end machine learning projects using Python and scikit-learn.',
        69.99,
        'Applied Machine Learning'
    );

-- Enrollments (FKs resolved via subquery; dates after 2026-01-01)
INSERT INTO enrollments (course_id, user_id, enroll_date, status) VALUES
    (
        (SELECT course_id FROM courses WHERE title = 'PostgreSQL Fundamentals'),
        (SELECT user_id   FROM users   WHERE email = 'maria.ivanova@gmail.com'),
        '2026-02-10',
        'active'
    ),
    (
        (SELECT course_id FROM courses WHERE title = 'React & Modern CSS'),
        (SELECT user_id   FROM users   WHERE email = 'aisha.bekova@mail.ru'),
        '2026-02-15',
        'active'
    ),
    (
        (SELECT course_id FROM courses WHERE title = 'Applied Machine Learning'),
        (SELECT user_id   FROM users   WHERE email = 'daniyar.seitkali@edu.kz'),
        '2026-03-01',
        'active'
    );

-- Progress
INSERT INTO progress (user_id, course_id, completion_percent) VALUES
    (
        (SELECT user_id   FROM users   WHERE email = 'maria.ivanova@gmail.com'),
        (SELECT course_id FROM courses WHERE title = 'PostgreSQL Fundamentals'),
        75
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'aisha.bekova@mail.ru'),
        (SELECT course_id FROM courses WHERE title = 'React & Modern CSS'),
        40
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'daniyar.seitkali@edu.kz'),
        (SELECT course_id FROM courses WHERE title = 'Applied Machine Learning'),
        90
    );

-- Feedback
INSERT INTO feedback (user_id, course_id, rating, comment) VALUES
    (
        (SELECT user_id   FROM users   WHERE email = 'maria.ivanova@gmail.com'),
        (SELECT course_id FROM courses WHERE title = 'PostgreSQL Fundamentals'),
        5,
        'Excellent course, very clear explanations and hands-on exercises.'
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'aisha.bekova@mail.ru'),
        (SELECT course_id FROM courses WHERE title = 'React & Modern CSS'),
        4,
        'Great content, would appreciate more advanced examples.'
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'daniyar.seitkali@edu.kz'),
        (SELECT course_id FROM courses WHERE title = 'Applied Machine Learning'),
        5,
        'Best ML course I have taken, practical and well-structured.'
    );

-- Certifications (issue_date after 2026-01-01)
INSERT INTO certifications (user_id, course_id, issue_date) VALUES
    (
        (SELECT user_id   FROM users   WHERE email = 'maria.ivanova@gmail.com'),
        (SELECT course_id FROM courses WHERE title = 'PostgreSQL Fundamentals'),
        '2026-04-01'
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'aisha.bekova@mail.ru'),
        (SELECT course_id FROM courses WHERE title = 'React & Modern CSS'),
        '2026-04-05'
    ),
    (
        (SELECT user_id   FROM users   WHERE email = 'daniyar.seitkali@edu.kz'),
        (SELECT course_id FROM courses WHERE title = 'Applied Machine Learning'),
        '2026-04-10'
    );

-- GroupUsers
INSERT INTO group_users (group_id, user_id, join_date) VALUES
    (
        (SELECT group_id FROM groups WHERE group_name = 'SQL Beginners Cohort'),
        (SELECT user_id  FROM users  WHERE email = 'maria.ivanova@gmail.com'),
        '2026-02-10'
    ),
    (
        (SELECT group_id FROM groups WHERE group_name = 'Web Dev Bootcamp'),
        (SELECT user_id  FROM users  WHERE email = 'aisha.bekova@mail.ru'),
        '2026-02-15'
    ),
    (
        (SELECT group_id FROM groups WHERE group_name = 'Data Science Track'),
        (SELECT user_id  FROM users  WHERE email = 'daniyar.seitkali@edu.kz'),
        '2026-03-01'
    );

-- GroupCourses
INSERT INTO group_courses (group_id, course_id, assigned_date) VALUES
    (
        (SELECT group_id  FROM groups  WHERE group_name = 'SQL Beginners Cohort'),
        (SELECT course_id FROM courses WHERE title = 'PostgreSQL Fundamentals'),
        '2026-02-08'
    ),
    (
        (SELECT group_id  FROM groups  WHERE group_name = 'Web Dev Bootcamp'),
        (SELECT course_id FROM courses WHERE title = 'React & Modern CSS'),
        '2026-02-13'
    ),
    (
        (SELECT group_id  FROM groups  WHERE group_name = 'Data Science Track'),
        (SELECT course_id FROM courses WHERE title = 'Applied Machine Learning'),
        '2026-02-28'
    );
