/*
    Booking System - Full SQL Setup (SQL Server)
    Copy all and run in SSMS.

    This script will:
    1) Create database BookingSystem if not exists
    2) Create tables [User], Booking, Doctor, DoctorDuty
    3) Create constraints and indexes
    4) Seed demo users, bác sĩ và mẫu lịch

    Notes:
    - Table/column names match Java code exactly.
    - From now on, update SQL directly in this file only.
*/

SET NOCOUNT ON;
GO

/* =============================
   1) CREATE DATABASE
   ============================= */
IF DB_ID('BookingSystem') IS NULL
BEGIN
    CREATE DATABASE BookingSystem;
END
GO

USE BookingSystem;
GO

/* =============================
   2) OPTIONAL CLEANUP (UNCOMMENT IF YOU WANT RESET)
   =============================
-- IF OBJECT_ID('dbo.Booking', 'U') IS NOT NULL DROP TABLE dbo.Booking;
-- IF OBJECT_ID('dbo.DoctorDuty', 'U') IS NOT NULL DROP TABLE dbo.DoctorDuty;
-- IF OBJECT_ID('dbo.Doctor', 'U') IS NOT NULL DROP TABLE dbo.Doctor;
-- IF OBJECT_ID('dbo.[User]', 'U') IS NOT NULL DROP TABLE dbo.[User];
*/

/* =============================
   3) TABLE: USER
   ============================= */
IF OBJECT_ID('dbo.[User]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[User] (
        id INT IDENTITY(1,1) NOT NULL,
        username VARCHAR(50) NOT NULL,
        [password] VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL,
        CONSTRAINT PK_User PRIMARY KEY (id),
        CONSTRAINT UQ_User_Username UNIQUE (username),
        CONSTRAINT CK_User_Role CHECK (role IN ('user', 'admin'))
    );
END
GO

/* =============================
   4) TABLE: BOOKING
   ============================= */
IF OBJECT_ID('dbo.Booking', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Booking (
        id INT IDENTITY(1,1) NOT NULL,
        user_id INT NOT NULL,
        booking_date DATE NOT NULL,
        start_time TIME(0) NOT NULL,
        end_time TIME(0) NOT NULL,
        status VARCHAR(20) NOT NULL,

        CONSTRAINT PK_Booking PRIMARY KEY (id),
        CONSTRAINT FK_Booking_User FOREIGN KEY (user_id) REFERENCES dbo.[User](id),
        CONSTRAINT CK_Booking_Status CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
        CONSTRAINT CK_Booking_TimeRange CHECK (start_time < end_time)
    );
END
GO

/* =============================
   4.1) TABLE: DOCTOR
   ============================= */
IF OBJECT_ID('dbo.Doctor', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Doctor (
        id INT IDENTITY(1,1) NOT NULL,
        full_name NVARCHAR(100) NOT NULL,
        specialty NVARCHAR(100) NULL,
        is_active BIT NOT NULL CONSTRAINT DF_Doctor_IsActive DEFAULT (1),
        CONSTRAINT PK_Doctor PRIMARY KEY (id),
        CONSTRAINT UQ_Doctor_FullName UNIQUE (full_name)
    );
END
GO

/* =============================
   4.2) TABLE: DOCTOR DUTY
   ============================= */
IF OBJECT_ID('dbo.DoctorDuty', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DoctorDuty (
        id INT IDENTITY(1,1) NOT NULL,
        doctor_id INT NOT NULL,
        duty_date DATE NOT NULL,
        shift_start TIME(0) NOT NULL,
        shift_end TIME(0) NOT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_DoctorDuty_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT PK_DoctorDuty PRIMARY KEY (id),
        CONSTRAINT FK_DoctorDuty_Doctor FOREIGN KEY (doctor_id) REFERENCES dbo.Doctor(id),
        CONSTRAINT CK_DoctorDuty_TimeRange CHECK (shift_start < shift_end),
        CONSTRAINT UQ_DoctorDuty_UniqueShift UNIQUE (doctor_id, duty_date, shift_start, shift_end)
    );
END
GO

/* =============================
   5) INDEXES (for faster query)
   ============================= */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Booking_UserId_Date' AND object_id = OBJECT_ID('dbo.Booking'))
BEGIN
    CREATE INDEX IX_Booking_UserId_Date ON dbo.Booking(user_id, booking_date DESC, start_time DESC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Booking_Date_Status' AND object_id = OBJECT_ID('dbo.Booking'))
BEGIN
    CREATE INDEX IX_Booking_Date_Status ON dbo.Booking(booking_date, status, start_time);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DoctorDuty_Date_Start' AND object_id = OBJECT_ID('dbo.DoctorDuty'))
BEGIN
    CREATE INDEX IX_DoctorDuty_Date_Start ON dbo.DoctorDuty(duty_date, shift_start, shift_end);
END
GO

/* =============================
   6) SEED USERS
   ============================= */
IF NOT EXISTS (SELECT 1 FROM dbo.[User] WHERE username = 'admin')
BEGIN
    INSERT INTO dbo.[User] (username, [password], role)
    VALUES ('admin', 'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk=', 'admin');
END
ELSE
BEGIN
    UPDATE dbo.[User]
    SET [password] = 'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk=', role = 'admin'
    WHERE username = 'admin' AND [password] NOT LIKE 'pbkdf2$%';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[User] WHERE username = 'user1')
BEGIN
    INSERT INTO dbo.[User] (username, [password], role)
    VALUES ('user1', 'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk=', 'user');
END
ELSE
BEGIN
    UPDATE dbo.[User]
    SET [password] = 'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk=', role = 'user'
    WHERE username = 'user1' AND [password] NOT LIKE 'pbkdf2$%';
END
GO

/* =============================
   6.1) SEED 1000 DEMO USERS
   ============================= */
;WITH Num AS (
    SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.[User] (username, [password], role)
SELECT
    CONCAT('user_demo_', RIGHT('0000' + CAST(n AS VARCHAR(4)), 4)),
    'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk=',
    'user'
FROM Num
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.[User] u
    WHERE u.username = CONCAT('user_demo_', RIGHT('0000' + CAST(Num.n AS VARCHAR(4)), 4))
);
GO

/* =============================
    6.2) MIGRATE LEGACY DEFAULT PASSWORD USERS
    =============================
    Mục tiêu: chuyển các tài khoản cũ còn dùng mật khẩu mặc định plain text
    sang dạng PBKDF2 để đồng bộ bảo mật.
*/
UPDATE dbo.[User]
SET [password] = 'pbkdf2$65536$xAJSRD9sAZqTWVvaeboJ0g==$tSm3USrERZjMbIk9Le/YGAwUIVDQWGuGlPCDI7fcBdk='
WHERE [password] = '123456';
GO

/* =============================
   7) OPTIONAL SAMPLE BOOKINGS
   ============================= */
IF NOT EXISTS (
    SELECT 1
    FROM dbo.Booking b
    JOIN dbo.[User] u ON u.id = b.user_id
    WHERE u.username = 'user1' AND b.booking_date = CAST(GETDATE() AS DATE)
)
BEGIN
    DECLARE @user1Id INT;
    SELECT @user1Id = id FROM dbo.[User] WHERE username = 'user1';

    INSERT INTO dbo.Booking (user_id, booking_date, start_time, end_time, status)
    VALUES
        (@user1Id, CAST(GETDATE() AS DATE), '09:00', '10:00', 'pending'),
        (@user1Id, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)), '10:30', '11:30', 'approved');
END
GO

/* =============================
   7.0) SEED RANDOM BOOKINGS FOR DEMO USERS
   =============================
   Mục tiêu: tạo dữ liệu lớn, phân bổ trạng thái hợp lý để panel Hoạt động
   thể hiện số liệu tổng thể trong ngày.
*/
IF NOT EXISTS (
    SELECT 1
    FROM dbo.Booking b
    JOIN dbo.[User] u ON u.id = b.user_id
    WHERE u.username LIKE 'user_demo_%'
)
BEGIN
    ;WITH DemoUsers AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM dbo.[User]
        WHERE username LIKE 'user_demo_%'
    ),
    Num AS (
        SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b
    ),
    BookingSource AS (
        SELECT
            n,
            ((n - 1) % 1000) + 1 AS user_rn,
            DATEADD(DAY, (ABS(CHECKSUM(CONCAT('d', n))) % 31) - 15, CAST(GETDATE() AS DATE)) AS booking_date,
            CASE
                WHEN (n % 100) < 40 THEN 'approved'
                WHEN (n % 100) < 70 THEN 'pending'
                WHEN (n % 100) < 85 THEN 'rejected'
                ELSE 'cancelled'
            END AS status,
            ABS(CHECKSUM(CONCAT('s', n))) % 17 AS slot_index,
            CASE (n % 4)
                WHEN 0 THEN 30
                WHEN 1 THEN 60
                WHEN 2 THEN 90
                ELSE 120
            END AS duration_minutes
        FROM Num
    )
    INSERT INTO dbo.Booking (user_id, booking_date, start_time, end_time, status)
    SELECT
        du.id,
        bs.booking_date,
        CAST(DATEADD(MINUTE, bs.slot_index * 30, CAST('08:00' AS DATETIME)) AS TIME(0)) AS start_time,
        CAST(DATEADD(MINUTE, (bs.slot_index * 30) + bs.duration_minutes, CAST('08:00' AS DATETIME)) AS TIME(0)) AS end_time,
        bs.status
    FROM BookingSource bs
    JOIN DemoUsers du ON du.rn = bs.user_rn
    WHERE CAST(DATEADD(MINUTE, (bs.slot_index * 30) + bs.duration_minutes, CAST('08:00' AS DATETIME)) AS TIME(0)) <= '18:00';
END
GO

/* =============================
   7.1) SEED DOCTORS
   ============================= */
DECLARE @DoctorSeed TABLE (
    full_name NVARCHAR(100) PRIMARY KEY,
    specialty NVARCHAR(100)
);

INSERT INTO @DoctorSeed (full_name, specialty)
VALUES
    (N'BS. Nguyễn Minh Anh', N'Nội tổng quát'),
    (N'BS. Trần Bảo Châu', N'Nhi khoa'),
    (N'BS. Lê Hoàng Đức', N'Tim mạch'),
    (N'BS. Phạm Quỳnh Giao', N'Da liễu'),
    (N'BS. Võ Thanh Hùng', N'Tai mũi họng'),
    (N'BS. Đỗ Kim Ngân', N'Răng hàm mặt'),
    (N'BS. Bùi Hà Linh', N'Nội tổng quát'),
    (N'BS. Trương Quốc Việt', N'Thần kinh'),
    (N'BS. Nguyễn Hải Nam', N'Tim mạch'),
    (N'BS. Hoàng Gia Hân', N'Nhi khoa'),
    (N'BS. Dương Anh Thư', N'Da liễu'),
    (N'BS. Phan Thanh Sơn', N'Nội tổng quát'),
    (N'BS. Vũ Khánh Toàn', N'Tai mũi họng'),
    (N'BS. Lý Ngọc Nhi', N'Răng hàm mặt'),
    (N'BS. Hồ Quang Thái', N'Thần kinh'),
    (N'BS. Đặng Thuỳ Trang', N'Nội tổng quát'),
    (N'BS. Ngô Minh Khang', N'Nhi khoa'),
    (N'BS. Cao Phúc Hậu', N'Tim mạch'),
    (N'BS. Tô Gia Linh', N'Da liễu'),
    (N'BS. Mai Hoài Phương', N'Chẩn đoán hình ảnh'),
    (N'BS. Đinh Tuấn Anh', N'Nội tổng quát'),
    (N'BS. Quách Bảo Trân', N'Nhi khoa'),
    (N'BS. Lưu Quốc Bảo', N'Tim mạch'),
    (N'BS. Tạ Đức Duy', N'Thần kinh'),
    (N'BS. Khuất Ngọc Mai', N'Tai mũi họng'),
    (N'BS. Triệu Hồng Nhung', N'Da liễu'),
    (N'BS. Mạc Minh Tuấn', N'Răng hàm mặt'),
    (N'BS. Châu Hải Đăng', N'Nội tổng quát'),
    (N'BS. Chu Nguyên Vũ', N'Nhi khoa'),
    (N'BS. Kiều Thanh Hòa', N'Tim mạch'),
    (N'BS. La Bảo Ngọc', N'Chẩn đoán hình ảnh'),
    (N'BS. Thái Khánh Vy', N'Da liễu'),
    (N'BS. Tăng Minh Phúc', N'Thần kinh'),
    (N'BS. Nghiêm Quỳnh An', N'Tai mũi họng'),
    (N'BS. Văn Đức Thành', N'Nội tổng quát'),
    (N'BS. Âu Hải Yến', N'Nhi khoa'),
    (N'BS. Ông Hữu Trọng', N'Tim mạch'),
    (N'BS. Đoàn Nhật Minh', N'Răng hàm mặt'),
    (N'BS. Nguyễn Cẩm Tiên', N'Da liễu'),
    (N'BS. Trần Hoàng Phúc', N'Chẩn đoán hình ảnh');

INSERT INTO dbo.Doctor (full_name, specialty, is_active)
SELECT s.full_name, s.specialty, 1
FROM @DoctorSeed s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Doctor d WHERE d.full_name = s.full_name
);

UPDATE d
SET d.is_active = 0
FROM dbo.Doctor d;

UPDATE d
SET d.is_active = 1,
    d.specialty = s.specialty
FROM dbo.Doctor d
JOIN @DoctorSeed s ON s.full_name = d.full_name;
GO

/* =============================
   7.2) OPTIONAL SAMPLE DUTY SCHEDULES
   ============================= */
DECLARE @firstWorkDay DATE = CAST(GETDATE() AS DATE);
WHILE DATENAME(WEEKDAY, @firstWorkDay) IN (N'Saturday', N'Sunday', N'Thứ Bảy', N'Chủ Nhật')
BEGIN
    SET @firstWorkDay = DATEADD(DAY, 1, @firstWorkDay);
END

IF NOT EXISTS (SELECT 1 FROM dbo.DoctorDuty WHERE duty_date = @firstWorkDay)
BEGIN
    INSERT INTO dbo.DoctorDuty (doctor_id, duty_date, shift_start, shift_end)
    SELECT d.id, @firstWorkDay,
           CASE d.full_name
                 WHEN N'BS. Nguyễn Minh Anh' THEN '07:30'
                 WHEN N'BS. Trần Bảo Châu' THEN '09:00'
                 WHEN N'BS. Lê Hoàng Đức' THEN '13:00'
                ELSE '17:30'
           END,
           CASE d.full_name
                 WHEN N'BS. Nguyễn Minh Anh' THEN '11:30'
                 WHEN N'BS. Trần Bảo Châu' THEN '12:00'
                 WHEN N'BS. Lê Hoàng Đức' THEN '17:00'
                ELSE '20:00'
           END
    FROM dbo.Doctor d
        WHERE d.full_name IN (N'BS. Nguyễn Minh Anh', N'BS. Trần Bảo Châu', N'BS. Lê Hoàng Đức', N'BS. Phạm Quỳnh Giao');
END
GO

/* =============================
   7.3) AUTO FILL DUTY SCHEDULES FOR DEMO (CURRENT MONTH)
   =============================
    Mục tiêu: demo nhẹ, mỗi ngày làm việc có ngẫu nhiên 3-7 bác sĩ trực.
    Script sẽ tạo lại lịch trực trong tháng hiện tại để đúng số lượng mong muốn.
*/
DECLARE @monthStart DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @monthEnd DATE = EOMONTH(GETDATE());

DELETE FROM dbo.DoctorDuty
WHERE duty_date BETWEEN @monthStart AND @monthEnd;

;WITH DatePool AS (
    SELECT @monthStart AS duty_date
    UNION ALL
    SELECT DATEADD(DAY, 1, duty_date)
    FROM DatePool
    WHERE duty_date < @monthEnd
),
WorkDays AS (
    SELECT duty_date
    FROM DatePool
    WHERE DATENAME(WEEKDAY, duty_date) NOT IN (N'Saturday', N'Sunday', N'Thứ Bảy', N'Chủ Nhật')
),
ShiftTemplate AS (
    SELECT 1 AS shift_no, CAST('07:30' AS TIME(0)) AS shift_start, CAST('11:30' AS TIME(0)) AS shift_end
    UNION ALL SELECT 2, CAST('09:00' AS TIME(0)), CAST('12:00' AS TIME(0))
    UNION ALL SELECT 3, CAST('13:00' AS TIME(0)), CAST('17:00' AS TIME(0))
    UNION ALL SELECT 4, CAST('17:30' AS TIME(0)), CAST('20:00' AS TIME(0))
),
DayTargets AS (
    SELECT
        w.duty_date,
        (ABS(CHECKSUM(CONVERT(VARCHAR(10), w.duty_date, 23))) % 5) + 3 AS doctor_target
    FROM WorkDays w
),
TopDoctors AS (
    SELECT TOP (40) d.id
    FROM dbo.Doctor d
    WHERE d.is_active = 1
    ORDER BY d.id
),
RandomDoctorsByDay AS (
    SELECT
        dt.duty_date,
        dt.doctor_target,
        td.id AS doctor_id,
        ROW_NUMBER() OVER (
            PARTITION BY dt.duty_date
            ORDER BY NEWID()
        ) AS doctor_pick
    FROM DayTargets dt
    CROSS JOIN TopDoctors td
),
DutyRows AS (
    SELECT
        rd.duty_date,
        rd.doctor_id,
        st.shift_start,
        st.shift_end
    FROM RandomDoctorsByDay rd
    JOIN ShiftTemplate st
        ON st.shift_no = ((rd.doctor_pick - 1) % 4) + 1
    WHERE rd.doctor_pick <= rd.doctor_target
)
INSERT INTO dbo.DoctorDuty (doctor_id, duty_date, shift_start, shift_end)
SELECT dr.doctor_id, dr.duty_date, dr.shift_start, dr.shift_end
FROM DutyRows dr
OPTION (MAXRECURSION 1000);
GO

/* =============================
   7.3.1) BACKFILL MISSING WORKDAYS IN CURRENT MONTH
   =============================
   Mục tiêu: nếu ngày làm việc nào trong tháng hiện tại chưa có phân ca,
   tự động bổ sung ngẫu nhiên 3-7 bác sĩ trực/ngày.
*/
DECLARE @fixMonthStart DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @fixMonthEnd DATE = EOMONTH(GETDATE());

;WITH DatePool AS (
    SELECT @fixMonthStart AS duty_date
    UNION ALL
    SELECT DATEADD(DAY, 1, duty_date)
    FROM DatePool
    WHERE duty_date < @fixMonthEnd
),
MissingWorkDays AS (
    SELECT dp.duty_date
    FROM DatePool dp
    WHERE DATENAME(WEEKDAY, dp.duty_date) NOT IN (N'Saturday', N'Sunday', N'Thứ Bảy', N'Chủ Nhật')
      AND NOT EXISTS (
            SELECT 1 FROM dbo.DoctorDuty dd WHERE dd.duty_date = dp.duty_date
      )
),
ShiftTemplate AS (
    SELECT 1 AS shift_no, CAST('07:30' AS TIME(0)) AS shift_start, CAST('11:30' AS TIME(0)) AS shift_end
    UNION ALL SELECT 2, CAST('09:00' AS TIME(0)), CAST('12:00' AS TIME(0))
    UNION ALL SELECT 3, CAST('13:00' AS TIME(0)), CAST('17:00' AS TIME(0))
    UNION ALL SELECT 4, CAST('17:30' AS TIME(0)), CAST('20:00' AS TIME(0))
),
DayTargets AS (
    SELECT
        m.duty_date,
        (ABS(CHECKSUM(CONCAT(CONVERT(VARCHAR(10), m.duty_date, 23), '-backfill'))) % 5) + 3 AS doctor_target
    FROM MissingWorkDays m
),
TopDoctors AS (
    SELECT TOP (40) d.id
    FROM dbo.Doctor d
    WHERE d.is_active = 1
    ORDER BY d.id
),
RandomDoctorsByDay AS (
    SELECT
        dt.duty_date,
        dt.doctor_target,
        td.id AS doctor_id,
        ROW_NUMBER() OVER (
            PARTITION BY dt.duty_date
            ORDER BY NEWID()
        ) AS doctor_pick
    FROM DayTargets dt
    CROSS JOIN TopDoctors td
),
DutyRows AS (
    SELECT
        rd.duty_date,
        rd.doctor_id,
        st.shift_start,
        st.shift_end
    FROM RandomDoctorsByDay rd
    JOIN ShiftTemplate st
        ON st.shift_no = ((rd.doctor_pick - 1) % 4) + 1
    WHERE rd.doctor_pick <= rd.doctor_target
)
INSERT INTO dbo.DoctorDuty (doctor_id, duty_date, shift_start, shift_end)
SELECT dr.doctor_id, dr.duty_date, dr.shift_start, dr.shift_end
FROM DutyRows dr
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.DoctorDuty dd
    WHERE dd.doctor_id = dr.doctor_id
      AND dd.duty_date = dr.duty_date
      AND dd.shift_start = dr.shift_start
      AND dd.shift_end = dr.shift_end
)
OPTION (MAXRECURSION 1000);
GO

/* =============================
   7.4) AUTO FILL DUTY SCHEDULES FOR NEXT WEEK (DEMO)
   =============================
   Mục tiêu: tuần sau (thứ 2 - thứ 6) mỗi ngày ngẫu nhiên 3-7 bác sĩ trực.
*/
DECLARE @today DATE = CAST(GETDATE() AS DATE);
DECLARE @thisMonday DATE = DATEADD(DAY, -(DATEDIFF(DAY, '19000101', @today) % 7), @today);
DECLARE @nextMonday DATE = DATEADD(DAY, 7, @thisMonday);
DECLARE @nextSunday DATE = DATEADD(DAY, 6, @nextMonday);

;WITH DatePool AS (
    SELECT @nextMonday AS duty_date
    UNION ALL
    SELECT DATEADD(DAY, 1, duty_date)
    FROM DatePool
    WHERE duty_date < @nextSunday
),
WorkDays AS (
    SELECT duty_date
    FROM DatePool
    WHERE ((DATEDIFF(DAY, '19000101', duty_date) % 7) + 1) BETWEEN 1 AND 5
),
ShiftTemplate AS (
    SELECT 1 AS shift_no, CAST('07:30' AS TIME(0)) AS shift_start, CAST('11:30' AS TIME(0)) AS shift_end
    UNION ALL SELECT 2, CAST('09:00' AS TIME(0)), CAST('12:00' AS TIME(0))
    UNION ALL SELECT 3, CAST('13:00' AS TIME(0)), CAST('17:00' AS TIME(0))
    UNION ALL SELECT 4, CAST('17:30' AS TIME(0)), CAST('20:00' AS TIME(0))
),
DayTargets AS (
    SELECT
        w.duty_date,
        (ABS(CHECKSUM(CONCAT(CONVERT(VARCHAR(10), w.duty_date, 23), '-next-week'))) % 5) + 3 AS doctor_target
    FROM WorkDays w
),
TopDoctors AS (
    SELECT TOP (40) d.id
    FROM dbo.Doctor d
    WHERE d.is_active = 1
    ORDER BY d.id
),
RandomDoctorsByDay AS (
    SELECT
        dt.duty_date,
        dt.doctor_target,
        td.id AS doctor_id,
        ROW_NUMBER() OVER (
            PARTITION BY dt.duty_date
            ORDER BY NEWID()
        ) AS doctor_pick
    FROM DayTargets dt
    CROSS JOIN TopDoctors td
),
DutyRows AS (
    SELECT
        rd.duty_date,
        rd.doctor_id,
        st.shift_start,
        st.shift_end
    FROM RandomDoctorsByDay rd
    JOIN ShiftTemplate st
        ON st.shift_no = ((rd.doctor_pick - 1) % 4) + 1
    WHERE rd.doctor_pick <= rd.doctor_target
)
INSERT INTO dbo.DoctorDuty (doctor_id, duty_date, shift_start, shift_end)
SELECT dr.doctor_id, dr.duty_date, dr.shift_start, dr.shift_end
FROM DutyRows dr
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.DoctorDuty dd
    WHERE dd.doctor_id = dr.doctor_id
      AND dd.duty_date = dr.duty_date
      AND dd.shift_start = dr.shift_start
      AND dd.shift_end = dr.shift_end
)
OPTION (MAXRECURSION 1000);
GO

/* =============================
   8) QUICK CHECK
   ============================= */
SELECT * FROM dbo.[User];
SELECT * FROM dbo.Booking ORDER BY booking_date DESC, start_time DESC;
SELECT dd.id, d.full_name, dd.duty_date, dd.shift_start, dd.shift_end
FROM dbo.DoctorDuty dd
JOIN dbo.Doctor d ON d.id = dd.doctor_id
ORDER BY dd.duty_date DESC, dd.shift_start ASC;
SELECT COUNT(1) AS total_doctors FROM dbo.Doctor;
SELECT COUNT(1) AS total_active_doctors FROM dbo.Doctor WHERE is_active = 1;
SELECT COUNT(1) AS total_duty_rows FROM dbo.DoctorDuty;
GO

/*
    IMPORTANT VALUES USED IN CODE:

    Roles:
    - admin
    - user

    Booking status:
    - pending
    - approved
    - rejected
    - cancelled

    Main table/column names:
    - dbo.[User](id, username, password, role)
    - dbo.Booking(id, user_id, booking_date, start_time, end_time, status)
    - dbo.Doctor(id, full_name, specialty, is_active)
    - dbo.DoctorDuty(id, doctor_id, duty_date, shift_start, shift_end)
*/
