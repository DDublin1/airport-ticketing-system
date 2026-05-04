-- =============================================================================
-- Airport Ticketing System - SQL Server Schema
-- =============================================================================
-- Purpose: Relational database for airport operations covering passenger management,
-- flight tracking, ticketing staff operations, and role-based access control.
-- =============================================================================

-- CREATE DATABASE
CREATE DATABASE AirportTicketingSystem;
GO

USE AirportTicketingSystem;
GO

-- =============================================================================
-- Core Tables
-- =============================================================================

-- Employee table for ticketing staff and supervisors
CREATE TABLE EMPLOYEE (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Salt NVARCHAR(64) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Role NVARCHAR(20) CHECK (Role IN ('Ticketing Staff', 'Ticketing Supervisor')) NOT NULL,
    LastLogin DATETIME NULL
);

-- Passenger table with contact information
CREATE TABLE PASSENGER (
    PassengerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    EmergencyContact NVARCHAR(20) NULL
);

-- Flight table with route and capacity information
CREATE TABLE FLIGHT (
    FlightID INT IDENTITY(1,1) PRIMARY KEY,
    FlightNumber NVARCHAR(10) NOT NULL,
    DepartureTime DATETIME NOT NULL,
    ArrivalTime DATETIME NOT NULL,
    Origin CHAR(3) NOT NULL,
    Destination CHAR(3) NOT NULL,
    TotalSeats INT NOT NULL,
    AvailableSeats INT NOT NULL,
    CONSTRAINT CHK_Seats CHECK (AvailableSeats >= 0 AND AvailableSeats <= TotalSeats)
);

-- Reservation table for booking management
CREATE TABLE RESERVATION (
    PNR CHAR(6) PRIMARY KEY,
    PassengerID INT NOT NULL,
    BookingDate DATE NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) CHECK (Status IN ('confirmed', 'pending', 'cancelled')) NOT NULL DEFAULT 'confirmed',
    ItineraryNotes NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Reservation_Passenger FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID) ON DELETE CASCADE
);

-- Seat table for aircraft seating configuration
CREATE TABLE SEAT (
    SeatID INT IDENTITY(1,1) PRIMARY KEY,
    FlightID INT NOT NULL,
    SeatNumber NVARCHAR(10) NOT NULL,
    Class NVARCHAR(20) CHECK (Class IN ('economy', 'business', 'first')) NOT NULL,
    IsPreferred BIT NOT NULL DEFAULT 0,
    PreferredFee DECIMAL(10,2) DEFAULT 30.00,
    CONSTRAINT FK_Seat_Flight FOREIGN KEY (FlightID) REFERENCES FLIGHT(FlightID) ON DELETE CASCADE,
    CONSTRAINT UQ_Seat UNIQUE (FlightID, SeatNumber)
);

-- Ticket table for issued tickets
CREATE TABLE TICKET (
    TicketID INT IDENTITY(1,1) PRIMARY KEY,
    PNR CHAR(6) NOT NULL,
    FlightID INT NOT NULL,
    SeatID INT NOT NULL,
    IssuedBy INT NOT NULL,
    IssueDate DATE NOT NULL DEFAULT GETDATE(),
    IssueTime TIME NOT NULL DEFAULT CONVERT(TIME, GETDATE()),
    BoardingNumber NVARCHAR(20) UNIQUE NOT NULL,
    MealPreference NVARCHAR(20) CHECK (MealPreference IN ('vegetarian', 'non-vegetarian')) NOT NULL,
    MealUpgraded BIT DEFAULT 0,
    IsUpgradedSeat BIT DEFAULT 0,
    BasePrice DECIMAL(10,2) NOT NULL,
    TaxRate DECIMAL(5,2) DEFAULT 20.00,
    TaxAmount AS (BasePrice * TaxRate / 100),
    TotalAmount AS (
        BasePrice + (BasePrice * TaxRate / 100) +
        CASE WHEN MealUpgraded = 1 THEN 20.00 ELSE 0 END +
        CASE WHEN IsPreferred = 1 AND IsUpgradedSeat = 0 THEN PreferredFee ELSE 0 END
    ),
    PreferredFee DECIMAL(10,2) DEFAULT 30.00,
    IsPreferred BIT DEFAULT 0,
    CONSTRAINT FK_Ticket_Reservation FOREIGN KEY (PNR) REFERENCES RESERVATION(PNR) ON DELETE CASCADE,
    CONSTRAINT FK_Ticket_Flight FOREIGN KEY (FlightID) REFERENCES FLIGHT(FlightID),
    CONSTRAINT FK_Ticket_Seat FOREIGN KEY (SeatID) REFERENCES SEAT(SeatID),
    CONSTRAINT FK_Ticket_Employee FOREIGN KEY (IssuedBy) REFERENCES EMPLOYEE(EmployeeID)
);

-- Additional services table for ancillary offerings
CREATE TABLE ADDITIONAL_SERVICES (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    TicketID INT NOT NULL,
    ServiceType NVARCHAR(50) NOT NULL,
    Fee DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Service_Ticket FOREIGN KEY (TicketID) REFERENCES TICKET(TicketID) ON DELETE CASCADE
);

-- Baggage table for luggage tracking
CREATE TABLE BAGGAGE (
    BaggageID INT IDENTITY(1,1) PRIMARY KEY,
    TicketID INT NOT NULL,
    Weight DECIMAL(5,2) NOT NULL,
    CurrentLoc NVARCHAR(50) NULL,
    Status NVARCHAR(20) CHECK (Status IN ('checked-in', 'loaded')) NOT NULL,
    IsExtra BIT DEFAULT 0,
    ExtraFee AS (CASE WHEN IsExtra = 1 THEN Weight * 100 ELSE 0 END),
    CONSTRAINT FK_Baggage_Ticket FOREIGN KEY (TicketID) REFERENCES TICKET(TicketID) ON DELETE CASCADE
);

-- Payment table for financial transactions
CREATE TABLE PAYMENT (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    TicketID INT UNIQUE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('completed', 'pending', 'failed')) NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL,
    TransactionTime DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Payment_Ticket FOREIGN KEY (TicketID) REFERENCES TICKET(TicketID) ON DELETE CASCADE
);

-- Audit log table for security and compliance
CREATE TABLE AUDIT_LOG (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    ActionTime DATETIME NOT NULL DEFAULT GETDATE(),
    ActionType NVARCHAR(50) NOT NULL,
    SupervisorID INT NULL,
    CONSTRAINT FK_Audit_Employee FOREIGN KEY (EmployeeID) REFERENCES EMPLOYEE(EmployeeID),
    CONSTRAINT FK_Audit_Supervisor FOREIGN KEY (SupervisorID) REFERENCES EMPLOYEE(EmployeeID)
);

-- =============================================================================
-- Indexes
-- =============================================================================

CREATE INDEX idx_flight_route ON FLIGHT(Origin, Destination);
CREATE INDEX idx_seat_availability ON SEAT(FlightID, Class, IsPreferred);
CREATE INDEX idx_ticket_boarding ON TICKET(BoardingNumber, IssueDate);

-- =============================================================================
-- Sample Data - Employees
-- =============================================================================

INSERT INTO EMPLOYEE (Username, PasswordHash, Salt, FirstName, LastName, Email, Role)
VALUES
-- Supervisors
('supervisor1', 'hashed_password_1', 'salt1', 'Emily', 'Johnson', 'ejohnson@airport.com', 'Ticketing Supervisor'),
('supervisor2', 'hashed_password_2', 'salt2', 'Michael', 'Chen', 'mchen@airport.com', 'Ticketing Supervisor'),
-- Staff
('agent1', 'hashed_password_3', 'salt3', 'Sarah', 'Williams', 'swilliams@airport.com', 'Ticketing Staff'),
('agent2', 'hashed_password_4', 'salt4', 'David', 'Brown', 'dbrown@airport.com', 'Ticketing Staff'),
('agent3', 'hashed_password_5', 'salt5', 'Jessica', 'Lee', 'jlee@airport.com', 'Ticketing Staff'),
('agent4', 'hashed_password_6', 'salt6', 'Robert', 'Garcia', 'rgarcia@airport.com', 'Ticketing Staff');

-- =============================================================================
-- Sample Data - Passengers
-- =============================================================================

INSERT INTO PASSENGER (FirstName, LastName, Email, DateOfBirth, EmergencyContact)
VALUES
('James', 'Smith', 'jsmith@email.com', '2000-05-15', '555-0101'),
('Olivia', 'Jones', 'ojones@email.com', '1995-08-22', '555-0102'),
('Liam', 'Taylor', 'ltaylor@email.com', '1998-11-30', '555-0103'),
('Emma', 'Wilson', 'ewilson@email.com', '1992-03-10', NULL),
('Noah', 'Davis', 'ndavis@email.com', '1997-07-18', '555-0105'),
('Ava', 'Miller', 'amiller@email.com', '1980-01-25', '555-0106'),
('William', 'Anderson', 'wanderson@email.com', '1978-09-14', '555-0107'),
('Sophia', 'Thomas', 'sthomas@email.com', '1982-12-05', NULL),
('Benjamin', 'Jackson', 'bjackson@email.com', '1975-06-19', '555-0109'),
('Isabella', 'White', 'iwhite@email.com', '1983-04-30', '555-0110'),
('Mason', 'Harris', 'mharris@email.com', '1965-02-11', '555-0111'),
('Charlotte', 'Martin', 'cmartin@email.com', '1960-10-08', NULL),
('Elijah', 'Thompson', 'ethompson@email.com', '1958-07-22', '555-0113'),
('Amelia', 'Martinez', 'amartinez@email.com', '1970-11-15', '555-0114'),
('Lucas', 'Robinson', 'lrobinson@email.com', '1968-09-03', '555-0115'),
('Mia', 'Clark', 'mclark@email.com', '1955-12-27', NULL),
('Henry', 'Rodriguez', 'hrodriguez@email.com', '1963-04-09', '555-0117'),
('Evelyn', 'Lewis', 'elewis@email.com', '1959-08-17', '555-0118');

-- =============================================================================
-- Sample Data - Flights
-- =============================================================================

INSERT INTO FLIGHT (FlightNumber, DepartureTime, ArrivalTime, Origin, Destination, TotalSeats, AvailableSeats)
VALUES
('BA101', '2023-12-15 08:00:00', '2023-12-15 11:00:00', 'LHR', 'JFK', 200, 150),
('BA202', '2023-12-15 14:30:00', '2023-12-15 17:45:00', 'JFK', 'LHR', 200, 180),
('AA345', '2023-12-16 09:15:00', '2023-12-16 12:30:00', 'LAX', 'ORD', 150, 120),
('DL789', '2023-12-17 16:00:00', '2023-12-17 19:20:00', 'ATL', 'MIA', 180, 160),
('UA456', '2023-12-18 07:30:00', '2023-12-18 10:45:00', 'ORD', 'DEN', 160, 140);

-- =============================================================================
-- Sample Data - Seats
-- =============================================================================

DECLARE @Numbers TABLE (Number INT);
WITH Numbers AS (
    SELECT 1 AS Number
    UNION ALL
    SELECT Number + 1 FROM Numbers WHERE Number < 200
)
INSERT INTO @Numbers (Number)
SELECT Number FROM Numbers OPTION (MAXRECURSION 200);

-- Insert seats for Flight 1 (BA101)
INSERT INTO SEAT (FlightID, SeatNumber, Class, IsPreferred, PreferredFee)
SELECT
    1 AS FlightID,
    CASE
        WHEN Number <= 20 THEN CONCAT('F', Number)
        WHEN Number <= 50 THEN CONCAT('B', Number-20)
        ELSE CONCAT('E', Number-50)
    END AS SeatNumber,
    CASE
        WHEN Number <= 20 THEN 'first'
        WHEN Number <= 50 THEN 'business'
        ELSE 'economy'
    END AS Class,
    CASE WHEN Number % 5 = 0 THEN 1 ELSE 0 END AS IsPreferred,
    CASE
        WHEN Number <= 20 THEN 100.00
        WHEN Number <= 50 THEN 50.00
        ELSE 30.00
    END AS PreferredFee
FROM @Numbers
WHERE Number <= 200;

-- Insert seats for Flight 2 (BA202)
INSERT INTO SEAT (FlightID, SeatNumber, Class, IsPreferred, PreferredFee)
SELECT
    2 AS FlightID,
    CASE
        WHEN Number <= 20 THEN CONCAT('F', Number)
        WHEN Number <= 50 THEN CONCAT('B', Number-20)
        ELSE CONCAT('E', Number-50)
    END AS SeatNumber,
    CASE
        WHEN Number <= 20 THEN 'first'
        WHEN Number <= 50 THEN 'business'
        ELSE 'economy'
    END AS Class,
    CASE WHEN Number % 5 = 0 THEN 1 ELSE 0 END AS IsPreferred,
    CASE
        WHEN Number <= 20 THEN 100.00
        WHEN Number <= 50 THEN 50.00
        ELSE 30.00
    END AS PreferredFee
FROM @Numbers
WHERE Number <= 200;

-- =============================================================================
-- Sample Data - Reservations
-- =============================================================================

INSERT INTO RESERVATION (PNR, PassengerID, BookingDate, Status, ItineraryNotes)
VALUES
('ABC123', 1, '2023-11-01', 'confirmed', 'Round trip to New York'),
('DEF456', 2, '2023-11-02', 'confirmed', 'Business class upgrade requested'),
('GHI789', 3, '2023-11-03', 'confirmed', 'Vegetarian meal required'),
('JKL012', 4, '2023-11-04', 'confirmed', 'Window seat preferred'),
('MNO345', 5, '2023-11-05', 'confirmed', 'Traveling with infant'),
('PQR678', 6, '2023-11-06', 'confirmed', 'Connecting flight to Chicago'),
('STU901', 7, '2023-11-07', 'confirmed', 'Extra legroom requested'),
('VWX234', 8, '2023-11-08', 'confirmed', 'Early check-in needed'),
('YZA567', 9, '2023-11-09', 'confirmed', 'Group booking - 4 passengers'),
('BCD890', 10, '2023-11-10', 'confirmed', 'Special assistance required'),
('EFG123', 11, '2023-11-11', 'confirmed', 'Frequent flyer member'),
('HIJ456', 12, '2023-11-12', 'confirmed', 'Corporate account'),
('KLM789', 13, '2023-11-13', 'pending', 'Awaiting payment confirmation'),
('NOP012', 14, '2023-11-14', 'pending', 'Seat selection pending'),
('QRS345', 15, '2023-11-15', 'pending', 'Price match requested'),
('TUV678', 16, '2023-11-16', 'cancelled', 'Changed travel plans'),
('WXY901', 17, '2023-11-17', 'cancelled', 'Flight schedule changed'),
('ZAB234', 18, '2023-11-18', 'cancelled', 'Duplicate booking');

-- =============================================================================
-- Sample Data - Tickets, Baggage, Additional Services, and Payments
-- =============================================================================

DELETE FROM ADDITIONAL_SERVICES;
DELETE FROM BAGGAGE;
DELETE FROM PAYMENT;
DELETE FROM TICKET;

INSERT INTO TICKET (PNR, FlightID, SeatID, IssuedBy, BoardingNumber, MealPreference, BasePrice, IsPreferred)
SELECT TOP 5
    r.PNR,
    1 AS FlightID,
    (
        SELECT TOP 1 s.SeatID
        FROM SEAT s
        WHERE s.FlightID = 1
        AND s.SeatID NOT IN (SELECT SeatID FROM TICKET WHERE SeatID IS NOT NULL)
        ORDER BY s.SeatID
    ) AS SeatID,
    1 AS IssuedBy,
    'BA101-' + LEFT(r.PNR, 3) AS BoardingNumber,
    'non-vegetarian' AS MealPreference,
    400.00 AS BasePrice,
    0 AS IsPreferred
FROM RESERVATION r
WHERE r.Status = 'confirmed';

INSERT INTO BAGGAGE (TicketID, Weight, Status, IsExtra)
SELECT
    TicketID,
    23.0 AS Weight,
    'checked-in' AS Status,
    0 AS IsExtra
FROM TICKET;

INSERT INTO ADDITIONAL_SERVICES (TicketID, ServiceType, Fee)
SELECT TOP 2
    TicketID,
    'Meal Upgrade',
    20.00
FROM TICKET
ORDER BY NEWID();

INSERT INTO ADDITIONAL_SERVICES (TicketID, ServiceType, Fee)
SELECT TOP 1
    TicketID,
    'Preferred Seat',
    30.00
FROM TICKET
WHERE TicketID NOT IN (SELECT TicketID FROM ADDITIONAL_SERVICES WHERE ServiceType = 'Meal Upgrade')
ORDER BY NEWID();

INSERT INTO PAYMENT (TicketID, Amount, Status, PaymentMethod)
SELECT
    TicketID,
    BasePrice + ISNULL((SELECT SUM(Fee) FROM ADDITIONAL_SERVICES WHERE TicketID = t.TicketID), 0),
    'completed',
    CASE (TicketID % 3)
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Debit Card'
        ELSE 'Bank Transfer'
    END
FROM TICKET t;

-- =============================================================================
-- Constraints and Views
-- =============================================================================

-- Future reservations constraint
ALTER TABLE RESERVATION
ADD CONSTRAINT CHK_FutureReservation
CHECK (BookingDate >= CAST(GETDATE() AS DATE));

-- View for senior passengers with pending reservations
CREATE OR ALTER VIEW vw_SeniorPendingPassengers AS
SELECT
    p.*,
    DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
    r.PNR,
    r.Status
FROM PASSENGER p
JOIN RESERVATION r ON p.PassengerID = r.PassengerID
WHERE r.Status = 'pending'
AND DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) > 40;

-- =============================================================================
-- Stored Procedures
-- =============================================================================

-- Search passengers by last name
CREATE OR ALTER PROCEDURE usp_SearchPassengersByName
    @LastName NVARCHAR(50)
AS
BEGIN
    SELECT
        p.PassengerID,
        p.FirstName,
        p.LastName,
        p.Email,
        t.BoardingNumber,
        t.IssueDate,
        f.FlightNumber,
        f.DepartureTime
    FROM PASSENGER p
    LEFT JOIN RESERVATION r ON p.PassengerID = r.PassengerID
    LEFT JOIN TICKET t ON r.PNR = t.PNR
    LEFT JOIN FLIGHT f ON t.FlightID = f.FlightID
    WHERE p.LastName LIKE '%' + @LastName + '%'
    ORDER BY t.IssueDate DESC;
END;
GO

-- Get business class meals for today
CREATE OR ALTER PROCEDURE usp_GetBusinessClassMealsToday
AS
BEGIN
    SELECT
        p.PassengerID,
        p.FirstName + ' ' + p.LastName AS PassengerName,
        t.MealPreference,
        f.FlightNumber,
        t.BoardingNumber,
        s.SeatNumber
    FROM TICKET t
    JOIN RESERVATION r ON t.PNR = r.PNR
    JOIN PASSENGER p ON r.PassengerID = p.PassengerID
    JOIN FLIGHT f ON t.FlightID = f.FlightID
    JOIN SEAT s ON t.SeatID = s.SeatID
    WHERE s.Class = 'business'
    AND CAST(t.IssueDate AS DATE) = CAST(GETDATE() AS DATE);
END;
GO

-- Add new employee
CREATE OR ALTER PROCEDURE usp_AddEmployee
    @Username NVARCHAR(50),
    @Password NVARCHAR(255),
    @Salt NVARCHAR(64),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(100),
    @Role NVARCHAR(20)
AS
BEGIN
    INSERT INTO EMPLOYEE (
        Username, PasswordHash, Salt,
        FirstName, LastName, Email, Role
    )
    VALUES (
        @Username, @Password, @Salt,
        @FirstName, @LastName, @Email, @Role
    );

    SELECT SCOPE_IDENTITY() AS NewEmployeeID;
END;
GO

-- Update passenger information
CREATE OR ALTER PROCEDURE usp_UpdatePassenger
    @PassengerID INT,
    @Email NVARCHAR(100) = NULL,
    @EmergencyContact NVARCHAR(20) = NULL
AS
BEGIN
    UPDATE PASSENGER
    SET
        Email = ISNULL(@Email, Email),
        EmergencyContact = ISNULL(@EmergencyContact, EmergencyContact)
    WHERE PassengerID = @PassengerID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- =============================================================================
-- Views for Reporting
-- =============================================================================

-- Employee revenue summary
CREATE OR ALTER VIEW vw_EmployeeRevenue AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    COUNT(t.TicketID) AS TicketsIssued,
    SUM(t.TotalAmount) AS TotalRevenue,
    SUM(b.ExtraFee) AS BaggageFees,
    SUM(CASE WHEN a.ServiceType = 'Meal Upgrade' THEN a.Fee ELSE 0 END) AS MealUpgrades,
    SUM(CASE WHEN a.ServiceType = 'Preferred Seat' THEN a.Fee ELSE 0 END) AS SeatFees
FROM EMPLOYEE e
LEFT JOIN TICKET t ON e.EmployeeID = t.IssuedBy
LEFT JOIN BAGGAGE b ON t.TicketID = b.TicketID
LEFT JOIN ADDITIONAL_SERVICES a ON t.TicketID = a.TicketID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;
GO

-- Flight capacity alert
CREATE OR ALTER VIEW vw_FlightCapacityAlert AS
SELECT
    f.FlightID,
    f.FlightNumber,
    f.DepartureTime,
    f.Origin,
    f.Destination,
    f.TotalSeats,
    f.AvailableSeats,
    CAST((f.TotalSeats - f.AvailableSeats) AS FLOAT) / f.TotalSeats * 100 AS CapacityPercentage,
    CASE
        WHEN (f.TotalSeats - f.AvailableSeats) / CAST(f.TotalSeats AS FLOAT) >= 0.9 THEN 'CRITICAL'
        WHEN (f.TotalSeats - f.AvailableSeats) / CAST(f.TotalSeats AS FLOAT) >= 0.75 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS AlertLevel
FROM FLIGHT f
WHERE f.DepartureTime BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE());

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update seat preferred status on ticket issue
CREATE OR ALTER TRIGGER trg_UpdateSeatStatus
ON TICKET
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET IsPreferred = 1
    FROM SEAT s
    JOIN inserted i ON s.SeatID = i.SeatID
    WHERE i.IsPreferred = 1;
END;
GO

-- =============================================================================
-- Functions
-- =============================================================================

-- Get count of checked-in baggage for a flight on a specific date
CREATE OR ALTER FUNCTION ufn_GetCheckedBaggageCount(
    @FlightNumber NVARCHAR(10),
    @Date DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(*)
    FROM BAGGAGE b
    JOIN TICKET t ON b.TicketID = t.TicketID
    JOIN FLIGHT f ON t.FlightID = f.FlightID
    WHERE f.FlightNumber = @FlightNumber
    AND CAST(t.IssueDate AS DATE) = @Date
    AND b.Status = 'checked-in';

    RETURN @Count;
END;
GO

-- Get complete travel history for a passenger
CREATE OR ALTER FUNCTION ufn_GetPassengerTravelHistory(
    @PassengerID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        t.TicketID,
        t.BoardingNumber,
        t.IssueDate,
        f.FlightNumber,
        f.Origin,
        f.Destination,
        f.DepartureTime,
        f.ArrivalTime,
        s.SeatNumber,
        s.Class,
        p.Amount AS PaymentAmount,
        p.Status AS PaymentStatus,
        (SELECT COUNT(*) FROM BAGGAGE WHERE TicketID = t.TicketID) AS BagsChecked
    FROM TICKET t
    JOIN RESERVATION r ON t.PNR = r.PNR
    JOIN FLIGHT f ON t.FlightID = f.FlightID
    JOIN SEAT s ON t.SeatID = s.SeatID
    LEFT JOIN PAYMENT p ON t.TicketID = p.TicketID
    WHERE r.PassengerID = @PassengerID
);
GO
