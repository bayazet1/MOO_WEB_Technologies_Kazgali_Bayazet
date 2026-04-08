/*
Schema Issues and Fixes

1. Members.username missing NOT NULL → ALTER TABLE Members ALTER COLUMN username SET NOT NULL;
2. Members.username missing UNIQUE → ALTER TABLE Members ADD CONSTRAINT members_username_unique UNIQUE (username);

3. Members.email missing NOT NULL → ALTER TABLE Members ALTER COLUMN email SET NOT NULL;
4. Members.email missing UNIQUE → ALTER TABLE Members ADD CONSTRAINT members_email_unique UNIQUE (email);

5. Members.is_active missing DEFAULT → ALTER TABLE Members ALTER COLUMN is_active SET DEFAULT true;

6. Books.author missing NOT NULL → ALTER TABLE Books ALTER COLUMN author SET NOT NULL;

7. Books.year_pub missing CHECK constraint → ALTER TABLE Books ADD CONSTRAINT books_year_check CHECK (year_pub >= 0);

8. Books missing column condition → ALTER TABLE Books ADD COLUMN condition VARCHAR(30) NOT NULL DEFAULT 'good';

9. Books.owner_id missing FOREIGN KEY → ALTER TABLE Books ADD CONSTRAINT books_owner_fk FOREIGN KEY (owner_id) REFERENCES Members(id);

10. Exchanges.book_id missing FOREIGN KEY → ALTER TABLE Exchanges ADD CONSTRAINT exchanges_book_fk FOREIGN KEY (book_id) REFERENCES Books(id);

11. Exchanges.borrower_id missing FOREIGN KEY → ALTER TABLE Exchanges ADD CONSTRAINT exchanges_member_fk FOREIGN KEY (borrower_id) REFERENCES Members(id);

12. Exchanges.exchange_date missing NOT NULL → ALTER TABLE Exchanges ALTER COLUMN exchange_date SET NOT NULL;

13. Exchanges.exchange_date missing CHECK constraint → ALTER TABLE Exchanges ADD CONSTRAINT exchange_date_check CHECK (exchange_date >= '2026-01-01');

14. Exchanges.return_date missing CHECK constraint → ALTER TABLE Exchanges ADD CONSTRAINT return_date_check CHECK (return_date >= '2026-01-01');

15. Exchanges missing status column → ALTER TABLE Exchanges ADD COLUMN status VARCHAR(20) DEFAULT 'pending';

16. Reviews.review_text missing NOT NULL → ALTER TABLE Reviews ALTER COLUMN review_text SET NOT NULL;

17. Reviews.rating missing CHECK constraint → ALTER TABLE Reviews ADD CONSTRAINT reviews_rating_check CHECK (rating BETWEEN 1 AND 5);

18. Reviews.book_id missing FOREIGN KEY → ALTER TABLE Reviews ADD CONSTRAINT reviews_book_fk FOREIGN KEY (book_id) REFERENCES Books(id);

19. Reviews.member_id missing FOREIGN KEY → ALTER TABLE Reviews ADD CONSTRAINT reviews_member_fk FOREIGN KEY (member_id) REFERENCES Members(id);
*/


--MEMBERS
-- username must not be null
ALTER TABLE Members
ALTER COLUMN username SET NOT NULL;
-- username must be unique
ALTER TABLE Members
ADD CONSTRAINT members_username_unique UNIQUE (username);
-- email must not be null
ALTER TABLE Members
ALTER COLUMN email SET NOT NULL;
-- email must be unique
ALTER TABLE Members
ADD CONSTRAINT members_email_unique UNIQUE (email);
-- default value for is_active
ALTER TABLE Members
ALTER COLUMN is_active SET DEFAULT true;
--BOOKS
-- author must not be null
ALTER TABLE Books
ALTER COLUMN author SET NOT NULL;
-- year_pub must be >= 0
ALTER TABLE Books
ADD CONSTRAINT books_year_check
CHECK (year_pub >= 0);
-- add missing column condition
ALTER TABLE Books
ADD COLUMN condition VARCHAR(30) NOT NULL DEFAULT 'good';
-- add foreign key to Members
ALTER TABLE Books
ADD CONSTRAINT books_owner_fk
FOREIGN KEY (owner_id)
REFERENCES Members(id);
--EXCHANGES
-- exchange_date must not be null
ALTER TABLE Exchanges
ALTER COLUMN exchange_date SET NOT NULL;
-- check exchange_date >= 2026
ALTER TABLE Exchanges
ADD CONSTRAINT exchange_date_check
CHECK (exchange_date >= '2026-01-01');
-- check return_date >= 2026
ALTER TABLE Exchanges
ADD CONSTRAINT return_date_check
CHECK (return_date >= '2026-01-01');
-- add missing status column
ALTER TABLE Exchanges
ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
-- foreign key to Books
ALTER TABLE Exchanges
ADD CONSTRAINT exchanges_book_fk
FOREIGN KEY (book_id)
REFERENCES Books(id);
-- foreign key to Members
ALTER TABLE Exchanges
ADD CONSTRAINT exchanges_member_fk
FOREIGN KEY (borrower_id)
REFERENCES Members(id);
--REVIEWS
-- review_text must not be null
ALTER TABLE Reviews
ALTER COLUMN review_text SET NOT NULL;
-- rating must be between 1 and 5
ALTER TABLE Reviews
ADD CONSTRAINT reviews_rating_check
CHECK (rating BETWEEN 1 AND 5);
-- foreign key to Books
ALTER TABLE Reviews
ADD CONSTRAINT reviews_book_fk
FOREIGN KEY (book_id)
REFERENCES Books(id);
-- foreign key to Members
ALTER TABLE Reviews
ADD CONSTRAINT reviews_member_fk
FOREIGN KEY (member_id)
REFERENCES Members(id);
-- drop constraint
ALTER TABLE Books
DROP CONSTRAINT books_owner_fk;
-- add it again
ALTER TABLE Books
ADD CONSTRAINT books_owner_fk
FOREIGN KEY (owner_id)
REFERENCES Members(id);





INSERT INTO Members (username, email, joined_date, is_active)
VALUES
('alice', 'alice@mail.com', '2026-01-10', true),
('bob', 'bob@mail.com', '2026-02-05', true),
('charlie', 'charlie@mail.com', '2026-03-15', true),
('david', 'david@mail.com', '2026-04-01', false);

INSERT INTO Books (title, author, year_pub, owner_id, condition)
VALUES
('Database Systems', 'Elmasri', 2016, 1, 'good'),
('Clean Code', 'Robert Martin', 2008, 2, 'excellent'),
('Learning SQL', 'Alan Beaulieu', 2020, 3, 'good'),
('PostgreSQL Guide', 'John Smith', 2022, 1, 'fair');

INSERT INTO Exchanges (book_id, borrower_id, exchange_date, return_date, status)
VALUES
(1, 2, '2026-05-01', '2026-05-10', 'returned'),
(2, 3, '2026-06-01', '2026-06-15', 'pending'),
(3, 1, '2026-07-05', '2026-07-20', 'pending');

INSERT INTO Reviews (book_id, member_id, rating, review_text, created_at)
VALUES
(1, 2, 5, 'Great database reference book.', '2026-05-11'),
(2, 3, 4, 'Very useful for programmers.', '2026-06-18'),
(3, 1, 5, 'Easy to understand SQL concepts.', '2026-07-22');


-- Intentional error: rating must be between 1 and 5
INSERT INTO Reviews (book_id, member_id, rating, review_text, created_at)
VALUES (1, 3, 6, 'Invalid rating example', '2026-08-01');

-- Received PostgreSQL error:
SQL Error [23514]: ERROR: new row for relation "reviews" violates check constraint "reviews_rating_check"
  Detail: Failing row contains (4, 1, 3, 6, Invalid rating example, 2026-08-01).
  ERROR: new row for relation "reviews" violates check constraint "reviews_rating_check"
  Detail: Failing row contains (4, 1, 3, 6, Invalid rating example, 2026-08-01).
