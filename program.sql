-- =====================================================================
-- LIBRARY LENDING SYSTEM
-- Relational database design & implementation (PostgreSQL dialect)
-- Based on: Fundamentals of Database Systems (Elmasri & Navathe)
-- =====================================================================
--
-- DESIGN NOTES
-- ---------------------------------------------------------------------
-- The book requirement says: "ISBN can be shared among copies" and
-- "a book can have multiple copies, while ISBN is used to group
-- identical editions." That means BOOK and "the physical thing a
-- member borrows" are two different entities:
--
--   BOOK       -> one row per ISBN/edition (title, author, publisher...)
--   BOOK_COPY  -> one row per physical copy of that ISBN (copy_id PK,
--                 shelf/section location, and its own availability
--                 status). This is what LOAN actually references.
--
-- This split is what makes the main challenge solvable cleanly: "a
-- book cannot be issued when no copy is available" becomes "a LOAN
-- can only be created for a BOOK_COPY whose status = 'available'",
-- enforced with a partial UNIQUE index + trigger (see below), instead
-- of a fuzzy boolean on the Book table that can't tell copies apart.
--
-- Tables:
--   1. BOOK        - catalog entry, one row per ISBN/edition
--   2. BOOK_COPY   - physical copy of a book, tracks availability
--   3. MEMBER      - library patrons
--   4. LIBRARIAN   - staff who issue/receive loans
--   5. LOAN        - borrowing transaction (the audit/history table)
--
-- =====================================================================


-- =====================================================================
-- 0. CLEAN SLATE (safe to re-run)
-- =====================================================================
DROP TABLE IF EXISTS loan            CASCADE;
DROP TABLE IF EXISTS book_copy       CASCADE;
DROP TABLE IF EXISTS book            CASCADE;
DROP TABLE IF EXISTS member          CASCADE;
DROP TABLE IF EXISTS librarian       CASCADE;
DROP TYPE  IF EXISTS copy_status_t;
DROP TYPE  IF EXISTS loan_status_t;


-- =====================================================================
-- 1. ENUM TYPES
-- =====================================================================
CREATE TYPE copy_status_t AS ENUM ('available', 'on_loan', 'lost', 'damaged', 'withdrawn');
CREATE TYPE loan_status_t AS ENUM ('borrowed', 'returned', 'overdue');


-- =====================================================================
-- 2. BOOK  (catalog entry - one row per ISBN/edition)
--    PK: isbn
-- =====================================================================
CREATE TABLE book (
    isbn            VARCHAR(20)  PRIMARY KEY,                 -- e.g. ISBN-13
    title           VARCHAR(255) NOT NULL,
    author          VARCHAR(255) NOT NULL,
    publisher       VARCHAR(150),
    publication_year SMALLINT CHECK (publication_year BETWEEN 1450 AND 2100),
    category        VARCHAR(80),
    created_at      TIMESTAMP    NOT NULL DEFAULT now()
);


-- =====================================================================
-- 3. BOOK_COPY  (physical copy of a book)
--    PK: copy_id
--    FK: isbn -> book(isbn)
--    This table is what carries "Available" status per the challenge -
--    each individual copy, not the book title as a whole, is available
--    or not.
-- =====================================================================
CREATE TABLE book_copy (
    copy_id         SERIAL       PRIMARY KEY,
    isbn            VARCHAR(20)  NOT NULL REFERENCES book(isbn)
                                   ON UPDATE CASCADE ON DELETE RESTRICT,
    shelf_location  VARCHAR(50),                               -- e.g. "Shelf 12"
    section         VARCHAR(50),                               -- e.g. "Fiction"
    status          copy_status_t NOT NULL DEFAULT 'available',
    acquired_date   DATE          NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_book_copy_isbn   ON book_copy(isbn);
CREATE INDEX idx_book_copy_status ON book_copy(status);


-- =====================================================================
-- 4. MEMBER  (library patrons / borrowers)
--    PK: member_id
-- =====================================================================
CREATE TABLE member (
    member_id       SERIAL       PRIMARY KEY,
    first_name      VARCHAR(80)  NOT NULL,
    last_name       VARCHAR(80)  NOT NULL,
    address         VARCHAR(255),
    phone           VARCHAR(20),
    email           VARCHAR(150) UNIQUE NOT NULL,
    membership_date DATE         NOT NULL DEFAULT CURRENT_DATE
);


-- =====================================================================
-- 5. LIBRARIAN  (staff who issue/receive loans)
--    PK: librarian_id
-- =====================================================================
CREATE TABLE librarian (
    librarian_id    SERIAL       PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    hire_date       DATE         NOT NULL DEFAULT CURRENT_DATE
);


-- =====================================================================
-- 6. LOAN  (borrowing/returning transaction - the audit/history table)
--    PK: loan_id
--    FK: copy_id           -> book_copy(copy_id)
--    FK: member_id         -> member(member_id)
--    FK: issuing_librarian_id  -> librarian(librarian_id)
--    FK: receiving_librarian_id -> librarian(librarian_id)  (nullable, set on return)
--
--    Every borrow/return event is a row here, and rows are never
--    deleted - this IS the loan history/audit trail. "Overdue" is
--    computed (see queries below and the maintenance job at the
--    bottom) rather than trusted blindly as a stored value, but we
--    still keep a status column so a snapshot is fast to query and
--    fines/reporting can join on it.
-- =====================================================================
CREATE TABLE loan (
    loan_id                 SERIAL       PRIMARY KEY,
    copy_id                 INTEGER      NOT NULL REFERENCES book_copy(copy_id),
    member_id               INTEGER      NOT NULL REFERENCES member(member_id),
    issuing_librarian_id    INTEGER      REFERENCES librarian(librarian_id),
    receiving_librarian_id  INTEGER      REFERENCES librarian(librarian_id),
    borrow_date             DATE         NOT NULL DEFAULT CURRENT_DATE,
    due_date                DATE         NOT NULL,
    return_date             DATE,                              -- NULL until returned
    status                  loan_status_t NOT NULL DEFAULT 'borrowed',
    fine_amount             NUMERIC(8,2) NOT NULL DEFAULT 0 CHECK (fine_amount >= 0),

    CONSTRAINT chk_due_after_borrow    CHECK (due_date >= borrow_date),
    CONSTRAINT chk_return_after_borrow CHECK (return_date IS NULL OR return_date >= borrow_date)
);

CREATE INDEX idx_loan_member   ON loan(member_id);
CREATE INDEX idx_loan_copy     ON loan(copy_id);
CREATE INDEX idx_loan_status   ON loan(status);
CREATE INDEX idx_loan_due_date ON loan(due_date);

-- MAIN CHALLENGE, part 1: a copy can have at most ONE open (unreturned)
-- loan at a time. A partial unique index enforces "no double booking"
-- of the same physical copy at the database level, independent of
-- whatever the application layer does.
CREATE UNIQUE INDEX uq_one_open_loan_per_copy
    ON loan(copy_id)
    WHERE return_date IS NULL;


-- =====================================================================
-- 7. TRIGGERS - keep book_copy.status in sync with loan activity
--    (MAIN CHALLENGE, part 2: enforce "cannot issue an unavailable
--    copy" and flip status automatically on borrow/return, so the
--    availability flag is never stale.)
-- =====================================================================

-- 7a. Before inserting a new loan: copy must currently be 'available'.
CREATE OR REPLACE FUNCTION fn_check_copy_available()
RETURNS TRIGGER AS $$
DECLARE
    v_status copy_status_t;
BEGIN
    SELECT status INTO v_status FROM book_copy WHERE copy_id = NEW.copy_id FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'Copy % does not exist', NEW.copy_id;
    ELSIF v_status <> 'available' THEN
        RAISE EXCEPTION 'Copy % is not available for lending (status = %)', NEW.copy_id, v_status;
    END IF;

    -- Optional business rule: block members who already have an overdue loan.
    IF EXISTS (
        SELECT 1 FROM loan
        WHERE member_id = NEW.member_id
          AND return_date IS NULL
          AND due_date < CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'Member % has overdue loans and cannot borrow new books', NEW.member_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_copy_available
    BEFORE INSERT ON loan
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_copy_available();

-- 7b. After inserting a loan: mark the copy as on_loan.
CREATE OR REPLACE FUNCTION fn_mark_copy_on_loan()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE book_copy SET status = 'on_loan' WHERE copy_id = NEW.copy_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mark_copy_on_loan
    AFTER INSERT ON loan
    FOR EACH ROW
    EXECUTE FUNCTION fn_mark_copy_on_loan();

-- 7c. After a loan is updated to set return_date: mark copy available
--     again and flip loan status to 'returned'.
CREATE OR REPLACE FUNCTION fn_mark_copy_returned()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE book_copy SET status = 'available' WHERE copy_id = NEW.copy_id;
        NEW.status := 'returned';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mark_copy_returned
    BEFORE UPDATE ON loan
    FOR EACH ROW
    EXECUTE FUNCTION fn_mark_copy_returned();


-- =====================================================================
-- 8. SAMPLE DATA
-- =====================================================================
INSERT INTO book (isbn, title, author, publisher, publication_year, category) VALUES
('978-0132836504', 'Fundamentals of Database Systems', 'Elmasri & Navathe', 'Pearson', 2015, 'Computer Science'),
('978-0134685991', 'Effective Java',                   'Joshua Bloch',      'Addison-Wesley', 2018, 'Computer Science'),
('978-0439708180', 'Harry Potter and the Sorcerer''s Stone', 'J. K. Rowling', 'Scholastic', 1998, 'Fantasy');

-- Two physical copies of the DB textbook, one of each of the others.
INSERT INTO book_copy (isbn, shelf_location, section) VALUES
('978-0132836504', 'CS-12', 'Computer Science'),
('978-0132836504', 'CS-12', 'Computer Science'),
('978-0134685991', 'CS-14', 'Computer Science'),
('978-0439708180', 'FIC-03', 'Fantasy');

INSERT INTO member (first_name, last_name, address, phone, email, membership_date) VALUES
('Asha', 'Rao',   '12 MG Road, Bengaluru', '9876543210', 'asha.rao@example.com',   '2023-01-15'),
('Vineeth', 'Kumar', '45 Park Street, Chennai', '9876500000', 'vineeth.kumar@medicodio.ai', '2024-06-01');

INSERT INTO librarian (name, email, hire_date) VALUES
('Priya Nair',  'priya.nair@library.org',  '2019-04-01'),
('Rahul Mehta', 'rahul.mehta@library.org', '2021-09-10');


-- =====================================================================
-- 9. SAMPLE QUERIES
-- =====================================================================

-- ---------------------------------------------------------------
-- 9.1 ISSUE A BOOK
--     Borrow one available copy of a given ISBN for a member,
--     14-day lending period, recorded by a librarian.
--     Step 1: pick an available copy of the requested ISBN.
--     Step 2: insert the loan (triggers validate + flip status).
-- ---------------------------------------------------------------
-- Example: member 2 borrows a copy of the DB textbook, issued by librarian 1.
WITH available_copy AS (
    SELECT copy_id
    FROM book_copy
    WHERE isbn = '978-0132836504'
      AND status = 'available'
    ORDER BY copy_id
    LIMIT 1
)
INSERT INTO loan (copy_id, member_id, issuing_librarian_id, borrow_date, due_date)
SELECT copy_id, 2, 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days'
FROM available_copy
RETURNING *;

-- If no row is returned, no copy was available for that ISBN -
-- the application should report "no copies available" to the user.


-- ---------------------------------------------------------------
-- 9.2 RETURN A BOOK
--     Set return_date on the open loan for a given copy; triggers
--     mark the copy available again and the loan 'returned'.
-- ---------------------------------------------------------------
UPDATE loan
SET return_date            = CURRENT_DATE,
    receiving_librarian_id = 2
WHERE copy_id = 1                 -- the copy being handed back
  AND return_date IS NULL;        -- only touches the open loan


-- ---------------------------------------------------------------
-- 9.3 FIND OVERDUE BOOKS
--     Loans still open (not returned) whose due date has passed.
-- ---------------------------------------------------------------
SELECT
    l.loan_id,
    m.first_name || ' ' || m.last_name AS member_name,
    b.title,
    bc.copy_id,
    l.borrow_date,
    l.due_date,
    CURRENT_DATE - l.due_date AS days_overdue
FROM loan l
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book      b  ON b.isbn     = bc.isbn
JOIN member    m  ON m.member_id = l.member_id
WHERE l.return_date IS NULL
  AND l.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;


-- ---------------------------------------------------------------
-- 9.4 FIND BOOKS CURRENTLY AVAILABLE
--     Per-title copy counts, and the individual available copies.
-- ---------------------------------------------------------------
-- (a) Availability summary per book title:
SELECT
    b.isbn,
    b.title,
    b.author,
    COUNT(*) FILTER (WHERE bc.status = 'available') AS copies_available,
    COUNT(*)                                          AS total_copies
FROM book b
JOIN book_copy bc ON bc.isbn = b.isbn
GROUP BY b.isbn, b.title, b.author
ORDER BY b.title;

-- (b) The actual available copies (with shelf location):
SELECT bc.copy_id, b.title, b.author, bc.shelf_location, bc.section
FROM book_copy bc
JOIN book b ON b.isbn = bc.isbn
WHERE bc.status = 'available'
ORDER BY b.title;


-- ---------------------------------------------------------------
-- 9.5 BORROWING HISTORY OF A MEMBER
-- ---------------------------------------------------------------
SELECT
    l.loan_id,
    b.title,
    l.borrow_date,
    l.due_date,
    l.return_date,
    l.status,
    l.fine_amount
FROM loan l
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book      b  ON b.isbn     = bc.isbn
WHERE l.member_id = 2       -- e.g. Vineeth Kumar
ORDER BY l.borrow_date DESC;


-- =====================================================================
-- 10. MAINTENANCE: mark overdue loans (run periodically, e.g. via cron)
--     Keeps the stored status column in sync so simple status = 'overdue'
--     queries stay cheap; the "as of right now" truth is always the
--     query in 9.3 above.
-- =====================================================================
UPDATE loan
SET status = 'overdue'
WHERE return_date IS NULL
  AND due_date < CURRENT_DATE
  AND status <> 'overdue';
