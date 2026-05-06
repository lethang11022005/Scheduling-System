<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="model.Booking"%>
<%@page import="model.DoctorDuty"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
        return;
    }
    String role = String.valueOf(session.getAttribute("role"));
    if (!"admin".equalsIgnoreCase(role)) {
        response.sendRedirect("BookingController?action=showForm&error=Bạn không có quyền truy cập");
        return;
    }

    List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
    List<DoctorDuty> duties = (List<DoctorDuty>) request.getAttribute("duties");
    List<String> doctorNames = (List<String>) request.getAttribute("doctorNames");
    Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("stats");

    String error = request.getParameter("error") != null ? request.getParameter("error") : (String) request.getAttribute("error");
    String success = request.getParameter("success") != null ? request.getParameter("success") : (String) request.getAttribute("success");

    String date = request.getAttribute("date") == null ? "" : String.valueOf(request.getAttribute("date"));
    String status = request.getAttribute("status") == null ? "" : String.valueOf(request.getAttribute("status"));
    String sort = request.getAttribute("sort") == null ? "date" : String.valueOf(request.getAttribute("sort"));
    String dutyDate = request.getAttribute("dutyDate") == null ? java.time.LocalDate.now().toString() : String.valueOf(request.getAttribute("dutyDate"));

    int currentPage = request.getAttribute("currentPage") == null ? 1 : (Integer) request.getAttribute("currentPage");
    int totalPages = request.getAttribute("totalPages") == null ? 1 : (Integer) request.getAttribute("totalPages");

    DateTimeFormatter viDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý lịch khám</title>
    <style>
        :root {
            --bg-1: #eef6ff;
            --bg-2: #f6fbff;
            --panel: #ffffff;
            --line: #dbe4f0;
            --text: #0f172a;
            --muted: #64748b;
            --primary: #2563eb;
            --ok: #16a34a;
            --danger: #dc2626;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: 'Segoe UI', sans-serif;
            color: var(--text);
            background: radial-gradient(circle at right top, #dbeafe 0%, transparent 42%),
                        linear-gradient(145deg, var(--bg-1), var(--bg-2));
            padding: 22px;
        }

        .container {
            max-width: 1220px;
            margin: 0 auto;
            background: var(--panel);
            border: 1px solid #eef2f7;
            border-radius: 20px;
            box-shadow: 0 20px 48px rgba(15, 23, 42, 0.08);
            padding: 24px;
        }

        .topbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 12px;
        }

        .topbar h2 {
            margin: 0;
            font-size: 28px;
            color: #0b3c8a;
            letter-spacing: .2px;
        }

        .admin-meta {
            margin: 0;
            color: var(--muted);
            font-size: 14px;
        }

        .admin-meta b { color: #0b3c8a; }

        a { color: var(--primary); text-decoration: none; }
        a:hover { text-decoration: underline; }

        .alert {
            margin: 10px 0;
            padding: 10px 12px;
            border-radius: 10px;
            border: 1px solid transparent;
            font-size: 14px;
        }

        .error {
            color: #991b1b;
            background: #fff1f2;
            border-color: #fecdd3;
        }

        .success {
            color: #166534;
            background: #ecfdf5;
            border-color: #bbf7d0;
        }

        .stats {
            margin: 16px 0;
            display: grid;
            grid-template-columns: repeat(5, minmax(120px, 1fr));
            gap: 12px;
        }

        .stat-card {
            background: linear-gradient(160deg, #ffffff, #f8fbff);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 12px;
        }

        .stat-label {
            font-size: 12px;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: .3px;
        }

        .stat-value {
            margin-top: 4px;
            font-size: 24px;
            font-weight: 800;
            color: #0b3c8a;
        }

        .panel {
            margin-top: 14px;
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 14px;
            background: #fcfdff;
        }

        .panel h3 {
            margin: 0 0 12px;
            font-size: 18px;
            color: #0b3c8a;
        }

        .filter {
            display: grid;
            grid-template-columns: 1.2fr 1.3fr 1.3fr auto auto;
            gap: 10px;
            align-items: end;
        }

        input, select, button {
            width: 100%;
            padding: 9px 10px;
            border-radius: 10px;
            border: 1px solid #cfd8e3;
            font-size: 14px;
            background: #fff;
        }

        button { cursor: pointer; }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 10px;
            font-weight: 600;
            padding: 9px 12px;
            border: 1px solid transparent;
            cursor: pointer;
        }

        .btn-primary {
            background: linear-gradient(120deg, #2563eb, #3b82f6);
            color: #fff;
        }

        .btn-ghost {
            background: #fff;
            color: #334155;
            border-color: #cfd8e3;
            text-decoration: none;
        }

        .btn-ghost:hover { text-decoration: none; background: #f8fafc; }

        .table-wrap {
            overflow: auto;
            border: 1px solid #e5eaf1;
            border-radius: 12px;
            background: #fff;
            margin-top: 12px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 900px;
        }

        th, td {
            padding: 10px;
            border-bottom: 1px solid #edf2f8;
            text-align: left;
            font-size: 14px;
            vertical-align: middle;
        }

        th {
            background: #f5f9ff;
            color: #1e3a8a;
            font-weight: 700;
            position: sticky;
            top: 0;
            z-index: 1;
        }

        tr:hover td { background: #fafcff; }

        .approve, .reject, .danger {
            border: none;
            color: #fff;
            font-weight: 600;
            padding: 7px 10px;
            border-radius: 8px;
            width: auto;
        }

        .approve { background: var(--ok); }
        .reject, .danger { background: var(--danger); }

        .pagination {
            margin-top: 14px;
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .pagination a {
            display: inline-flex;
            min-width: 34px;
            height: 34px;
            align-items: center;
            justify-content: center;
            border: 1px solid #dbe4f0;
            border-radius: 8px;
            background: #fff;
            color: #334155;
            text-decoration: none;
            font-weight: 600;
        }

        .pagination a.current {
            background: #2563eb;
            color: #fff;
            border-color: #2563eb;
        }

        .status {
            text-transform: uppercase;
            font-size: 12px;
            font-weight: 700;
            display: inline-block;
            padding: 4px 10px;
            border-radius: 999px;
            border: 1px solid transparent;
        }

        .status.pending { color: #a16207; background: #fffbeb; border-color: #fde68a; }
        .status.approved { color: #166534; background: #ecfdf5; border-color: #bbf7d0; }
        .status.rejected { color: #991b1b; background: #fef2f2; border-color: #fecaca; }
        .status.cancelled { color: #334155; background: #f1f5f9; border-color: #cbd5e1; }

        .duty-panel {
            margin: 16px 0 0;
            border: 1px solid #dbeafe;
            border-radius: 12px;
            padding: 14px;
            background: #f8fbff;
        }

        .duty-title { margin: 0 0 10px; color: #1e3a8a; }
        .duty-form { display: grid; grid-template-columns: 1.1fr 1fr 1fr 1fr auto; gap: 10px; align-items: end; }
        .duty-table th, .duty-table td { font-size: 13px; }

        @media (max-width: 980px) {
            body { padding: 12px; }
            .container { padding: 14px; border-radius: 14px; }
            .topbar { flex-direction: column; align-items: flex-start; }
            .stats { grid-template-columns: repeat(2, minmax(120px, 1fr)); }
            .filter { grid-template-columns: 1fr; }
            .duty-form { grid-template-columns: 1fr; }
        }
    </style>
</head>

<body>
<div style="display:grid;grid-template-columns:220px 1fr;min-height:100vh;">
    <jsp:include page="sidebar.jsp"/>
    <div class="container">


    <div class="topbar">
        <h2>Quản trị hệ thống</h2>
        <p class="admin-meta">
            Đăng nhập với tài khoản <b><%= session.getAttribute("username") %></b> |
            <a href="LoginController?action=logout">Đăng xuất</a>
        </p>
    </div>

    <div style="margin-bottom:18px;">
        <div style="display:flex;gap:8px;">
            <a href="#" id="tab-booking" class="btn btn-ghost" style="border-bottom:3px solid #2563eb;">Quản lý đặt lịch</a>
            <a href="#" id="tab-doctor" class="btn btn-ghost">Quản lý bác sĩ trực</a>
        </div>
    </div>

    <% if (error != null && !error.isBlank()) { %>
    <p class="alert error"><%= error %></p>
    <% } %>
    <% if (success != null && !success.isBlank()) { %>
    <p class="alert success"><%= success %></p>
    <% } %>


    <div id="booking-section">
        <% if (stats != null) { %>
        <div class="stats">
            <div class="stat-card"><div class="stat-label"><%= date.isBlank() ? "Hôm nay" : "Ngày đã lọc" %></div><div class="stat-value"><%= stats.getOrDefault("today", 0) %></div></div>
            <div class="stat-card"><div class="stat-label">Chờ duyệt</div><div class="stat-value"><%= stats.getOrDefault("pending", 0) %></div></div>
            <div class="stat-card"><div class="stat-label">Đã duyệt</div><div class="stat-value"><%= stats.getOrDefault("approved", 0) %></div></div>
            <div class="stat-card"><div class="stat-label">Từ chối</div><div class="stat-value"><%= stats.getOrDefault("rejected", 0) %></div></div>
            <div class="stat-card"><div class="stat-label">Đã hủy</div><div class="stat-value"><%= stats.getOrDefault("cancelled", 0) %></div></div>
        </div>
        <% } %>

        <section class="panel">
            <h3>Lọc danh sách lịch khám</h3>
            <form action="AdminController" method="get" class="filter">
                <input type="hidden" name="action" value="listAll">
                <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                <input type="date" name="date" value="<%= date %>">
                <select name="status">
                    <option value="" <%= "".equals(status) ? "selected" : "" %>>Tất cả trạng thái</option>
                    <option value="pending" <%= "pending".equals(status) ? "selected" : "" %>>Chờ duyệt</option>
                    <option value="approved" <%= "approved".equals(status) ? "selected" : "" %>>Đã duyệt</option>
                    <option value="rejected" <%= "rejected".equals(status) ? "selected" : "" %>>Từ chối</option>
                    <option value="cancelled" <%= "cancelled".equals(status) ? "selected" : "" %>>Đã hủy</option>
                </select>
                <select name="sort">
                    <option value="date" <%= "date".equals(sort) ? "selected" : "" %>>Sắp xếp theo ngày</option>
                    <option value="status" <%= "status".equals(sort) ? "selected" : "" %>>Sắp xếp theo trạng thái</option>
                </select>
                <button class="btn btn-primary" type="submit">Lọc dữ liệu</button>
                <a class="btn btn-ghost" href="AdminController?action=listAll">Đặt lại</a>
            </form>
        </section>

        <section class="panel">
            <h3>Danh sách lịch khám</h3>
            <div class="table-wrap">
                <table>
                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>Bệnh nhân</th>
                        <th>Ngày khám</th>
                        <th>Bắt đầu - Kết thúc</th>
                        <th>Trạng thái</th>
                        <th>Thao tác</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        if (bookings == null || bookings.isEmpty()) {
                    %>
                    <tr><td colspan="6">Không có lịch khám nào.</td></tr>
                    <%
                        } else {
                            for (Booking booking : bookings) {
                    %>
                    <tr>
                        <td><%= booking.getId() %></td>
                        <td><%= booking.getUsername() %></td>
                        <td><%= booking.getBookingDate() == null ? "-" : viDateFormatter.format(booking.getBookingDate()) %></td>
                        <td><%= booking.getStartTime() %> - <%= booking.getEndTime() %></td>
                        <%
                            String statusCode = booking.getStatus() == null ? "pending" : booking.getStatus().toLowerCase();
                            String statusLabel = "pending".equals(statusCode) ? "CHỜ DUYỆT"
                                    : ("approved".equals(statusCode) ? "ĐÃ DUYỆT"
                                    : ("rejected".equals(statusCode) ? "TỪ CHỐI" : "ĐÃ HỦY"));
                        %>
                        <td><span class="status <%= statusCode %>"><%= statusLabel %></span></td>
                        <td>
                            <% if ("pending".equalsIgnoreCase(booking.getStatus())) { %>
                            <form action="AdminController" method="post" style="display:inline;">
                                <input type="hidden" name="action" value="approve">
                                <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                                <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                <input type="hidden" name="date" value="<%= date %>">
                                <input type="hidden" name="status" value="<%= status %>">
                                <input type="hidden" name="sort" value="<%= sort %>">
                                <input type="hidden" name="page" value="<%= currentPage %>">
                                <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                                <button class="approve" type="submit">Duyệt</button>
                            </form>
                            <form action="AdminController" method="post" style="display:inline;">
                                <input type="hidden" name="action" value="reject">
                                <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                                <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                <input type="hidden" name="date" value="<%= date %>">
                                <input type="hidden" name="status" value="<%= status %>">
                                <input type="hidden" name="sort" value="<%= sort %>">
                                <input type="hidden" name="page" value="<%= currentPage %>">
                                <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                                <button class="reject" type="submit">Từ chối</button>
                            </form>
                            <% } else { %>
                            -
                            <% } %>
                        </td>
                    </tr>
                    <%      }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </section>

        <div class="pagination">
            <% for (int i = 1; i <= totalPages; i++) { %>
            <a class="<%= i == currentPage ? "current" : "" %>" href="AdminController?action=listAll&date=<%= date %>&status=<%= status %>&sort=<%= sort %>&dutyDate=<%= dutyDate %>&page=<%= i %>"><%= i %></a>
            <% } %>
        </div>
    </div>

    <div id="doctor-section" style="display:none;">
        <div class="duty-panel">
            <h3 class="duty-title">Quản lý bác sĩ trực</h3>
            <form action="AdminController" method="post" class="duty-form">
                <input type="hidden" name="action" value="addDuty">
                <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                <input type="hidden" name="date" value="<%= date %>">
                <input type="hidden" name="status" value="<%= status %>">
                <input type="hidden" name="sort" value="<%= sort %>">
                <input type="hidden" name="page" value="<%= currentPage %>">

                <div>
                    <label>Ngày trực</label>
                    <input type="date" name="dutyDate" value="<%= dutyDate %>" required>
                </div>
                <div>
                    <label>Tên bác sĩ</label>
                    <input type="text" name="doctorName" list="doctorNameList" placeholder="VD: BS. Nguyen Van A" required>
                    <datalist id="doctorNameList">
                        <% if (doctorNames != null) {
                            for (String doctorName : doctorNames) { %>
                        <option value="<%= doctorName %>"></option>
                        <%  }
                           } %>
                    </datalist>
                </div>
                <div>
                    <label>Chuyên khoa (tùy chọn)</label>
                    <input type="text" name="specialty" placeholder="Nội tổng quát">
                </div>
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">
                    <div>
                        <label>Bắt đầu</label>
                        <input type="time" name="shiftStart" required>
                    </div>
                    <div>
                        <label>Kết thúc</label>
                        <input type="time" name="shiftEnd" required>
                    </div>
                </div>
                <button class="btn btn-primary" type="submit">Thêm ca trực</button>
            </form>

            <div class="table-wrap">
                <table class="duty-table">
                    <thead>
                    <tr>
                        <th>Bác sĩ</th>
                        <th>Ngày trực</th>
                        <th>Giờ trực</th>
                        <th>Thao tác</th>
                    </tr>
                    </thead>
                    <tbody>
                    <%
                        if (duties == null || duties.isEmpty()) {
                    %>
                    <tr><td colspan="4">Chưa có lịch trực trong ngày đã chọn.</td></tr>
                    <% } else {
                        for (DoctorDuty duty : duties) {
                    %>
                    <tr>
                        <td><%= duty.getDoctorName() %></td>
                        <td><%= duty.getDutyDate() %></td>
                        <td><%= duty.getShiftStart() %> - <%= duty.getShiftEnd() %></td>
                        <td>
                            <form action="AdminController" method="post" style="display:inline;">
                                <input type="hidden" name="action" value="deleteDuty">
                                <input type="hidden" name="dutyId" value="<%= duty.getId() %>">
                                <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                                <input type="hidden" name="date" value="<%= date %>">
                                <input type="hidden" name="status" value="<%= status %>">
                                <input type="hidden" name="sort" value="<%= sort %>">
                                <input type="hidden" name="page" value="<%= currentPage %>">
                                <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                                <button class="danger" type="submit" onclick="return confirm('Bạn chắc chắn muốn xóa ca trực này?');">Xóa</button>
                            </form>
                        </td>
                    </tr>
                    <%      }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        // Tab switching logic
        const tabBooking = document.getElementById('tab-booking');
        const tabDoctor = document.getElementById('tab-doctor');
        const bookingSection = document.getElementById('booking-section');
        const doctorSection = document.getElementById('doctor-section');

        tabBooking.addEventListener('click', function(e) {
            e.preventDefault();
            tabBooking.style.borderBottom = '3px solid #2563eb';
            tabDoctor.style.borderBottom = 'none';
            bookingSection.style.display = '';
            doctorSection.style.display = 'none';
        });
        tabDoctor.addEventListener('click', function(e) {
            e.preventDefault();
            tabDoctor.style.borderBottom = '3px solid #2563eb';
            tabBooking.style.borderBottom = 'none';
            bookingSection.style.display = 'none';
            doctorSection.style.display = '';
        });
    </script>

    <section class="panel">
        <h3>Lọc danh sách lịch khám</h3>
        <form action="AdminController" method="get" class="filter">
            <input type="hidden" name="action" value="listAll">
            <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
            <input type="date" name="date" value="<%= date %>">
            <select name="status">
                <option value="" <%= "".equals(status) ? "selected" : "" %>>Tất cả trạng thái</option>
                <option value="pending" <%= "pending".equals(status) ? "selected" : "" %>>Chờ duyệt</option>
                <option value="approved" <%= "approved".equals(status) ? "selected" : "" %>>Đã duyệt</option>
                <option value="rejected" <%= "rejected".equals(status) ? "selected" : "" %>>Từ chối</option>
                <option value="cancelled" <%= "cancelled".equals(status) ? "selected" : "" %>>Đã hủy</option>
            </select>
            <select name="sort">
                <option value="date" <%= "date".equals(sort) ? "selected" : "" %>>Sắp xếp theo ngày</option>
                <option value="status" <%= "status".equals(sort) ? "selected" : "" %>>Sắp xếp theo trạng thái</option>
            </select>
            <button class="btn btn-primary" type="submit">Lọc dữ liệu</button>
            <a class="btn btn-ghost" href="AdminController?action=listAll">Đặt lại</a>
        </form>
    </section>

    <div class="duty-panel">
        <h3 class="duty-title">Quản lý lịch bác sĩ trực</h3>
        <form action="AdminController" method="post" class="duty-form">
            <input type="hidden" name="action" value="addDuty">
            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
            <input type="hidden" name="date" value="<%= date %>">
            <input type="hidden" name="status" value="<%= status %>">
            <input type="hidden" name="sort" value="<%= sort %>">
            <input type="hidden" name="page" value="<%= currentPage %>">

            <div>
                <label>Ngày trực</label>
                <input type="date" name="dutyDate" value="<%= dutyDate %>" required>
            </div>
            <div>
                <label>Tên bác sĩ</label>
                <input type="text" name="doctorName" list="doctorNameList" placeholder="VD: BS. Nguyen Van A" required>
                <datalist id="doctorNameList">
                    <% if (doctorNames != null) {
                        for (String doctorName : doctorNames) { %>
                    <option value="<%= doctorName %>"></option>
                    <%  }
                       } %>
                </datalist>
            </div>
            <div>
                <label>Chuyên khoa (tùy chọn)</label>
                <input type="text" name="specialty" placeholder="Nội tổng quát">
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">
                <div>
                    <label>Bắt đầu</label>
                    <input type="time" name="shiftStart" required>
                </div>
                <div>
                    <label>Kết thúc</label>
                    <input type="time" name="shiftEnd" required>
                </div>
            </div>
            <button class="btn btn-primary" type="submit">Thêm ca trực</button>
        </form>

        <div class="table-wrap">
            <table class="duty-table">
                <thead>
                <tr>
                    <th>Bác sĩ</th>
                    <th>Ngày trực</th>
                    <th>Giờ trực</th>
                    <th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <%
                    if (duties == null || duties.isEmpty()) {
                %>
                <tr><td colspan="4">Chưa có lịch trực trong ngày đã chọn.</td></tr>
                <% } else {
                    for (DoctorDuty duty : duties) {
                %>
                <tr>
                    <td><%= duty.getDoctorName() %></td>
                    <td><%= duty.getDutyDate() %></td>
                    <td><%= duty.getShiftStart() %> - <%= duty.getShiftEnd() %></td>
                    <td>
                        <form action="AdminController" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="deleteDuty">
                            <input type="hidden" name="dutyId" value="<%= duty.getId() %>">
                            <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                            <input type="hidden" name="date" value="<%= date %>">
                            <input type="hidden" name="status" value="<%= status %>">
                            <input type="hidden" name="sort" value="<%= sort %>">
                            <input type="hidden" name="page" value="<%= currentPage %>">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                            <button class="danger" type="submit" onclick="return confirm('Bạn chắc chắn muốn xóa ca trực này?');">Xóa</button>
                        </form>
                    </td>
                </tr>
                <%      }
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <section class="panel">
        <h3>Danh sách lịch khám</h3>
        <div class="table-wrap">
            <table>
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Bệnh nhân</th>
                    <th>Ngày khám</th>
                    <th>Bắt đầu - Kết thúc</th>
                    <th>Trạng thái</th>
                    <th>Thao tác</th>
                </tr>
                </thead>
                <tbody>
                <%
                    if (bookings == null || bookings.isEmpty()) {
                %>
                <tr><td colspan="6">Không có lịch khám nào.</td></tr>
                <%
                    } else {
                        for (Booking booking : bookings) {
                %>
                <tr>
                    <td><%= booking.getId() %></td>
                    <td><%= booking.getUsername() %></td>
                    <td><%= booking.getBookingDate() == null ? "-" : viDateFormatter.format(booking.getBookingDate()) %></td>
                    <td><%= booking.getStartTime() %> - <%= booking.getEndTime() %></td>
                    <%
                        String statusCode = booking.getStatus() == null ? "pending" : booking.getStatus().toLowerCase();
                        String statusLabel = "pending".equals(statusCode) ? "CHỜ DUYỆT"
                                : ("approved".equals(statusCode) ? "ĐÃ DUYỆT"
                                : ("rejected".equals(statusCode) ? "TỪ CHỐI" : "ĐÃ HỦY"));
                    %>
                    <td><span class="status <%= statusCode %>"><%= statusLabel %></span></td>
                    <td>
                        <% if ("pending".equalsIgnoreCase(booking.getStatus())) { %>
                        <form action="AdminController" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="approve">
                            <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                            <input type="hidden" name="date" value="<%= date %>">
                            <input type="hidden" name="status" value="<%= status %>">
                            <input type="hidden" name="sort" value="<%= sort %>">
                            <input type="hidden" name="page" value="<%= currentPage %>">
                            <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                            <button class="approve" type="submit">Duyệt</button>
                        </form>
                        <form action="AdminController" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="reject">
                            <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                            <input type="hidden" name="date" value="<%= date %>">
                            <input type="hidden" name="status" value="<%= status %>">
                            <input type="hidden" name="sort" value="<%= sort %>">
                            <input type="hidden" name="page" value="<%= currentPage %>">
                            <input type="hidden" name="dutyDate" value="<%= dutyDate %>">
                            <button class="reject" type="submit">Từ chối</button>
                        </form>
                        <% } else { %>
                        -
                        <% } %>
                    </td>
                </tr>
                <%      }
                    }
                %>
                </tbody>
            </table>
        </div>
    </section>

    <div class="pagination">
        <% for (int i = 1; i <= totalPages; i++) { %>
        <a class="<%= i == currentPage ? "current" : "" %>" href="AdminController?action=listAll&date=<%= date %>&status=<%= status %>&sort=<%= sort %>&dutyDate=<%= dutyDate %>&page=<%= i %>"><%= i %></a>
        <% } %>
    </div>
</div>
</div>
</body>
</html>
