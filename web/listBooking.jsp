<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="model.Booking"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
        return;
    }
    String role = String.valueOf(session.getAttribute("role"));
    if ("admin".equalsIgnoreCase(role)) {
        response.sendRedirect("AdminController?action=listAll");
        return;
    }

    List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
    Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("stats");
    String error = request.getParameter("error") != null ? request.getParameter("error") : (String) request.getAttribute("error");
    String success = request.getParameter("success") != null ? request.getParameter("success") : (String) request.getAttribute("success");
    int currentPage = request.getAttribute("currentPage") == null ? 1 : (Integer) request.getAttribute("currentPage");
    int totalPages = request.getAttribute("totalPages") == null ? 1 : (Integer) request.getAttribute("totalPages");
    DateTimeFormatter viDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    if (bookings == null && request.getAttribute("error") == null) {
        response.sendRedirect("BookingController?action=listUser");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lịch khám của tôi</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f8fafc; margin: 0; }
        .container { max-width: 1000px; margin: 24px auto; background: #fff; border-radius: 12px; padding: 24px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; border-bottom: 1px solid #e5e7eb; text-align: left; }
        th { background: #eff6ff; }
        .actions a { margin-right: 8px; color: #2563eb; text-decoration: none; }
        .error { color: #b91c1c; }
        .success { color: #15803d; }
        .status { text-transform: uppercase; font-size: 12px; font-weight: 700; display: inline-block; padding: 4px 10px; border-radius: 999px; border: 1px solid transparent; }
        .status.pending { color: #a16207; background: #fffbeb; border-color: #fde68a; }
        .status.approved { color: #166534; background: #ecfdf5; border-color: #bbf7d0; }
        .status.rejected { color: #991b1b; background: #fef2f2; border-color: #fecaca; }
        .status.cancelled { color: #334155; background: #f1f5f9; border-color: #cbd5e1; }
        .stats { margin: 10px 0 16px; display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
        .stat-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px; }
        .stat-label { font-size: 12px; color: #64748b; }
        .stat-value { font-size: 20px; font-weight: 700; color: #1e293b; }
    </style>
</head>
<body>
<div class="container">
    <% if (error != null && !error.isBlank()) { %>
    <p class="error"><%= error %></p>
    <% } %>
    <% if (success != null && !success.isBlank()) { %>
    <p class="success"><%= success %></p>
    <% } %>

    <% if (stats != null) { %>
    <div class="stats">
        <div class="stat-card"><div class="stat-label">Chờ duyệt</div><div class="stat-value"><%= stats.get("pending") %></div></div>
        <div class="stat-card"><div class="stat-label">Đã duyệt</div><div class="stat-value"><%= stats.get("approved") %></div></div>
        <div class="stat-card"><div class="stat-label">Từ chối</div><div class="stat-value"><%= stats.get("rejected") %></div></div>
        <div class="stat-card"><div class="stat-label">Đã hủy</div><div class="stat-value"><%= stats.get("cancelled") %></div></div>
    </div>
    <% } %>

    <table>
        <thead>
        <tr>
            <th>Ngày khám</th>
            <th>Bắt đầu</th>
            <th>Kết thúc</th>
            <th>Trạng thái</th>
            <th>Thao tác</th>
        </tr>
        </thead>
        <tbody>
        <%
            if (bookings == null || bookings.isEmpty()) {
        %>
        <tr><td colspan="5">Chưa có lịch khám nào.</td></tr>
        <%
            } else {
                for (Booking booking : bookings) {
        %>
        <tr>
            <%
                String statusCode = booking.getStatus() == null ? "pending" : booking.getStatus().toLowerCase();
                String statusLabel = "pending".equals(statusCode) ? "CHỜ DUYỆT"
                        : ("approved".equals(statusCode) ? "ĐÃ DUYỆT"
                        : ("rejected".equals(statusCode) ? "TỪ CHỐI" : "ĐÃ HỦY"));
            %>
            <td><%= booking.getBookingDate() == null ? "-" : viDateFormatter.format(booking.getBookingDate()) %></td>
            <td><%= booking.getStartTime() %></td>
            <td><%= booking.getEndTime() %></td>
            <td><span class="status <%= statusCode %>"><%= statusLabel %></span></td>
            <td>
                <% if (!"cancelled".equalsIgnoreCase(booking.getStatus()) && !"rejected".equalsIgnoreCase(booking.getStatus()) && !"approved".equalsIgnoreCase(booking.getStatus())) { %>
                <form action="BookingController" method="post" style="display:inline;">
                    <input type="hidden" name="action" value="cancel">
                    <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                    <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                    <button type="submit" style="background:#dc2626;color:#fff;border:none;padding:6px 10px;border-radius:6px;cursor:pointer;" onclick="return confirm('Bạn có chắc muốn hủy lịch khám này?');">Hủy lịch</button>
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

    <div style="margin-top: 14px;">
        <% for (int i = 1; i <= totalPages; i++) { %>
        <a href="BookingController?action=listUser&page=<%= i %>" style="margin-right:8px;"><%= i == currentPage ? "[" + i + "]" : i %></a>
        <% } %>
    </div>
</div>
</body>
</html>
