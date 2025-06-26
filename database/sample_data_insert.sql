-- ============================================================================
-- 工場設備管理システム - サンプルデータ登録SQL文
-- Azure SQL Database v12 用
-- ============================================================================

USE FactoryManagement;
GO

-- 既存データのクリア（テスト・開発環境用）
-- 本番環境では実行しないでください
DELETE FROM PartUsage;
DELETE FROM AlertHistory;
DELETE FROM AlertRules;
DELETE FROM MaintenanceHistory;
DELETE FROM WorkOrders;
DELETE FROM Parts;
DELETE FROM UserRoles;
DELETE FROM Users;
DELETE FROM Roles;
DELETE FROM Equipment;
GO

-- IDENTITY挿入を有効にする
SET IDENTITY_INSERT Equipment ON;
SET IDENTITY_INSERT Roles ON;
SET IDENTITY_INSERT Users ON;
SET IDENTITY_INSERT Parts ON;
GO

-- ============================================================================
-- 1. 設備マスターデータの挿入
-- ============================================================================
INSERT INTO Equipment (EquipmentId, EquipmentName, EquipmentType, SerialNumber, Manufacturer, Model, Location, InstallationDate, MaintenanceCycleHours, ResponsiblePerson, Status)
VALUES
    (1, N'第1製造ライン主モーター', N'Motor', N'MOT-001-2023', N'東洋電機製造', N'TDK-3000', N'第1工場1階A区画', '2023-01-15', 720, N'田中太郎', N'Active'),
    (2, N'第2製造ライン組立ロボット', N'Robot', N'ROB-002-2023', N'三菱電機', N'RV-20F', N'第1工場1階B区画', '2023-02-20', 1440, N'佐藤花子', N'Active'),
    (3, N'空圧コンプレッサー1号機', N'Compressor', N'COM-003-2023', N'日立産機システム', N'OSP-37.5B', N'第1工場地下1階機械室', '2023-03-10', 2160, N'鈴木一郎', N'Active'),
    (4, N'品質検査装置', N'Inspection', N'INS-004-2023', N'キーエンス', N'IV-X3000', N'第1工場2階品質管理室', '2023-04-05', 8760, N'高橋美咲', N'Active'),
    (5, N'包装機械ライン', N'Packaging', N'PKG-005-2023', N'東洋自動機', N'TJP-500', N'第1工場1階C区画', '2023-05-12', 1080, N'山田次郎', N'Active'),
    (6, N'プレス機1号機', N'Press', N'PRS-006-2022', N'アマダ', N'HFP-1703', N'第2工場1階A区画', '2022-11-15', 480, N'渡辺恵子', N'Maintenance'),
    (7, N'切削加工機CNC', N'CNC', N'CNC-007-2023', N'DMG森精機', N'NHX-5500', N'第2工場1階B区画', '2023-06-20', 720, N'伊藤誠', N'Active'),
    (8, N'搬送ベルトコンベア', N'Conveyor', N'CNV-008-2023', N'椿本チエイン', N'TCC-3000', N'第1工場1階全域', '2023-07-01', 4320, N'加藤健一', N'Active'),
    (9, N'冷却システム', N'Cooling', N'COL-009-2022', N'ダイキン工業', N'AHU-15', N'第1工場屋上', '2022-12-01', 2880, N'松本雅志', N'Active'),
    (10, N'電力制御盤', N'Electrical', N'ELC-010-2023', N'パナソニック', N'ACVF-45K', N'第1工場地下1階電気室', '2023-01-25', 8760, N'小林浩二', N'Active');
GO

-- ============================================================================
-- 2. ロールマスターデータの挿入
-- ============================================================================
INSERT INTO Roles (RoleId, RoleName, Description, Permissions, IsActive)
VALUES
    (1, N'システム管理者', N'システム全体の管理権限を持つ', N'CREATE,READ,UPDATE,DELETE,ADMIN', 1),
    (2, N'工場管理者', N'工場全体の運営管理権限', N'READ,UPDATE,REPORT', 1),
    (3, N'メンテナンス担当者', N'設備メンテナンスに関する権限', N'READ,UPDATE,MAINTENANCE', 1),
    (4, N'品質管理者', N'品質管理に関する権限', N'READ,UPDATE,QUALITY', 1),
    (5, N'現場オペレーター', N'現場での基本操作権限', N'READ,BASIC_UPDATE', 1),
    (6, N'閲覧者', N'データの閲覧のみ可能', N'READ', 1);
GO

-- ============================================================================
-- 3. ユーザーマスターデータの挿入
-- ============================================================================
INSERT INTO Users (UserId, Username, Email, FullName, Department, Position, IsActive)
VALUES
    (1, N'tanaka.taro', N'tanaka.taro@factory.co.jp', N'田中太郎', N'生産技術部', N'主任技師', 1),
    (2, N'sato.hanako', N'sato.hanako@factory.co.jp', N'佐藤花子', N'生産技術部', N'技師', 1),
    (3, N'suzuki.ichiro', N'suzuki.ichiro@factory.co.jp', N'鈴木一郎', N'設備保全部', N'係長', 1),
    (4, N'takahashi.misaki', N'takahashi.misaki@factory.co.jp', N'高橋美咲', N'品質管理部', N'主任', 1),
    (5, N'yamada.jiro', N'yamada.jiro@factory.co.jp', N'山田次郎', N'生産部', N'班長', 1),
    (6, N'watanabe.keiko', N'watanabe.keiko@factory.co.jp', N'渡辺恵子', N'設備保全部', N'技師', 1),
    (7, N'ito.makoto', N'ito.makoto@factory.co.jp', N'伊藤誠', N'生産技術部', N'技師', 1),
    (8, N'kato.kenichi', N'kato.kenichi@factory.co.jp', N'加藤健一', N'設備保全部', N'技師', 1),
    (9, N'matsumoto.masashi', N'matsumoto.masashi@factory.co.jp', N'松本雅志', N'設備保全部', N'係長', 1),
    (10, N'kobayashi.koji', N'kobayashi.koji@factory.co.jp', N'小林浩二', N'電気保全部', N'主任技師', 1),
    (11, N'admin.user', N'admin@factory.co.jp', N'システム管理者', N'情報システム部', N'課長', 1),
    (12, N'manager.factory', N'manager@factory.co.jp', N'工場管理者', N'工場管理部', N'部長', 1);
GO

-- ============================================================================
-- 4. 部品マスターデータの挿入
-- ============================================================================
INSERT INTO Parts (PartId, PartNumber, PartName, Description, Category, UnitCost, StockQuantity, MinStockLevel, Supplier, Location)
VALUES
    (1, N'BRG-001', N'深溝玉軸受け', N'モーター用深溝玉軸受け 6205-2RS サイズ', N'軸受け', 2500.00, 25, 5, N'日本精工株式会社', N'倉庫A-1-03'),
    (2, N'OIL-002', N'潤滑油', N'高温用合成潤滑油 VG46 20Lドラム缶', N'潤滑剤', 15000.00, 8, 2, N'出光興産株式会社', N'倉庫B-2-01'),
    (3, N'FLT-003', N'エアフィルター', N'コンプレッサー用エアフィルター 高効率タイプ', N'フィルター', 8000.00, 12, 3, N'東洋濾紙株式会社', N'倉庫A-2-05'),
    (4, N'BLT-004', N'Vベルト', N'動力伝達用Vベルト A型 長さ1200mm', N'ベルト', 3200.00, 15, 4, N'バンドー化学株式会社', N'倉庫A-1-08'),
    (5, N'SNS-005', N'温度センサー', N'白金測温抵抗体 Pt100 シース型', N'センサー', 12000.00, 6, 2, N'横河電機株式会社', N'倉庫C-1-02'),
    (6, N'GSK-006', N'ガスケット', N'フランジ用ガスケット NBR 厚さ3mm', N'シール材', 800.00, 30, 10, N'NOK株式会社', N'倉庫A-3-01'),
    (7, N'CNT-007', N'電磁接触器', N'三相用電磁接触器 AC100V コイル', N'電気部品', 18000.00, 4, 2, N'三菱電機株式会社', N'倉庫C-2-03'),
    (8, N'HYD-008', N'油圧ホース', N'高圧油圧ホース 1/2インチ 2m', N'ホース', 5500.00, 8, 2, N'横浜ゴム株式会社', N'倉庫B-1-04'),
    (9, N'GRS-009', N'グリース', N'リチウム基グリース 高温用 400gカートリッジ', N'潤滑剤', 1200.00, 20, 8, N'協同油脂株式会社', N'倉庫B-2-02'),
    (10, N'VAL-010', N'電磁弁', N'2ポート電磁弁 AC200V 口径15A', N'バルブ', 25000.00, 3, 1, N'CKD株式会社', N'倉庫C-1-05'),
    (11, N'SWC-011', N'リミットスイッチ', N'ローラレバー型リミットスイッチ IP67', N'センサー', 8500.00, 7, 2, N'オムロン株式会社', N'倉庫C-1-01'),
    (12, N'CHN-012', N'ローラーチェーン', N'RS40 ローラーチェーン 1m単位', N'チェーン', 2800.00, 10, 3, N'椿本チエイン株式会社', N'倉庫A-1-06'),
    (13, N'FUS-013', N'ヒューズ', N'高圧限流ヒューズ 100A 600V', N'電気部品', 6000.00, 12, 4, N'SOC株式会社', N'倉庫C-2-01'),
    (14, N'SPR-014', N'圧縮ばね', N'圧縮コイルばね ステンレス製 線径2mm', N'ばね', 500.00, 40, 15, N'東海バネ工業株式会社', N'倉庫A-3-03'),
    (15, N'MOT-015', N'モーター', N'三相誘導モーター 3.7kW 4P AC200V', N'モーター', 85000.00, 2, 1, N'東芝産業機器システム株式会社', N'倉庫B-3-01');
GO

-- IDENTITY挿入を無効にする
SET IDENTITY_INSERT Equipment OFF;
SET IDENTITY_INSERT Roles OFF;
SET IDENTITY_INSERT Users OFF;
SET IDENTITY_INSERT Parts OFF;
GO

-- ============================================================================
-- 5. ユーザーロール関連データの挿入
-- ============================================================================
INSERT INTO UserRoles (UserId, RoleId, AssignedDate, IsActive)
VALUES
    (11, 1, '2024-01-01', 1), -- システム管理者
    (12, 2, '2024-01-01', 1), -- 工場管理者
    (1, 3, '2024-01-01', 1),  -- 田中太郎：メンテナンス担当者
    (2, 3, '2024-01-01', 1),  -- 佐藤花子：メンテナンス担当者
    (3, 3, '2024-01-01', 1),  -- 鈴木一郎：メンテナンス担当者
    (4, 4, '2024-01-01', 1),  -- 高橋美咲：品質管理者
    (5, 5, '2024-01-01', 1),  -- 山田次郎：現場オペレーター
    (6, 3, '2024-01-01', 1),  -- 渡辺恵子：メンテナンス担当者
    (7, 3, '2024-01-01', 1),  -- 伊藤誠：メンテナンス担当者
    (8, 3, '2024-01-01', 1),  -- 加藤健一：メンテナンス担当者
    (9, 3, '2024-01-01', 1),  -- 松本雅志：メンテナンス担当者
    (10, 3, '2024-01-01', 1); -- 小林浩二：メンテナンス担当者
GO

-- ============================================================================
-- 6. メンテナンス履歴データの挿入
-- ============================================================================
INSERT INTO MaintenanceHistory (EquipmentId, MaintenanceType, MaintenanceDate, WorkDescription, Worker, DurationMinutes, NextScheduledDate, Cost, Priority, Status)
VALUES
    (1, N'Scheduled', '2024-01-15 09:00:00', N'第1製造ライン主モーターの定期点検。ベアリング状態確認、潤滑油交換、電流値測定を実施。異常は確認されず、次回メンテナンス予定日を設定。', N'田中太郎', 120, '2024-04-15', 15000.00, N'Medium', N'Completed'),
    (2, N'Preventive', '2024-01-20 14:30:00', N'第2製造ライン組立ロボットの予防保全。アーム動作精度確認、センサー校正、グリス補充を実施。動作に軽微な誤差を検出したため調整済み。', N'佐藤花子', 180, '2024-07-20', 25000.00, N'High', N'Completed'),
    (3, N'Scheduled', '2024-01-25 08:00:00', N'空圧コンプレッサー1号機の定期メンテナンス。フィルター交換、ドレン排出、圧力調整弁点検を実施。すべて正常動作を確認。', N'鈴木一郎', 90, '2024-07-25', 8000.00, N'Medium', N'Completed'),
    (4, N'Scheduled', '2024-02-01 10:00:00', N'品質検査装置の年次点検。光学系清掃、カメラキャリブレーション、測定精度確認を実施。基準値内で動作していることを確認。', N'高橋美咲', 240, '2025-02-01', 35000.00, N'High', N'Completed'),
    (5, N'Emergency', '2024-02-05 16:45:00', N'包装機械ラインの緊急修理。包装フィルム送り機構の故障により包装不良が発生。モーター交換とベルト調整を実施し復旧完了。', N'山田次郎', 300, '2024-05-05', 45000.00, N'Critical', N'Completed'),
    (6, N'Scheduled', '2024-02-10 13:00:00', N'プレス機1号機の定期オーバーホール。油圧システム点検、金型精度確認、安全装置動作試験を実施中。部品交換が必要なため継続作業。', N'渡辺恵子', 480, '2024-08-10', 80000.00, N'High', N'InProgress'),
    (7, N'Preventive', '2024-02-12 11:15:00', N'切削加工機CNCの予防保全。スピンドル振動測定、切削液交換、工具摩耗状況確認を実施。振動値が基準値上限近くのため経過観察。', N'伊藤誠', 150, '2024-05-12', 22000.00, N'Medium', N'Completed'),
    (8, N'Scheduled', '2024-02-15 09:30:00', N'搬送ベルトコンベアの半年点検。ベルト張力調整、ローラー清掃、駆動モーター点検を実施。1箇所でベルト表面に軽微な損傷確認、要経過観察。', N'加藤健一', 200, '2024-08-15', 18000.00, N'Medium', N'Completed'),
    (9, N'Scheduled', '2024-02-18 15:00:00', N'冷却システムの季節メンテナンス。冷媒量確認、フィルター交換、温度制御精度点検を実施。冬季運転モードへの切り替え完了。', N'松本雅志', 120, '2024-05-18', 12000.00, N'Medium', N'Completed'),
    (10, N'Scheduled', '2024-02-20 08:45:00', N'電力制御盤の年次点検。端子台締付け確認、絶縁抵抗測定、保護継電器動作試験を実施。すべて基準値内で良好な状態を確認。', N'小林浩二', 180, '2025-02-20', 20000.00, N'High', N'Completed'),
    (1, N'Preventive', '2024-03-01 10:00:00', N'第1製造ライン主モーターの振動測定と軸受け交換作業を予定。前回点検での軽微な振動増加を受けての予防的措置。', N'田中太郎', 240, '2024-06-01', 30000.00, N'High', N'Scheduled'),
    (3, N'Scheduled', '2024-03-15 14:00:00', N'空圧コンプレッサー1号機の四半期定期点検。オイル交換、エアフィルター清掃、安全弁動作確認を予定。', N'鈴木一郎', 120, '2024-06-15', 15000.00, N'Medium', N'Scheduled');
GO

-- ============================================================================
-- 7. 作業指示データの挿入
-- ============================================================================
INSERT INTO WorkOrders (EquipmentId, WorkOrderNumber, Title, Description, Priority, Status, ScheduledDate, AssignedTechnician, EstimatedCost)
VALUES
    (1, N'WO-2024-001', N'モーター軸受け交換', N'第1製造ライン主モーターの軸受け交換作業。振動値上昇のため予防的交換を実施。', N'High', N'Assigned', '2024-03-01 10:00:00', N'田中太郎', 30000.00),
    (6, N'WO-2024-002', N'プレス機オーバーホール', N'プレス機1号機の定期オーバーホール作業。油圧システム点検と部品交換。', N'High', N'InProgress', '2024-02-10 13:00:00', N'渡辺恵子', 80000.00),
    (3, N'WO-2024-003', N'コンプレッサー定期点検', N'空圧コンプレッサー1号機の四半期定期点検作業。', N'Medium', N'Created', '2024-03-15 14:00:00', N'鈴木一郎', 15000.00),
    (8, N'WO-2024-004', N'コンベアベルト交換', N'搬送ベルトコンベアの損傷部分ベルト交換作業。', N'Medium', N'Created', '2024-03-20 09:00:00', N'加藤健一', 25000.00),
    (5, N'WO-2024-005', N'包装機センサー調整', N'包装機械ラインのセンサー感度調整作業。', N'Low', N'Created', '2024-03-25 13:30:00', N'山田次郎', 5000.00);
GO

-- ============================================================================
-- 8. アラート定義データの挿入
-- ============================================================================
INSERT INTO AlertRules (EquipmentId, MetricName, Operator, ThresholdValue, DurationMinutes, Severity, IsEnabled, NotificationMethod, Recipients)
VALUES
    (1, N'temperature', N'>', 85.0, 5, N'Critical', 1, N'email', N'tanaka.taro@factory.co.jp,manager@factory.co.jp'),
    (1, N'vibration', N'>', 5.0, 10, N'High', 1, N'email', N'tanaka.taro@factory.co.jp'),
    (2, N'temperature', N'>', 80.0, 5, N'High', 1, N'email', N'sato.hanako@factory.co.jp'),
    (3, N'pressure', N'>', 8.0, 5, N'Critical', 1, N'email', N'suzuki.ichiro@factory.co.jp,manager@factory.co.jp'),
    (3, N'pressure', N'<', 2.0, 3, N'High', 1, N'email', N'suzuki.ichiro@factory.co.jp'),
    (4, N'temperature', N'>', 70.0, 15, N'Medium', 1, N'email', N'takahashi.misaki@factory.co.jp'),
    (5, N'vibration', N'>', 4.0, 5, N'High', 1, N'email', N'yamada.jiro@factory.co.jp'),
    (6, N'pressure', N'>', 12.0, 5, N'Critical', 1, N'email', N'watanabe.keiko@factory.co.jp,manager@factory.co.jp'),
    (7, N'temperature', N'>', 90.0, 5, N'Critical', 1, N'email', N'ito.makoto@factory.co.jp,manager@factory.co.jp'),
    (8, N'current', N'>', 15.0, 10, N'Medium', 1, N'email', N'kato.kenichi@factory.co.jp'),
    (9, N'temperature', N'>', 35.0, 5, N'High', 1, N'email', N'matsumoto.masashi@factory.co.jp'),
    (10, N'voltage', N'<', 190.0, 2, N'Critical', 1, N'email', N'kobayashi.koji@factory.co.jp,manager@factory.co.jp');
GO

-- ============================================================================
-- 9. アラート履歴データの挿入（サンプル）
-- ============================================================================
INSERT INTO AlertHistory (AlertRuleId, EquipmentId, AlertTime, MetricName, ActualValue, ThresholdValue, Severity, Status, AcknowledgedTime, AcknowledgedBy, Resolution)
VALUES
    (2, 1, '2024-02-22 14:30:00', N'vibration', 5.2, 5.0, N'High', N'Resolved', '2024-02-22 14:45:00', N'田中太郎', N'軸受け点検実施。異常なし。センサー校正により正常値に復帰。'),
    (5, 3, '2024-02-20 09:15:00', N'pressure', 1.8, 2.0, N'High', N'Resolved', '2024-02-20 09:30:00', N'鈴木一郎', N'圧力調整弁を調整。正常圧力に復帰。'),
    (7, 5, '2024-02-18 16:20:00', N'vibration', 4.3, 4.0, N'High', N'Acknowledged', '2024-02-18 16:35:00', N'山田次郎', N'継続監視中。次回メンテナンス時に詳細点検予定。'),
    (11, 9, '2024-02-15 11:45:00', N'temperature', 37.2, 35.0, N'High', N'Resolved', '2024-02-15 12:00:00', N'松本雅志', N'冷媒不足が原因。冷媒補充により正常温度に復帰。');
GO

-- ============================================================================
-- 10. 部品使用履歴データの挿入
-- ============================================================================
INSERT INTO PartUsage (MaintenanceId, PartId, QuantityUsed, UnitCost, UsageDate)
VALUES
    (1, 2, 1, 15000.00, '2024-01-15 09:30:00'), -- 潤滑油使用
    (1, 1, 2, 2500.00, '2024-01-15 10:15:00'),  -- 軸受け使用
    (2, 9, 3, 1200.00, '2024-01-20 15:00:00'),  -- グリース使用
    (3, 3, 1, 8000.00, '2024-01-25 08:30:00'),  -- エアフィルター使用
    (3, 2, 1, 15000.00, '2024-01-25 09:00:00'), -- 潤滑油使用
    (4, 5, 1, 12000.00, '2024-02-01 11:00:00'), -- 温度センサー使用
    (5, 15, 1, 85000.00, '2024-02-05 17:00:00'), -- モーター交換
    (5, 4, 2, 3200.00, '2024-02-05 18:30:00'),  -- Vベルト使用
    (7, 2, 1, 15000.00, '2024-02-12 12:00:00'), -- 潤滑油使用
    (8, 4, 1, 3200.00, '2024-02-15 10:30:00'),  -- Vベルト使用
    (8, 12, 2, 2800.00, '2024-02-15 11:00:00'), -- チェーン使用
    (9, 3, 1, 8000.00, '2024-02-18 15:30:00'),  -- エアフィルター使用
    (10, 13, 2, 6000.00, '2024-02-20 09:30:00'), -- ヒューズ使用
    (10, 7, 1, 18000.00, '2024-02-20 10:00:00'); -- 電磁接触器使用
GO

-- ============================================================================
-- データ挿入完了メッセージ
-- ============================================================================
PRINT '============================================================================';
PRINT 'サンプルデータの挿入が完了しました。';
PRINT '============================================================================';
PRINT '挿入されたデータ:';
PRINT '- 設備マスター: 10件';
PRINT '- ユーザー: 12件';
PRINT '- ロール: 6件';
PRINT '- ユーザーロール関連: 12件';
PRINT '- 部品マスター: 15件';
PRINT '- メンテナンス履歴: 12件';
PRINT '- 作業指示: 5件';
PRINT '- アラート定義: 12件';
PRINT '- アラート履歴: 4件';
PRINT '- 部品使用履歴: 14件';
PRINT '============================================================================';

-- データ確認用クエリ例
PRINT '設備別メンテナンス履歴確認:';
SELECT 
    e.EquipmentName,
    COUNT(mh.MaintenanceId) as MaintenanceCount,
    MAX(mh.MaintenanceDate) as LastMaintenance,
    MAX(mh.NextScheduledDate) as NextScheduled
FROM Equipment e
LEFT JOIN MaintenanceHistory mh ON e.EquipmentId = mh.EquipmentId
GROUP BY e.EquipmentId, e.EquipmentName
ORDER BY e.EquipmentId;

PRINT '';
PRINT 'アクティブアラート確認:';
SELECT 
    e.EquipmentName,
    ah.MetricName,
    ah.Severity,
    ah.Status,
    ah.AlertTime
FROM AlertHistory ah
INNER JOIN Equipment e ON ah.EquipmentId = e.EquipmentId
WHERE ah.Status IN ('Active', 'Acknowledged')
ORDER BY ah.AlertTime DESC;