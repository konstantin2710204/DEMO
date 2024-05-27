create database Hotel;

alter database Hotel collate Cyrillic_General_CI_AS;

use Hotel;

create table Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
    Phone NVARCHAR(11) NOT NULL CHECK(Phone LIKE '89%' AND LEN(Phone) = 11),
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PassportSeries INT NOT NULL CHECK(LEN(CAST(PassportSeries AS VARCHAR)) = 4),
    PassportNumber INT NOT NULL CHECK(LEN(CAST(PassportNumber AS VARCHAR)) = 6),
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
	TypeName NVARCHAR(10) NOT NULL CHECK(TypeName IN ('Эконом', 'Комфорт', 'Бизнес', 'VIP', 'Пентхаус', 'Президентский люкс')),
	PriceDay DECIMAL(18, 2) NOT NULL CHECK(PriceDay > 0)
);

create table Rooms (
	RoomID INT IDENTITY(1,1) PRIMARY KEY,
	RoomTypeID INT NOT NULL REFERENCES RoomTypes(RoomTypeID),
	Number INT NOT NULL CHECK(Number > 0),
	Floor INT NOT NULL CHECK(Floor > 0),
	Notes NVARCHAR(MAX) NOT NULL,
	Status NVARCHAR(8) NOT NULL CHECK(Status IN('Свободен', 'Занят'))
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

create table Services (
	ServiceID INT IDENTITY(1,1) PRIMARY KEY,
	TypeName NVARCHAR(20) NOT NULL CHECK(TypeName IN ('Бассейн', 'Массаж', 'Завтрак', 'Обед', 'Ужин', 'Мини-бар', 'All-n-Clusive')),
	EmployeeID UNIQUEIDENTIFIER NOT NULL REFERENCES Employees(EmployeeID),
	Price DECIMAL(18, 2) NOT NULL CHECK (Price > 0)
);

create table ServiceDetails (
	ServiceID INT NOT NULL REFERENCES Services(ServiceID),
	RoomID INT NOT NULL REFERENCES Rooms(RoomID)
);

create table HistoryCost (
	ChangeDate DATETIME DEFAULT GETDATE(),
    RoomTypeID INT NOT NULL FOREIGN KEY REFERENCES RoomTypes(RoomTypeID),
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
ON RoomTypes
AFTER UPDATE
AS
BEGIN
    IF UPDATE(PriceDay)
    BEGIN
        INSERT INTO HistoryCost (RoomTypeID, OldPrice, NewPrice)
        SELECT 
            i.RoomTypeID, 
            d.PriceDay AS OldPrice, 
            i.PriceDay AS NewPrice
        FROM 
            inserted i
        JOIN 
            deleted d ON i.RoomTypeID = d.RoomTypeID;
    END
END;

-- Заполнение таблицы Clients (Клиенты)
INSERT INTO Clients (FirstName, LastName, MiddleName, Phone, Email, PassportSeries, PassportNumber, IssuedBy)
VALUES
('Иван', 'Иванов', 'Иванович', '89101234567', 'ivanov@example.com', 1234, 567890, 'МВД России'),
('Петр', 'Петров', 'Петрович', '89107654321', 'petrov@example.com', 4321, 987654, 'МВД России');

-- Заполнение таблицы Employees (Сотрудники)
INSERT INTO Employees (FirstName, LastName, MiddleName, EmployeeType, BirthDate, Phone, City, Street, House, Apartment)
VALUES
('Анна', 'Сидорова', 'Владимировна', 'Администратор', '1985-03-15', '89105556677', 'Москва', 'Ленина', '10', '12'),
('Сергей', 'Сергеев', 'Сергеевич', 'Горничная', '1990-07-22', '89104443322', 'Санкт-Петербург', 'Невский', '23', '45');

-- Заполнение таблицы RoomTypes (Типы номеров)
INSERT INTO RoomTypes (TypeName, PriceDay)
VALUES
('Эконом', 2000.00),
('Бизнес', 5000.00);

-- Заполнение таблицы Rooms (Номера)
INSERT INTO Rooms (RoomTypeID, Number, Floor, Notes, Status)
VALUES
(1, 101, 1, 'Обычный эконом номер', 'Свободен'),
(2, 202, 2, 'Бизнес номер с видом на парк', 'Занят');

-- Заполнение таблицы Reservations (Бронирования)
INSERT INTO Reservations (EmployeeID, ReservationType, ContactInfo, ApplicationDate, StartDate, EndDate, Status)
VALUES
((SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 'Телефон', '89101234567', '2024-05-01', '2024-06-01', '2024-06-10', 'Оплачено'),
((SELECT EmployeeID FROM Employees WHERE LastName = 'Сергеев'), 'Сайт', '89107654321', '2024-05-10', '2024-06-15', '2024-06-20', 'Не оплачено');

-- Заполнение таблицы ReservationDetails (Детали бронирований)
INSERT INTO ReservationDetails (ReservationID, ClientID, RoomID)
VALUES
(1, 1, 1),
(2, 2, 2);

-- Заполнение таблицы Services (Услуги)
INSERT INTO Services (TypeName, EmployeeID, Price)
VALUES
('Бассейн', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 500.00),
('Массаж', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 1500.00),
('Завтрак', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 300.00),
('Обед', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 500.00),
('Ужин', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 700.00),
('Мини-бар', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 800.00),
('All-n-Clusive', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сидорова'), 2000.00),
('Бассейн', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сергеев'), 500.00),
('Массаж', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сергеев'), 1500.00),
('Завтрак', (SELECT EmployeeID FROM Employees WHERE LastName = 'Сергеев'), 300.00);

-- Заполнение таблицы ServiceDetails (Детали услуг)
INSERT INTO ServiceDetails (ServiceID, RoomID)
VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 2),
(5, 2),
(6, 2);

DELETE FROM Services
WHERE ServiceID NOT IN (SELECT ServiceID FROM ServiceDetails);

UPDATE RoomTypes
SET PriceDay = PriceDay * 1.15
WHERE RoomTypeID = (
    SELECT TOP 1 RoomTypeID
    FROM Reservations
    JOIN ReservationDetails ON Reservations.ReservationID = ReservationDetails.ReservationID
    JOIN Rooms ON ReservationDetails.RoomID = Rooms.RoomID
    GROUP BY RoomTypeID
    ORDER BY COUNT(*) DESC
);

SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    c.MiddleName,
    s.TypeName AS Service,
    SUM(s.Price) AS TotalSpent
FROM 
    Clients c
JOIN 
    ReservationDetails rd ON c.ClientID = rd.ClientID
JOIN 
    Rooms r ON rd.RoomID = r.RoomID
JOIN 
    ServiceDetails sd ON r.RoomID = sd.RoomID
JOIN 
    Services s ON sd.ServiceID = s.ServiceID
GROUP BY 
    c.ClientID,
    c.FirstName,
    c.LastName,
    c.MiddleName,
    s.TypeName
ORDER BY 
    c.ClientID,
    s.TypeName;