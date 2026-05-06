# Hệ thống Đặt lịch Khám bệnh

Ứng dụng web quản lý đặt lịch khám bệnh được xây dựng bằng Java EE, JSP/Servlet, và SQL Server.

## 📋 Mục lục

- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt](#-cài-đặt)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [Hướng dẫn sử dụng](#-hướng-dẫn-sử-dụng)
- [API Endpoints](#-api-endpoints)
- [Bảo mật](#-bảo-mật)
- [Tài khoản mặc định](#-tài-khoản-mặc-định)

## ✨ Tính năng

### Dành cho Bệnh nhân (User)
- **Đăng nhập/Đăng xuất**: Xác thực người dùng với mã hóa mật khẩu PBKDF2
- **Đặt lịch khám**: Chọn ngày, giờ khám với giao diện lịch trực quan
- **Quản lý lịch khám**: Xem danh sách lịch đã đặt, hủy lịch (nếu còn thời gian)
- **Thống kê cá nhân**: Xem số lượng lịch theo trạng thái (chờ duyệt, đã duyệt, từ chối, đã hủy)
- **Đổi mật khẩu**: Cập nhật mật khẩu bảo mật
- **Xem lịch trực bác sĩ**: Kiểm tra bác sĩ trực theo ngày


### Dành cho Quản trị viên (Admin)
- **Dashboard tổng quan**: Thống kê hoạt động đặt lịch theo ngày
- **Quản lý lịch khám**: Duyệt/từ chối lịch khám của bệnh nhân
- **Quản lý lịch trực bác sĩ**: Thêm, xóa lịch trực bác sĩ
- **Lọc và sắp xếp**: Tìm kiếm lịch khám theo ngày, trạng thái
- **Phân trang**: Hiển thị danh sách với phân trang

### Tính năng chung
- **Lịch tương tác**: Giao diện lịch đẹp mắt, dễ sử dụng
- **Validation**: Kiểm tra dữ liệu đầu vào phía client và server
- **Responsive**: Giao diện tương thích với nhiều kích thước màn hình
- **CSRF Protection**: Bảo vệ chống tấn công CSRF
- **Security Headers**: Thiết lập các header bảo mật (XSS, Clickjacking)

## 🛠 Công nghệ sử dụng

### Backend
- **Java 17**: Ngôn ngữ lập trình chính
- **Jakarta EE 10**: Servlet API, JSP, JSTL
- **Apache Tomcat 10+**: Web server/servlet container
- **SQL Server**: Hệ quản trị cơ sở dữ liệu


### Frontend
- **HTML5/CSS3**: Giao diện người dùng
- **JavaScript (Vanilla)**: Xử lý tương tác phía client
- **AJAX/Fetch API**: Giao tiếp bất đồng bộ với server

### Thư viện
- **JSTL 2.0**: Jakarta Standard Tag Library
- **Microsoft SQL Server JDBC Driver 13.2**: Kết nối database

### Kiến trúc
- **MVC Pattern**: Model-View-Controller
- **DAO Pattern**: Data Access Object
- **Service Layer**: Business logic layer
- **Filter**: Security headers, authentication

## 📦 Yêu cầu hệ thống

- **JDK**: 17 trở lên
- **Apache Tomcat**: 10.0+ (hỗ trợ Jakarta EE 10)
- **SQL Server**: 2019 trở lên (hoặc SQL Server Express)
- **IDE**: NetBeans 17+ (khuyến nghị) hoặc IntelliJ IDEA, Eclipse
- **RAM**: Tối thiểu 4GB
- **Disk**: 500MB trống


## 🚀 Cài đặt

### 1. Cài đặt SQL Server

1. Tải và cài đặt SQL Server 2019+ hoặc SQL Server Express
2. Cài đặt SQL Server Management Studio (SSMS)
3. Khởi động SQL Server service

### 2. Tạo cơ sở dữ liệu

1. Mở SQL Server Management Studio
2. Kết nối đến SQL Server instance (localhost)
3. Mở file `src/conf/schema.sql`
4. Chạy toàn bộ script để tạo database và seed dữ liệu mẫu

Script sẽ tự động:
- Tạo database `BookingSystem`
- Tạo các bảng: `User`, `Booking`, `Doctor`, `DoctorDuty`
- Tạo indexes để tối ưu hiệu suất
- Seed 1000+ user demo và dữ liệu mẫu
- Tạo lịch trực bác sĩ cho tháng hiện tại

### 3. Cấu hình kết nối database

Mở file `src/java/utils/DBUtils.java` và kiểm tra thông tin kết nối:

```java
private static final String DB_URL = "jdbc:sqlserver://localhost:1433;databaseName=BookingSystem;encrypt=true;trustServerCertificate=true";
private static final String DB_USER = "sa";
private static final String DB_PASSWORD = "123";
```


Hoặc sử dụng system properties khi chạy ứng dụng:
```bash
-Ddb.url=jdbc:sqlserver://localhost:1433;databaseName=BookingSystem;encrypt=true;trustServerCertificate=true
-Ddb.user=sa
-Ddb.password=your_password
```

### 4. Cài đặt và chạy ứng dụng

#### Sử dụng NetBeans:

1. Mở NetBeans IDE
2. Chọn **File → Open Project**
3. Chọn thư mục project
4. Chuột phải vào project → **Properties**
5. Chọn **Run** → Cấu hình Tomcat server
6. Nhấn **F6** hoặc **Run** để chạy ứng dụng

#### Sử dụng Command Line:

```bash
# Build project
ant clean
ant compile
ant dist

# Deploy file WAR vào Tomcat
cp dist/Project.war $CATALINA_HOME/webapps/

# Khởi động Tomcat
$CATALINA_HOME/bin/startup.sh  # Linux/Mac
$CATALINA_HOME/bin/startup.bat # Windows
```

### 5. Truy cập ứng dụng

Mở trình duyệt và truy cập:
```
http://localhost:8080/Project/
```


## 📁 Cấu trúc dự án

```
Project/
├── src/
│   ├── java/
│   │   ├── controller/          # Servlet controllers
│   │   │   ├── LoginController.java
│   │   │   ├── DashboardController.java
│   │   │   ├── UserBookingController.java
│   │   │   ├── AdminController.java
│   │   │   └── ProfileController.java
│   │   ├── dao/                 # Data Access Objects
│   │   │   ├── UserDAO.java
│   │   │   ├── BookingDAO.java
│   │   │   └── DoctorDutyDAO.java
│   │   ├── model/               # Domain models
│   │   │   ├── User.java
│   │   │   ├── Booking.java
│   │   │   └── DoctorDuty.java
│   │   ├── service/             # Business logic
│   │   │   ├── UserService.java
│   │   │   └── BookingService.java
│   │   ├── utils/               # Utilities
│   │   │   ├── DBUtils.java
│   │   │   └── PasswordUtils.java
│   │   ├── validator/           # Input validation
│   │   │   └── BookingValidator.java
│   │   └── filter/              # Servlet filters
│   │       └── SecurityHeadersFilter.java
│   └── conf/
│       ├── MANIFEST.MF
│       └── schema.sql           # Database schema & seed data
├── web/
│   ├── WEB-INF/
│   │   ├── web.xml              # Deployment descriptor
│   │   └── lib/                 # JAR dependencies
│   ├── META-INF/
│   │   └── context.xml
│   ├── login.jsp                # Login page
│   ├── dashboard.jsp            # Main dashboard
│   ├── booking.jsp              # Booking form (embedded)
│   ├── listBooking.jsp          # User bookings list
│   ├── admin.jsp                # Admin panel
│   ├── adminBooking.jsp         # Admin booking management
│   ├── sidebar.jsp              # Sidebar component
│   ├── header.jsp               # Header component
│   ├── footer.jsp               # Footer component
│   └── index.html               # Landing page
├── lib/                         # External libraries
│   ├── jakarta.servlet.jsp.jstl-2.0.0.jar
│   ├── jakarta.servlet.jsp.jstl-api-2.0.0.jar
│   └── mssql-jdbc-13.2.0.jre11.jar
├── build.xml                    # Ant build script
└── README.md                    # This file
```


## 📖 Hướng dẫn sử dụng

### Đăng nhập

1. Truy cập trang chủ: `http://localhost:8080/Project/`
2. Nhập tên đăng nhập và mật khẩu
3. Chọn "Ghi nhớ tên đăng nhập" nếu muốn lưu thông tin
4. Nhấn "Đăng nhập"

### Dành cho Bệnh nhân

#### Đặt lịch khám

1. Đăng nhập với tài khoản user
2. Chọn menu **"Đặt lịch khám"**
3. Chọn ngày khám trên lịch (chỉ được chọn ngày làm việc từ T2-T6)
4. Chọn giờ khám từ danh sách giờ trống
5. Nhập họ tên và số điện thoại
6. Nhấn **"Xác nhận đặt lịch"**

**Lưu ý:**
- Chỉ đặt lịch được đến hết tháng 4
- Thứ 7, Chủ nhật là ngày nghỉ
- Giờ làm việc: 08:00 - 18:00
- Mỗi slot đặt lịch: 30 phút

#### Xem lịch khám của tôi

1. Chọn menu **"Lịch khám của tôi"**
2. Xem danh sách lịch đã đặt với trạng thái
3. Có thể hủy lịch nếu:
   - Trạng thái đang "Chờ duyệt"
   - Chưa quá giờ khám

#### Đổi mật khẩu

1. Click vào avatar góc phải → **"Hồ sơ của tôi"**
2. Nhập mật khẩu hiện tại
3. Nhập mật khẩu mới (tối thiểu 6 ký tự)
4. Xác nhận mật khẩu mới
5. Nhấn **"Cập nhật mật khẩu"**


### Dành cho Quản trị viên

#### Xem thống kê

1. Đăng nhập với tài khoản admin
2. Dashboard hiển thị:
   - Thống kê lịch khám theo ngày
   - Lịch trực bác sĩ trong tháng
   - Click vào ngày để xem chi tiết

#### Quản lý lịch khám

1. Chọn menu **"Quản lý lịch khám"**
2. Lọc theo:
   - Ngày đặt lịch
   - Trạng thái (Tất cả, Chờ duyệt, Đã duyệt, Từ chối, Đã hủy)
3. Sắp xếp theo ngày hoặc trạng thái
4. Duyệt/Từ chối lịch khám bằng nút tương ứng

#### Quản lý lịch trực bác sĩ

1. Xem lịch trực trên dashboard
2. Thêm lịch trực mới:
   - Chọn ngày trực
   - Nhập tên bác sĩ
   - Nhập chuyên khoa (tùy chọn)
   - Chọn giờ bắt đầu và kết thúc ca trực
   - Nhấn **"Thêm lịch trực"**
3. Xóa lịch trực: Click nút xóa tương ứng

## 🔌 API Endpoints

### Authentication
- `POST /LoginController` - Đăng nhập
- `POST /LoginController?action=logout` - Đăng xuất

### User Booking
- `GET /BookingController?action=slots&date={date}&duration={duration}` - Lấy giờ trống
- `POST /BookingController?action=book` - Đặt lịch khám
- `GET /BookingController?action=listUser` - Danh sách lịch của user
- `POST /BookingController?action=cancel&id={bookingId}` - Hủy lịch


### Admin
- `GET /AdminController` - Admin dashboard
- `GET /AdminController?action=list` - Danh sách tất cả lịch khám
- `POST /AdminController?action=approve&id={bookingId}` - Duyệt lịch
- `POST /AdminController?action=reject&id={bookingId}` - Từ chối lịch
- `POST /AdminController?action=addDuty` - Thêm lịch trực bác sĩ
- `POST /AdminController?action=deleteDuty&id={dutyId}` - Xóa lịch trực

### Dashboard
- `GET /DashboardController` - Trang chủ dashboard
- `GET /DashboardController?ajax=stats&statsDate={date}` - Thống kê theo ngày

### Profile
- `POST /ProfileController` - Đổi mật khẩu

## 🔒 Bảo mật

### Mã hóa mật khẩu
- Sử dụng **PBKDF2** với SHA-256
- 65,536 iterations
- Salt ngẫu nhiên cho mỗi mật khẩu
- Format: `pbkdf2$iterations$salt$hash`

### CSRF Protection
- Token CSRF được tạo cho mỗi session
- Kiểm tra token trên mọi POST request quan trọng

### Security Headers
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

### Session Management
- Session timeout: 30 phút
- Session invalidation khi logout
- Kiểm tra authentication trên mọi protected page


### Input Validation
- Server-side validation cho tất cả input
- Client-side validation với HTML5 và JavaScript
- Parameterized queries để chống SQL Injection
- XSS protection với output encoding

## 👤 Tài khoản mặc định

### Admin
```
Username: admin
Password: 123456
```

### User
```
Username: user1
Password: 123456
```

### Demo Users
```
Username: user_demo_0001 đến user_demo_1000
Password: 123456
```

**⚠️ Lưu ý:** Đổi mật khẩu ngay sau khi đăng nhập lần đầu trong môi trường production!

## 🗄️ Database Schema

### Bảng User
```sql
[User] (
    id INT PRIMARY KEY IDENTITY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('user', 'admin'))
)
```

### Bảng Booking
```sql
Booking (
    id INT PRIMARY KEY IDENTITY,
    user_id INT FOREIGN KEY REFERENCES [User](id),
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'))
)
```


### Bảng Doctor
```sql
Doctor (
    id INT PRIMARY KEY IDENTITY,
    full_name NVARCHAR(100) UNIQUE NOT NULL,
    specialty NVARCHAR(100),
    is_active BIT DEFAULT 1
)
```

### Bảng DoctorDuty
```sql
DoctorDuty (
    id INT PRIMARY KEY IDENTITY,
    doctor_id INT FOREIGN KEY REFERENCES Doctor(id),
    duty_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME(),
    UNIQUE (doctor_id, duty_date, shift_start, shift_end)
)
```

## 🎨 Giao diện

- **Design**: Modern, clean, gradient background
- **Color scheme**: Blue theme (#2563eb primary)
- **Typography**: Segoe UI font family
- **Responsive**: Grid layout với breakpoints
- **Animations**: Smooth transitions và hover effects
- **Icons**: Unicode symbols và custom CSS

## 🧪 Testing

### Manual Testing Checklist

**Authentication:**
- ✅ Đăng nhập với tài khoản hợp lệ
- ✅ Đăng nhập với tài khoản không hợp lệ
- ✅ Đăng xuất
- ✅ Session timeout

**Booking (User):**
- ✅ Đặt lịch ngày hợp lệ
- ✅ Đặt lịch ngày cuối tuần (should fail)
- ✅ Đặt lịch quá tháng 4 (should fail)
- ✅ Hủy lịch đang chờ duyệt
- ✅ Không thể hủy lịch đã duyệt


**Admin:**
- ✅ Xem danh sách lịch khám
- ✅ Duyệt lịch khám
- ✅ Từ chối lịch khám
- ✅ Thêm lịch trực bác sĩ
- ✅ Xóa lịch trực bác sĩ
- ✅ Lọc và sắp xếp

**Security:**
- ✅ CSRF token validation
- ✅ SQL Injection prevention
- ✅ XSS protection
- ✅ Session management

## 🐛 Troubleshooting

### Lỗi kết nối database

**Lỗi:** `Cannot connect to database`

**Giải pháp:**
1. Kiểm tra SQL Server đang chạy
2. Kiểm tra thông tin kết nối trong `DBUtils.java`
3. Kiểm tra firewall cho phép kết nối port 1433
4. Kiểm tra SQL Server Authentication mode (Mixed Mode)

### Lỗi JDBC Driver

**Lỗi:** `ClassNotFoundException: com.microsoft.sqlserver.jdbc.SQLServerDriver`

**Giải pháp:**
1. Kiểm tra file `mssql-jdbc-13.2.0.jre11.jar` trong `web/WEB-INF/lib/`
2. Clean và rebuild project
3. Restart Tomcat server

### Lỗi 404 Not Found

**Lỗi:** Không tìm thấy trang

**Giải pháp:**
1. Kiểm tra context path: `/Project/`
2. Kiểm tra Tomcat đã deploy thành công
3. Xem log trong `$CATALINA_HOME/logs/catalina.out`

### Lỗi Session timeout

**Lỗi:** Bị đăng xuất liên tục

**Giải pháp:**
1. Tăng session timeout trong `web.xml`:
```xml
<session-config>
    <session-timeout>60</session-timeout>
</session-config>
```


## 📝 Quy tắc nghiệp vụ

### Đặt lịch khám
- Chỉ đặt lịch được từ hôm nay đến hết ngày 30/4
- Không đặt lịch vào thứ 7, Chủ nhật
- Giờ làm việc: 08:00 - 18:00
- Mỗi slot: 30 phút (08:00, 08:30, 09:00, ...)
- Thời lượng khám: 30, 60, 90, hoặc 120 phút
- Không đặt lịch quá giờ hiện tại trong ngày

### Trạng thái lịch khám
- **pending**: Chờ admin duyệt
- **approved**: Admin đã duyệt
- **rejected**: Admin từ chối
- **cancelled**: User đã hủy

### Hủy lịch
- Chỉ hủy được lịch có trạng thái "pending"
- Không hủy được lịch đã qua giờ khám
- Không hủy được lịch đã duyệt/từ chối

### Lịch trực bác sĩ
- Chỉ tạo lịch trực từ thứ 2 đến thứ 6
- Giờ kết thúc phải sau giờ bắt đầu
- Không trùng lặp (cùng bác sĩ, ngày, giờ)

## 🔄 Workflow

### User Booking Flow
```
1. User đăng nhập
2. Chọn "Đặt lịch khám"
3. Chọn ngày trên lịch
4. Hệ thống load giờ trống
5. User chọn giờ và nhập thông tin
6. Submit → Status: pending
7. Admin duyệt → Status: approved/rejected
8. User có thể hủy nếu còn pending
```

### Admin Approval Flow
```
1. Admin đăng nhập
2. Vào "Quản lý lịch khám"
3. Xem danh sách lịch chờ duyệt
4. Click "Duyệt" hoặc "Từ chối"
5. Status cập nhật trong database
6. User thấy trạng thái mới trong "Lịch khám của tôi"
```


## 🚀 Performance Optimization

### Database Indexes
```sql
-- Tối ưu query booking theo user và ngày
CREATE INDEX IX_Booking_UserId_Date ON Booking(user_id, booking_date DESC, start_time DESC);

-- Tối ưu query booking theo ngày và trạng thái
CREATE INDEX IX_Booking_Date_Status ON Booking(booking_date, status, start_time);

-- Tối ưu query lịch trực theo ngày
CREATE INDEX IX_DoctorDuty_Date_Start ON DoctorDuty(duty_date, shift_start, shift_end);
```

### Connection Pooling
Sử dụng Tomcat JDBC Connection Pool trong `META-INF/context.xml`:
```xml
<Resource name="jdbc/BookingDB"
          auth="Container"
          type="javax.sql.DataSource"
          maxTotal="20"
          maxIdle="10"
          maxWaitMillis="10000"
          username="sa"
          password="123"
          driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver"
          url="jdbc:sqlserver://localhost:1433;databaseName=BookingSystem"/>
```

### Caching Strategy
- Session-based caching cho user info
- Client-side caching với localStorage (remember username)
- Browser caching cho static resources

## 📊 Statistics & Reporting

Hệ thống cung cấp các thống kê:

**User Dashboard:**
- Tổng số lịch đã đặt
- Số lịch theo trạng thái (pending, approved, rejected, cancelled)
- Thống kê theo ngày

**Admin Dashboard:**
- Tổng số lịch trong hệ thống
- Số lịch chờ duyệt
- Hoạt động theo ngày
- Lịch trực bác sĩ

## 🔮 Future Enhancements

- [ ] Email notification khi lịch được duyệt/từ chối
- [ ] SMS reminder trước giờ khám
- [ ] Export báo cáo Excel/PDF
- [ ] Đánh giá bác sĩ sau khám
- [ ] Tích hợp thanh toán online
- [ ] Mobile app (Android/iOS)
- [ ] Real-time notification với WebSocket
- [ ] Multi-language support
- [ ] Advanced search và filter
- [ ] Appointment rescheduling


## 🤝 Contributing

Nếu bạn muốn đóng góp cho project:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

### Coding Standards
- Sử dụng Java naming conventions
- Comment code khi cần thiết
- Viết code dễ đọc, dễ maintain
- Test kỹ trước khi commit

## 📄 License

Project này được phát triển cho mục đích học tập và nghiên cứu.

## 👨‍💻 Author

**Lê Văn Thắng**
- GitHub: [@letha](https://github.com/letha)

## 📞 Support

Nếu gặp vấn đề hoặc có câu hỏi:
- Tạo issue trên GitHub
- Email: letha@example.com

## 🙏 Acknowledgments

- Jakarta EE Documentation
- Apache Tomcat Documentation
- Microsoft SQL Server Documentation
- Stack Overflow Community

---

**⭐ Nếu project hữu ích, hãy cho một star trên GitHub!**

**📅 Last Updated:** May 2026
**🔖 Version:** 1.0.0