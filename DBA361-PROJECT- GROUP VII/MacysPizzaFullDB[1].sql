CREATE DATABASE MacysPizza
ON PRIMARY 
    (NAME = MacysPrimary, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\MacysPizzaDB.mdf', SIZE = 50MB, MAXSIZE = 500MB, FILEGROWTH = 10MB),
FILEGROUP MacysSecondary
    (NAME = MacysSecondary, FILENAME = 'C:\Program Files\Microsoft SQL Server\MacysSecondary.ndf', SIZE = 50MB, MAXSIZE = 500MB, FILEGROWTH = 10MB)
LOG ON 
    (NAME = MacysLog, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\MacysPizza_log.ldf', SIZE = 50MB, MAXSIZE = 500MB, FILEGROWTH = 10MB);

USE MacysPizza
GO

CREATE SCHEMA Macys;

CREATE TABLE Macys.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    UserRole NVARCHAR(20) CHECK (UserRole IN ('Admin', 'Staff', 'Customer')) NOT NULL,
) ON MacysSecondary;

CREATE TABLE Macys.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Phone NVARCHAR(20),
) ON MacysSecondary;

CREATE TABLE Macys.Menu (
    MenuItemID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
) ON MacysSecondary;

CREATE TABLE Macys.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    OrderStatus NVARCHAR(20) CHECK (OrderStatus IN ('Pending', 'Processing', 'Completed', 'Cancelled')) DEFAULT 'Pending',
    PaymentMethod NVARCHAR(50),
    FOREIGN KEY (CustomerID) REFERENCES Macys.Customers(CustomerID)
) ON MacysSecondary;

CREATE TABLE Macys.OrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    MenuItemID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    FOREIGN KEY (OrderID) REFERENCES Macys.Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (MenuItemID) REFERENCES Macys.Menu(MenuItemID)
) ON MacysSecondary;

INSERT INTO Macys.Users (Username, Password, UserRole)
VALUES 
    ('admin', 'password123', 'Admin'),
    ('cashier1', 'cashierpass', 'Staff'),
    ('customer1', 'custpass', 'Customer');

INSERT INTO Macys.Customers (Phone)
VALUES 
    ('081 589 658'),
    ('062 245 3369'),
    ('076 225 0128'),
    ('084 675 8919');

INSERT INTO Macys.Menu (Name, Price)
VALUES ('Pepperoni Pizza', 99.99),
       ('Cheese Pizza', 74.99);

INSERT INTO Macys.Orders (CustomerID, OrderStatus)
VALUES (1, 'Pending');

INSERT INTO Macys.OrderItems (OrderID, MenuItemID, Quantity)
VALUES (1, 1, 2);

--Create relevant database views to present simpler interfaces to data tables and restrict access to the sensitive data.

USE MacysPizza;



GO
CREATE VIEW Macys.OrdersView AS
SELECT o.OrderID, o.OrderStatus, c.Phone, m.Name AS MenuItem, oi.Quantity
FROM Macys.Orders o
JOIN Macys.Customers c ON o.CustomerID = c.CustomerID
JOIN Macys.OrderItems oi ON o.OrderID = oi.OrderID
JOIN Macys.Menu m ON oi.MenuItemID = m.MenuItemID;

GO
CREATE VIEW Macys.MenuView AS
SELECT MenuItemID, Name, Price FROM Macys.Menu;

GO
CREATE VIEW Macys.CustomersView AS
SELECT CustomerID, Phone FROM Macys.Customers;

GO
CREATE VIEW Macys.UsersView AS
SELECT Username, UserRole FROM Macys.Users;




--Define the following two database roles and associated permissions and assign specific users to the two roles.

USE MacysPizza;

CREATE ROLE Management;

GRANT SELECT, INSERT, UPDATE ON Macys.OrdersView TO Management;
GRANT SELECT, INSERT, UPDATE ON Macys.MenuView TO Management;
GRANT SELECT ON Macys.CustomersView TO Management;
GRANT SELECT ON Macys.UsersView TO Management;

CREATE ROLE Staff;

GRANT SELECT ON Macys.MenuView TO Staff;
GRANT SELECT ON Macys.OrdersView TO Staff;

--Users assigned to the management role should have read and write access (SELECT, INSERT, UPDATE) to all views except the Users data.

EXEC sp_addrolemember 'Management', 'Staff';

DENY SELECT ON Macys.Users TO Staff;
DENY SELECT ON Macys.Customers TO Staff;
DENY SELECT ON Macys.Menu TO Staff;
DENY SELECT ON Macys.Orders TO Staff;
DENY SELECT ON Macys.OrderItems TO Staff;

SELECT * FROM sys.server_principals WHERE type IN ('S', 'U');
SELECT * FROM sys.database_principals WHERE type IN ('S', 'U');

--Execute the relevant system stored procedures or Dynamic Management Views (DMVs) to document the logins, users and permissions.

SELECT * FROM sys.database_permissions WHERE grantee_principal_id = USER_ID('admin');
SELECT * FROM sys.database_permissions WHERE grantee_principal_id = USER_ID('cashier1');




--Make sure the C:\Backups\ directory exists before running the scripts.
BACKUP DATABASE MacysPizza
TO DISK = 'C:\Backups\MacysPizza_Full.bak'
WITH INIT, NAME = 'Full Backup of MacysPizza';

BACKUP DATABASE MacysPizza
TO DISK = 'C:\Backups\MacysPizza_Diff.bak'
WITH DIFFERENTIAL, INIT, NAME = 'Differential Backup of MacysPizza';

BACKUP DATABASE MacysPizza
FILEGROUP = 'PRIMARY'
TO DISK = 'C:\Backups\MacysPizza_Primary.bak'
WITH FORMAT, INIT, NAME = 'Primary Filegroup Backup';

BACKUP DATABASE MacysPizza
FILEGROUP = 'MacysSecondary'
TO DISK = 'C:\Backups\MacysPizza_Secondary.bak'
WITH FORMAT, INIT, NAME = 'Secondary Filegroup Backup';

BACKUP LOG MacysPizza
TO DISK = 'C:\Backups\MacysPizza_Log.bak'
WITH INIT, NAME = 'Transaction Log Backup';

--This helps monitor file sizes and ensure your filegroups are not running out of space.
EXEC sp_spaceused;
EXEC sp_helpdb 'MacysPizza';

EXEC sp_who2;


DBCC SHOW_STATISTICS ('Macys.Orders', idx_OrderStatus);


