-- ============================================================================
-- 工場設備管理システム - Azure SQL Database v12 テーブル作成SQL文
-- ============================================================================

-- データベース照合順序設定（日本語対応）
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FactoryManagement')
BEGIN
    CREATE DATABASE FactoryManagement
    COLLATE Japanese_CI_AS;
END
GO

USE FactoryManagement;
GO

-- ============================================================================
-- 1. 設備マスターテーブル（Equipment）
-- ============================================================================
IF OBJECT_ID('Equipment', 'U') IS NOT NULL
    DROP TABLE Equipment;
GO

CREATE TABLE Equipment (
    EquipmentId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentName NVARCHAR(100) NOT NULL,
    EquipmentType NVARCHAR(50) NOT NULL,
    SerialNumber NVARCHAR(50) UNIQUE,
    Manufacturer NVARCHAR(100),
    Model NVARCHAR(100),
    Location NVARCHAR(100) NOT NULL,
    InstallationDate DATE NOT NULL,
    MaintenanceCycleHours INT NOT NULL,
    ResponsiblePerson NVARCHAR(100),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Maintenance', 'Retired')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- 設備マスターテーブルのインデックス
CREATE INDEX IX_Equipment_Type_Location ON Equipment (EquipmentType, Location);
CREATE INDEX IX_Equipment_Status ON Equipment (Status);
CREATE INDEX IX_Equipment_ResponsiblePerson ON Equipment (ResponsiblePerson);
GO

-- ============================================================================
-- 2. メンテナンス履歴テーブル（MaintenanceHistory）
-- ============================================================================
IF OBJECT_ID('MaintenanceHistory', 'U') IS NOT NULL
    DROP TABLE MaintenanceHistory;
GO

CREATE TABLE MaintenanceHistory (
    MaintenanceId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT NOT NULL,
    MaintenanceType NVARCHAR(50) NOT NULL CHECK (MaintenanceType IN ('Scheduled', 'Emergency', 'Preventive')),
    MaintenanceDate DATETIME2 NOT NULL,
    WorkDescription NVARCHAR(MAX),
    Worker NVARCHAR(100),
    DurationMinutes INT,
    NextScheduledDate DATE,
    Cost DECIMAL(10,2),
    Priority NVARCHAR(20) CHECK (Priority IN ('Low', 'Medium', 'High', 'Critical')),
    Status NVARCHAR(20) DEFAULT 'Completed' CHECK (Status IN ('Scheduled', 'InProgress', 'Completed')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (EquipmentId) REFERENCES Equipment(EquipmentId)
);
GO

-- メンテナンス履歴テーブルのインデックス
CREATE INDEX IX_MaintenanceHistory_Date_Equipment ON MaintenanceHistory (MaintenanceDate DESC, EquipmentId);
CREATE INDEX IX_MaintenanceHistory_Type ON MaintenanceHistory (MaintenanceType);
CREATE INDEX IX_MaintenanceHistory_Status ON MaintenanceHistory (Status);
GO

-- ============================================================================
-- 3. 作業指示テーブル（WorkOrders）
-- ============================================================================
IF OBJECT_ID('WorkOrders', 'U') IS NOT NULL
    DROP TABLE WorkOrders;
GO

CREATE TABLE WorkOrders (
    WorkOrderId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT NOT NULL,
    WorkOrderNumber NVARCHAR(50) UNIQUE NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    Priority NVARCHAR(20) CHECK (Priority IN ('Low', 'Medium', 'High', 'Critical')),
    Status NVARCHAR(20) DEFAULT 'Created' CHECK (Status IN ('Created', 'Assigned', 'InProgress', 'Completed', 'Cancelled')),
    ScheduledDate DATETIME2,
    StartDate DATETIME2,
    CompletionDate DATETIME2,
    AssignedTechnician NVARCHAR(100),
    EstimatedCost DECIMAL(10,2),
    ActualCost DECIMAL(10,2),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (EquipmentId) REFERENCES Equipment(EquipmentId)
);
GO

-- 作業指示テーブルのインデックス
CREATE INDEX IX_WorkOrders_Status_Priority ON WorkOrders (Status, Priority);
CREATE INDEX IX_WorkOrders_ScheduledDate ON WorkOrders (ScheduledDate);
CREATE INDEX IX_WorkOrders_AssignedTechnician ON WorkOrders (AssignedTechnician);
GO

-- ============================================================================
-- 4. 部品マスターテーブル（Parts）
-- ============================================================================
IF OBJECT_ID('Parts', 'U') IS NOT NULL
    DROP TABLE Parts;
GO

CREATE TABLE Parts (
    PartId INT PRIMARY KEY IDENTITY(1,1),
    PartNumber NVARCHAR(50) UNIQUE NOT NULL,
    PartName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    Category NVARCHAR(50),
    UnitCost DECIMAL(10,2),
    StockQuantity INT DEFAULT 0,
    MinStockLevel INT DEFAULT 0,
    Supplier NVARCHAR(100),
    Location NVARCHAR(100),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- 部品マスターテーブルのインデックス
CREATE INDEX IX_Parts_Category ON Parts (Category);
CREATE INDEX IX_Parts_Supplier ON Parts (Supplier);
CREATE INDEX IX_Parts_StockLevel ON Parts (StockQuantity, MinStockLevel);
GO

-- ============================================================================
-- 5. 部品使用履歴テーブル（PartUsage）
-- ============================================================================
IF OBJECT_ID('PartUsage', 'U') IS NOT NULL
    DROP TABLE PartUsage;
GO

CREATE TABLE PartUsage (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    MaintenanceId INT NOT NULL,
    PartId INT NOT NULL,
    QuantityUsed INT NOT NULL,
    UnitCost DECIMAL(10,2),
    TotalCost AS (QuantityUsed * UnitCost) PERSISTED,
    UsageDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (MaintenanceId) REFERENCES MaintenanceHistory(MaintenanceId),
    FOREIGN KEY (PartId) REFERENCES Parts(PartId)
);
GO

-- 部品使用履歴テーブルのインデックス
CREATE INDEX IX_PartUsage_MaintenanceId ON PartUsage (MaintenanceId);
CREATE INDEX IX_PartUsage_PartId ON PartUsage (PartId);
CREATE INDEX IX_PartUsage_UsageDate ON PartUsage (UsageDate);
GO

-- ============================================================================
-- 6. アラート定義テーブル（AlertRules）
-- ============================================================================
IF OBJECT_ID('AlertRules', 'U') IS NOT NULL
    DROP TABLE AlertRules;
GO

CREATE TABLE AlertRules (
    AlertRuleId INT PRIMARY KEY IDENTITY(1,1),
    EquipmentId INT NOT NULL,
    MetricName NVARCHAR(50) NOT NULL,
    Operator NVARCHAR(10) NOT NULL CHECK (Operator IN ('>', '<', '>=', '<=', '=')),
    ThresholdValue DECIMAL(10,3) NOT NULL,
    DurationMinutes INT DEFAULT 0,
    Severity NVARCHAR(20) CHECK (Severity IN ('Low', 'Medium', 'High', 'Critical')),
    IsEnabled BIT DEFAULT 1,
    NotificationMethod NVARCHAR(50),
    Recipients NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (EquipmentId) REFERENCES Equipment(EquipmentId)
);
GO

-- アラート定義テーブルのインデックス
CREATE INDEX IX_AlertRules_Equipment_Enabled ON AlertRules (EquipmentId, IsEnabled);
CREATE INDEX IX_AlertRules_MetricName ON AlertRules (MetricName);
CREATE INDEX IX_AlertRules_Severity ON AlertRules (Severity);
GO

-- ============================================================================
-- 7. アラート履歴テーブル（AlertHistory）
-- ============================================================================
IF OBJECT_ID('AlertHistory', 'U') IS NOT NULL
    DROP TABLE AlertHistory;
GO

CREATE TABLE AlertHistory (
    AlertId INT PRIMARY KEY IDENTITY(1,1),
    AlertRuleId INT NOT NULL,
    EquipmentId INT NOT NULL,
    AlertTime DATETIME2 NOT NULL,
    MetricName NVARCHAR(50) NOT NULL,
    ActualValue DECIMAL(10,3) NOT NULL,
    ThresholdValue DECIMAL(10,3) NOT NULL,
    Severity NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Acknowledged', 'Resolved')),
    AcknowledgedTime DATETIME2,
    AcknowledgedBy NVARCHAR(100),
    Resolution NVARCHAR(MAX),
    ResolvedTime DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (AlertRuleId) REFERENCES AlertRules(AlertRuleId),
    FOREIGN KEY (EquipmentId) REFERENCES Equipment(EquipmentId)
);
GO

-- アラート履歴テーブルのインデックス
CREATE INDEX IX_AlertHistory_Status_Severity_Time ON AlertHistory (Status, Severity, AlertTime DESC);
CREATE INDEX IX_AlertHistory_Equipment ON AlertHistory (EquipmentId);
CREATE INDEX IX_AlertHistory_AlertTime ON AlertHistory (AlertTime DESC);
GO

-- ============================================================================
-- 8. ユーザーマスターテーブル（Users）
-- ============================================================================
IF OBJECT_ID('Users', 'U') IS NOT NULL
    DROP TABLE Users;
GO

CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) UNIQUE NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Department NVARCHAR(50),
    Position NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    LastLoginDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- ユーザーマスターテーブルのインデックス
CREATE INDEX IX_Users_Department ON Users (Department);
CREATE INDEX IX_Users_IsActive ON Users (IsActive);
CREATE INDEX IX_Users_LastLogin ON Users (LastLoginDate DESC);
GO

-- ============================================================================
-- 9. ロールマスターテーブル（Roles）
-- ============================================================================
IF OBJECT_ID('Roles', 'U') IS NOT NULL
    DROP TABLE Roles;
GO

CREATE TABLE Roles (
    RoleId INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(200),
    Permissions NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 10. ユーザーロール関連テーブル（UserRoles）
-- ============================================================================
IF OBJECT_ID('UserRoles', 'U') IS NOT NULL
    DROP TABLE UserRoles;
GO

CREATE TABLE UserRoles (
    UserRoleId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    AssignedDate DATETIME2 DEFAULT GETDATE(),
    ExpiryDate DATETIME2,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    UNIQUE (UserId, RoleId)
);
GO

-- ユーザーロール関連テーブルのインデックス
CREATE INDEX IX_UserRoles_UserId ON UserRoles (UserId);
CREATE INDEX IX_UserRoles_RoleId ON UserRoles (RoleId);
CREATE INDEX IX_UserRoles_Active ON UserRoles (IsActive);
GO

-- ============================================================================
-- トリガー設定（UpdatedAt自動更新）
-- ============================================================================

-- Equipment テーブル用トリガー
CREATE TRIGGER TR_Equipment_UpdatedAt
ON Equipment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Equipment 
    SET UpdatedAt = GETDATE()
    FROM Equipment e
    INNER JOIN inserted i ON e.EquipmentId = i.EquipmentId;
END
GO

-- WorkOrders テーブル用トリガー
CREATE TRIGGER TR_WorkOrders_UpdatedAt
ON WorkOrders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE WorkOrders 
    SET UpdatedAt = GETDATE()
    FROM WorkOrders w
    INNER JOIN inserted i ON w.WorkOrderId = i.WorkOrderId;
END
GO

-- Parts テーブル用トリガー
CREATE TRIGGER TR_Parts_UpdatedAt
ON Parts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Parts 
    SET UpdatedAt = GETDATE()
    FROM Parts p
    INNER JOIN inserted i ON p.PartId = i.PartId;
END
GO

-- AlertRules テーブル用トリガー
CREATE TRIGGER TR_AlertRules_UpdatedAt
ON AlertRules
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AlertRules 
    SET UpdatedAt = GETDATE()
    FROM AlertRules ar
    INNER JOIN inserted i ON ar.AlertRuleId = i.AlertRuleId;
END
GO

-- Users テーブル用トリガー
CREATE TRIGGER TR_Users_UpdatedAt
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users 
    SET UpdatedAt = GETDATE()
    FROM Users u
    INNER JOIN inserted i ON u.UserId = i.UserId;
END
GO

-- Roles テーブル用トリガー
CREATE TRIGGER TR_Roles_UpdatedAt
ON Roles
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Roles 
    SET UpdatedAt = GETDATE()
    FROM Roles r
    INNER JOIN inserted i ON r.RoleId = i.RoleId;
END
GO

-- ============================================================================
-- ビュー作成（よく使用されるクエリの効率化）
-- ============================================================================

-- 設備とメンテナンス履歴の結合ビュー
CREATE VIEW VW_Equipment_Maintenance AS
SELECT 
    e.EquipmentId,
    e.EquipmentName,
    e.EquipmentType,
    e.Location,
    e.Status as EquipmentStatus,
    e.ResponsiblePerson,
    mh.MaintenanceId,
    mh.MaintenanceType,
    mh.MaintenanceDate,
    mh.NextScheduledDate,
    mh.Cost as MaintenanceCost,
    mh.Status as MaintenanceStatus
FROM Equipment e
LEFT JOIN MaintenanceHistory mh ON e.EquipmentId = mh.EquipmentId;
GO

-- アクティブアラートビュー
CREATE VIEW VW_Active_Alerts AS
SELECT 
    ah.AlertId,
    e.EquipmentName,
    e.Location,
    ah.MetricName,
    ah.Severity,
    ah.ActualValue,
    ah.ThresholdValue,
    ah.AlertTime,
    ah.Status,
    DATEDIFF(MINUTE, ah.AlertTime, GETDATE()) as MinutesSinceAlert
FROM AlertHistory ah
INNER JOIN Equipment e ON ah.EquipmentId = e.EquipmentId
WHERE ah.Status IN ('Active', 'Acknowledged');
GO

-- 設備稼働状況サマリービュー
CREATE VIEW VW_Equipment_Summary AS
SELECT 
    e.EquipmentId,
    e.EquipmentName,
    e.EquipmentType,
    e.Location,
    e.Status,
    (SELECT COUNT(*) FROM MaintenanceHistory mh WHERE mh.EquipmentId = e.EquipmentId AND mh.MaintenanceDate >= DATEADD(MONTH, -1, GETDATE())) as MaintenanceCountLastMonth,
    (SELECT COUNT(*) FROM AlertHistory ah WHERE ah.EquipmentId = e.EquipmentId AND ah.AlertTime >= DATEADD(WEEK, -1, GETDATE()) AND ah.Severity IN ('High', 'Critical')) as CriticalAlertsLastWeek,
    (SELECT TOP 1 mh.NextScheduledDate FROM MaintenanceHistory mh WHERE mh.EquipmentId = e.EquipmentId ORDER BY mh.MaintenanceDate DESC) as NextMaintenanceDate
FROM Equipment e
WHERE e.Status = 'Active';
GO

PRINT 'Azure SQL Database v12 テーブル作成が完了しました。';
PRINT '作成されたテーブル: Equipment, MaintenanceHistory, WorkOrders, Parts, PartUsage, AlertRules, AlertHistory, Users, Roles, UserRoles';
PRINT '作成されたビュー: VW_Equipment_Maintenance, VW_Active_Alerts, VW_Equipment_Summary';
PRINT 'インデックスとトリガーも正常に作成されました。';