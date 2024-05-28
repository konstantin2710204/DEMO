create database Hotel;

alter database Hotel collate Cyrillic_General_CI_AS;

use Hotel;

create table Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
    Phone NVARCHAR(11) NOT NULL CHECK(Phone LIKE '89%' AND LEN(Phone) = 11),
    Email NVARCHAR(100) NOT NULL,
    PassportSeries INT NOT NULL CHECK(LEN(CAST(PassportSeries AS VARCHAR)) = 4),
    PassportNumber INT NOT NULL CHECK(LEN(CAST(PassportNumber AS VARCHAR)) = 6),
	IssueDate DATE NOT NULL,
    IssuedBy NVARCHAR(100) NOT NULL
);

create table Employees (
	EmployeeID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
	EmployeeType NVARCHAR(50) NOT NULL CHECK (EmployeeType IN('Администратор', 'Горничная', 'Портье', 'Водитель', 'Кухонный персонал', 'Официанты', 'Охранник', 'Главный инженер')),
    BirthDate DATE NOT NULL,
    Phone NVARCHAR(20) NOT NULL CHECK(Phone LIKE '89%' AND LEN(Phone) = 11),
    City NVARCHAR(50) NOT NULL,
    Street NVARCHAR(100) NOT NULL,
    House NVARCHAR(10) NOT NULL,
    Apartment NVARCHAR(10) NOT NULL
);

create table RoomTypes (
	RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
	TypeName NVARCHAR(50) NOT NULL CHECK(TypeName IN ('Эконом-класс', 'Стандарт', 'Полулюкс', 'Люкс', 'Президентский номер')),
	PriceDay DECIMAL(18, 2) NOT NULL CHECK(PriceDay > 0)
);

create table Rooms (
	RoomID INT IDENTITY(1,1) PRIMARY KEY,
	RoomTypeID INT NOT NULL REFERENCES RoomTypes(RoomTypeID),
	Number INT NOT NULL CHECK(Number > 0),
	Floor INT NOT NULL CHECK(Floor > 0),
	Notes NVARCHAR(MAX) NOT NULL,
	Status NVARCHAR(10) NOT NULL CHECK(Status IN('Свободен', 'Занят'))
);

create table Reservations (
	ReservationID INT IDENTITY(1,1) PRIMARY KEY,
	EmployeeID UNIQUEIDENTIFIER NOT NULL REFERENCES Employees(EmployeeID),
	ReservationType NVARCHAR(10) NOT NULL CHECK(ReservationType IN ('Телефон', 'Сайт')),
	ContactInfo NVARCHAR(100) NOT NULL CHECK(ContactInfo LIKE '89%' OR ContactInfo LIKE '%[A-Z0-9]@%[A-Z0-9].%[A-Z0-9]%'),
	ApplicationDate DATE NOT NULL,
	StartDate DATE NOT NULL,
	EndDate DATE NOT NULL,
	Status NVARCHAR(20) NOT NULL CHECK (Status IN ('Оплачено', 'Не оплачено'))
);

create table ReservationDetails (
	ReservationID INT NOT NULL REFERENCES Reservations(ReservationID),
	ClientID INT NOT NULL REFERENCES Clients(ClientID),
	RoomID INT NOT NULL REFERENCES Rooms(RoomID),
);

-- Таблица категорий услуг
CREATE TABLE ServiceCategories (
    ServiceCategoryID INT IDENTITY PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL
);

-- Таблица дополнительных услуг
CREATE TABLE Services (
    ServiceID INT IDENTITY PRIMARY KEY,
    ServiceName NVARCHAR(50) NOT NULL,
    ServiceCategoryID INT NOT NULL REFERENCES ServiceCategories(ServiceCategoryID),
    Price DECIMAL(10, 2) NOT NULL
);

-- Таблица регистрационных карт
CREATE TABLE RegistrationCards (
    RegistrationCardID INT IDENTITY PRIMARY KEY,
    ClientID INT NOT NULL REFERENCES Clients(ClientID),
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    RoomID INT NOT NULL REFERENCES Rooms(RoomID),
    PaymentType NVARCHAR(50) NOT NULL,
);

-- Таблица для связи регистрационных карт и дополнительных услуг
CREATE TABLE RegistrationCardServices (
    RegistrationCardID INT NOT NULL,
    ServiceID INT NOT NULL,
    PRIMARY KEY (RegistrationCardID, ServiceID),
    FOREIGN KEY (RegistrationCardID) REFERENCES RegistrationCards(RegistrationCardID),
    FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID)
);

create table HistoryCost (
	ChangeDate DATETIME DEFAULT GETDATE(),
    ServiceID INT NOT NULL FOREIGN KEY REFERENCES Services(ServiceID),
    OldPrice DECIMAL(18, 2) NOT NULL CHECK (OldPrice > 0),
    NewPrice DECIMAL(18, 2) NOT NULL CHECK (NewPrice > 0)
);

CREATE PROCEDURE ValidateEmails
AS
BEGIN
    SELECT 
        Email, 
        CASE 
            WHEN Email LIKE '%[A-Z0-9]@%[A-Z0-9].%[A-Z0-9]%' AND Email NOT LIKE '%["<>]%' THEN 1
            ELSE 0
        END AS IsValid
    FROM Clients;
END;

CREATE TRIGGER trg_UpdateProductPrice
ON Services
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Price)
    BEGIN
        INSERT INTO HistoryCost (ServiceID, OldPrice, NewPrice)
        SELECT 
            i.ServiceID, 
            d.Price AS OldPrice, 
            i.Price AS NewPrice
        FROM 
            inserted i
        JOIN 
            deleted d ON i.ServiceID = d.ServiceID;
    END
END;

INSERT INTO Clients (FirstName, LastName, MiddleName, Phone, Email, PassportSeries, PassportNumber, IssueDate, IssuedBy) VALUES
('Иван', 'Иванов', 'Иванович', '89123456789', 'ivanov@mail.ru', 1234, 567890, '2020-01-15', 'ОВД Центрального района г. Москвы'),
('Петр', 'Петров', 'Петрович', '89234567890', 'petrov@mail.ru', 2345, 678901, '2019-05-20', 'ОВД Кировского района г. Санкт-Петербурга');

INSERT INTO Employees (FirstName, LastName, MiddleName, EmployeeType, BirthDate, Phone, City, Street, House, Apartment) VALUES
('Анна', 'Смирнова', 'Сергеевна', 'Администратор', '1985-08-25', '89345678901', 'Москва', 'Ленина', '15', '101'),
('Светлана', 'Кузнецова', 'Андреевна', 'Горничная', '1990-02-14', '89456789012', 'Санкт-Петербург', 'Победы', '20', '202');

INSERT INTO RoomTypes (TypeName, PriceDay) VALUES
('Эконом-класс', 2500.00),
('Люкс', 7500.00),
('Стандарт', 3500.00),
('Полулюкс', 5000.00);

INSERT INTO Rooms (RoomTypeID, Number, Floor, Notes, Status) VALUES
(1, 101, 1, 'Окно выходит на улицу', 'Свободен'),
(2, 202, 2, 'Окно выходит во двор', 'Занят'),
(1, 102, 1, 'Окно выходит в сад', 'Свободен'),
(2, 203, 2, 'Окно выходит на парковку', 'Занят');

INSERT INTO Reservations (EmployeeID, ReservationType, ContactInfo, ApplicationDate, StartDate, EndDate, Status) VALUES
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Анна'), 'Телефон', '89123456789', '2024-05-01', '2024-05-10', '2024-05-15', 'Оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Светлана'), 'Сайт', 'petrov@mail.ru', '2024-05-05', '2024-05-12', '2024-05-17', 'Не оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Анна'), 'Телефон', '89234567891', '2024-05-10', '2024-05-20', '2024-05-25', 'Оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Светлана'), 'Сайт', 'ivanov@mail.ru', '2024-05-15', '2024-05-18', '2024-05-23', 'Не оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Анна'), 'Телефон', '89345678902', '2024-05-18', '2024-05-20', '2024-05-25', 'Оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Светлана'), 'Сайт', 'smirnova@mail.ru', '2024-05-20', '2024-05-22', '2024-05-27', 'Не оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Анна'), 'Телефон', '89456789012', '2024-05-22', '2024-05-25', '2024-05-30', 'Оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Светлана'), 'Сайт', 'kuznetsova@mail.ru', '2024-05-25', '2024-05-27', '2024-06-01', 'Не оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Анна'), 'Телефон', '89567890123', '2024-05-27', '2024-05-30', '2024-06-04', 'Оплачено'),
((SELECT TOP 1 EmployeeID FROM Employees WHERE FirstName = 'Светлана'), 'Сайт', 'andreev@mail.ru', '2024-05-30', '2024-06-02', '2024-06-07', 'Не оплачено');

INSERT INTO ReservationDetails (ReservationID, ClientID, RoomID) VALUES
(1, 1, 1),
(2, 2, 2),
(3, 1, 3),
(4, 2, 4),
(5, 1, 1),
(6, 2, 2),
(7, 1, 3),
(8, 2, 4),
(9, 1, 1),
(10, 2, 2);

INSERT INTO ServiceCategories (CategoryName) VALUES
('Спа'),
('Транспорт'),
('Еда и напитки'),
('Уборка'),
('Развлечения');

INSERT INTO Services (ServiceName, ServiceCategoryID, Price) VALUES
('Массаж', 1, 3000.00),
('Трансфер до аэропорта', 2, 1500.00),
('Ужин в номере', 3, 2000.00),
('Уборка номера', 4, 1000.00),
('Посещение бассейна', 5, 500.00),
('Йога', 1, 1200.00),
('Трансфер до вокзала', 2, 1000.00),
('Завтрак в номер', 3, 800.00),
('Химчистка', 4, 1500.00),
('Экскурсия', 5, 2500.00);

INSERT INTO RegistrationCards (ClientID, CheckInDate, CheckOutDate, RoomID, PaymentType) VALUES
(1, '2024-05-10', '2024-05-15', 1, 'Наличные'),
(2, '2024-05-12', '2024-05-17', 2, 'Карта');

INSERT INTO RegistrationCardServices (RegistrationCardID, ServiceID) VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(1, 5),
(2, 6),
(2, 7),
(2, 8),
(2, 9),
(2, 10);

SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    rc.CheckInDate,
    rc.CheckOutDate,
    DATEDIFF(day, rc.CheckInDate, rc.CheckOutDate) * rt.PriceDay + ISNULL(SUM(s.Price), 0) AS TotalAmount
FROM 
    Clients c
JOIN 
    RegistrationCards rc ON c.ClientID = rc.ClientID
JOIN 
    Rooms r ON rc.RoomID = r.RoomID
JOIN 
    RoomTypes rt ON r.RoomTypeID = rt.RoomTypeID
LEFT JOIN 
    RegistrationCardServices rcs ON rc.RegistrationCardID = rcs.RegistrationCardID
LEFT JOIN 
    Services s ON rcs.ServiceID = s.ServiceID
GROUP BY 
    c.ClientID, c.FirstName, c.LastName, rc.CheckInDate, rc.CheckOutDate, rt.PriceDay;



DELETE FROM Services
WHERE ServiceID NOT IN (
    SELECT DISTINCT ServiceID 
    FROM RegistrationCardServices
);

UPDATE RoomTypes
SET PriceDay = PriceDay * 1.15
WHERE RoomTypeID = (
    SELECT TOP 1 RoomTypeID
    FROM ReservationDetails
    JOIN Rooms ON ReservationDetails.RoomID = Rooms.RoomID
    GROUP BY RoomTypeID
    ORDER BY COUNT(*) DESC
);