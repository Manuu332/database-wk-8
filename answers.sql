-- Library Management System Database

-- Create Database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- 1. Members Table (One-to-Many with Borrowings)
CREATE TABLE Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    membership_date DATE NOT NULL,
    membership_status ENUM('Active', 'Suspended', 'Expired') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Authors Table (Many-to-Many with Books through BookAuthors)
CREATE TABLE Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Publishers Table (One-to-Many with Books)
CREATE TABLE Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    publisher_name VARCHAR(100) UNIQUE NOT NULL,
    contact_email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    website VARCHAR(200),
    established_year YEAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Categories Table (One-to-Many with Books)
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_category_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES Categories(category_id) ON DELETE SET NULL
);

-- 5. Books Table (Central table with multiple relationships)
CREATE TABLE Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    edition VARCHAR(20),
    publication_year YEAR,
    pages INT CHECK (pages > 0),
    language VARCHAR(30) DEFAULT 'English',
    description TEXT,
    publisher_id INT NOT NULL,
    category_id INT NOT NULL,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    shelf_location VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id) ON DELETE RESTRICT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE RESTRICT
);

-- 6. BookAuthors Table (Junction table for Many-to-Many relationship between Books and Authors)
CREATE TABLE BookAuthors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type ENUM('Primary', 'Co-Author', 'Editor', 'Translator') DEFAULT 'Primary',
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- 7. Borrowings Table (One-to-Many from Members and Books)
CREATE TABLE Borrowings (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('Borrowed', 'Returned', 'Overdue', 'Lost') DEFAULT 'Borrowed',
    late_fee DECIMAL(8,2) DEFAULT 0.00 CHECK (late_fee >= 0),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE RESTRICT,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE RESTRICT,
    CHECK (due_date >= borrow_date),
    CHECK (return_date IS NULL OR return_date >= borrow_date)
);

-- 8. Reservations Table (For books that are currently borrowed)
CREATE TABLE Reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled') DEFAULT 'Pending',
    priority INT DEFAULT 1 CHECK (priority >= 1),
    expiry_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    UNIQUE KEY unique_active_reservation (member_id, book_id, status)
);

-- 9. Fines Table (One-to-Many with Members)
CREATE TABLE Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    borrowing_id INT NULL,
    amount DECIMAL(8,2) NOT NULL CHECK (amount > 0),
    reason ENUM('Late Return', 'Lost Book', 'Damage', 'Other') NOT NULL,
    fine_date DATE NOT NULL,
    paid_date DATE NULL,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (borrowing_id) REFERENCES Borrowings(borrowing_id) ON DELETE SET NULL,
    CHECK (paid_date IS NULL OR paid_date >= fine_date)
);

-- 10. Staff Table (Library employees)
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    position ENUM('Librarian', 'Assistant', 'Manager', 'Admin') NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2) CHECK (salary > 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 11. BookReviews Table (Many-to-Many between Members and Books)
CREATE TABLE BookReviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_title VARCHAR(200),
    review_text TEXT,
    review_date DATE NOT NULL,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    UNIQUE KEY unique_member_book_review (member_id, book_id)
);

-- Insert Sample Data

-- Insert Publishers
INSERT INTO Publishers (publisher_name, contact_email, established_year) VALUES
('Penguin Random House', 'contact@penguin.com', 2013),
('HarperCollins', 'info@harpercollins.com', 1989),
('Simon & Schuster', 'support@simonschuster.com', 1924);

-- Insert Categories
INSERT INTO Categories (category_name, description) VALUES
('Fiction', 'Imaginative literature including novels and short stories'),
('Science Fiction', 'Fiction based on imagined future scientific or technological advances'),
('Mystery', 'Fiction involving suspense and crime solving'),
('Biography', 'Accounts of peoples lives written by other authors'),
('Science', 'Books about scientific principles and discoveries');

-- Insert Authors
INSERT INTO Authors (first_name, last_name, nationality) VALUES
('George', 'Orwell', 'British'),
('Frank', 'Herbert', 'American'),
('Agatha', 'Christie', 'British'),
('Walter', 'Isaacson', 'American'),
('Stephen', 'Hawking', 'British');

-- Insert Books
INSERT INTO Books (isbn, title, publication_year, pages, publisher_id, category_id, total_copies, available_copies) VALUES
('978-0451524935', '1984', 1949, 328, 1, 1, 5, 5),
('978-0441172719', 'Dune', 1965, 412, 2, 2, 3, 3),
('978-0062073561', 'Murder on the Orient Express', 1934, 256, 3, 3, 4, 4),
('978-1501127625', 'Leonardo da Vinci', 2017, 624, 1, 4, 2, 2),
('978-0553380163', 'A Brief History of Time', 1988, 256, 2, 5, 3, 3);

-- Insert BookAuthors (Many-to-Many relationships)
INSERT INTO BookAuthors (book_id, author_id, contribution_type) VALUES
(1, 1, 'Primary'),
(2, 2, 'Primary'),
(3, 3, 'Primary'),
(4, 4, 'Primary'),
(5, 5, 'Primary');

-- Insert Members
INSERT INTO Members (first_name, last_name, email, phone, membership_date) VALUES
('John', 'Smith', 'john.smith@email.com', '+1234567890', '2024-01-15'),
('Sarah', 'Johnson', 'sarah.j@email.com', '+1234567891', '2024-02-20'),
('Michael', 'Brown', 'michael.b@email.com', '+1234567892', '2024-03-10');

-- Insert Staff
INSERT INTO Staff (first_name, last_name, email, position, hire_date, salary) VALUES
('Emily', 'Davis', 'emily.davis@library.com', 'Librarian', '2020-06-15', 55000.00),
('Robert', 'Wilson', 'robert.wilson@library.com', 'Manager', '2018-03-10', 75000.00);

-- Create Indexes for Performance
CREATE INDEX idx_books_title ON Books(title);
CREATE INDEX idx_books_isbn ON Books(isbn);
CREATE INDEX idx_borrowings_member ON Borrowings(member_id);
CREATE INDEX idx_borrowings_book ON Borrowings(book_id);
CREATE INDEX idx_borrowings_due_date ON Borrowings(due_date);
CREATE INDEX idx_members_email ON Members(email);
CREATE INDEX idx_members_status ON Members(membership_status);

-- Create Views for Common Queries

-- View: Available Books
CREATE VIEW AvailableBooks AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    a.first_name,
    a.last_name,
    b.available_copies,
    c.category_name,
    p.publisher_name
FROM Books b
JOIN BookAuthors ba ON b.book_id = ba.book_id
JOIN Authors a ON ba.author_id = a.author_id
JOIN Categories c ON b.category_id = c.category_id
JOIN Publishers p ON b.publisher_id = p.publisher_id
WHERE b.available_copies > 0;

-- View: Current Borrowings with Member Details
CREATE VIEW CurrentBorrowings AS
SELECT 
    br.borrowing_id,
    m.first_name,
    m.last_name,
    m.email,
    b.title,
    br.borrow_date,
    br.due_date,
    br.status,
    DATEDIFF(CURDATE(), br.due_date) AS days_overdue
FROM Borrowings br
JOIN Members m ON br.member_id = m.member_id
JOIN Books b ON br.book_id = b.book_id
WHERE br.status IN ('Borrowed', 'Overdue');

-- View: Member Reading History
CREATE VIEW MemberReadingHistory AS
SELECT 
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title,
    br.borrow_date,
    br.return_date,
    a.first_name AS author_first_name,
    a.last_name AS author_last_name
FROM Borrowings br
JOIN Members m ON br.member_id = m.member_id
JOIN Books b ON br.book_id = b.book_id
JOIN BookAuthors ba ON b.book_id = ba.book_id
JOIN Authors a ON ba.author_id = a.author_id
WHERE br.status = 'Returned';

-- Stored Procedure: Borrow a Book
DELIMITER //
CREATE PROCEDURE BorrowBook(
    IN p_member_id INT,
    IN p_book_id INT,
    IN p_borrow_days INT
)
BEGIN
    DECLARE available_count INT;
    DECLARE member_status VARCHAR(20);
    
    -- Check member status
    SELECT membership_status INTO member_status FROM Members WHERE member_id = p_member_id;
    IF member_status != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member is not active';
    END IF;
    
    -- Check available copies
    SELECT available_copies INTO available_count FROM Books WHERE book_id = p_book_id;
    IF available_count <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book is not available';
    END IF;
    
    -- Create borrowing record
    INSERT INTO Borrowings (member_id, book_id, borrow_date, due_date)
    VALUES (p_member_id, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_borrow_days DAY));
    
    -- Update available copies
    UPDATE Books 
    SET available_copies = available_copies - 1 
    WHERE book_id = p_book_id;
    
END//
DELIMITER ;

-- Stored Procedure: Return a Book
DELIMITER //
CREATE PROCEDURE ReturnBook(
    IN p_borrowing_id INT
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_late_fee DECIMAL(8,2);
    
    -- Get book ID and due date
    SELECT book_id, due_date INTO v_book_id, v_due_date 
    FROM Borrowings 
    WHERE borrowing_id = p_borrowing_id;
    
    -- Calculate late fee if applicable
    IF CURDATE() > v_due_date THEN
        SET v_late_fee = DATEDIFF(CURDATE(), v_due_date) * 0.50; -- $0.50 per day
    ELSE
        SET v_late_fee = 0;
    END IF;
    
    -- Update borrowing record
    UPDATE Borrowings 
    SET return_date = CURDATE(),
        status = 'Returned',
        late_fee = v_late_fee
    WHERE borrowing_id = p_borrowing_id;
    
    -- Update available copies
    UPDATE Books 
    SET available_copies = available_copies + 1 
    WHERE book_id = v_book_id;
    
    -- Insert fine if applicable
    IF v_late_fee > 0 THEN
        INSERT INTO Fines (member_id, borrowing_id, amount, reason, fine_date)
        SELECT member_id, p_borrowing_id, v_late_fee, 'Late Return', CURDATE()
        FROM Borrowings 
        WHERE borrowing_id = p_borrowing_id;
    END IF;
    
END//
DELIMITER ;

-- Create Triggers for Data Integrity

-- Trigger: Update book status when copies run out
DELIMITER //
CREATE TRIGGER after_book_update
AFTER UPDATE ON Books
FOR EACH ROW
BEGIN
    IF NEW.available_copies = 0 AND OLD.available_copies > 0 THEN
        INSERT INTO Reservations (book_id, member_id, reservation_date, expiry_date)
        SELECT NEW.book_id, member_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY)
        FROM Members 
        WHERE membership_status = 'Active'
        LIMIT 1;
    END IF;
END//
DELIMITER ;

-- Display Database Structure
SHOW TABLES;

-- Display table relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'LibraryManagementSystem'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;