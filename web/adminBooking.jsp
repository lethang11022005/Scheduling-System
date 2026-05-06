<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="model.Booking"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
    Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("stats");
    String error = request.getParameter("error") != null ? request.getParameter("error") : (String) request.getAttribute("error");
    String success = request.getParameter("success") != null ? request.getParameter("success") : (String) request.getAttribute("success");
    String date = request.getAttribute("date") == null ? "" : String.valueOf(request.getAttribute("date"));
    String status = request.getAttribute("status") == null ? "" : String.valueOf(request.getAttribute("status"));
    String sort = request.getAttribute("sort") == null ? "date" : String.valueOf(request.getAttribute("sort"));
    int currentPage = request.getAttribute("currentPage") == null ? 1 : (Integer) request.getAttribute("currentPage");
    int totalPages = request.getAttribute("totalPages") == null ? 1 : (Integer) request.getAttribute("totalPages");
    DateTimeFormatter viDateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
%>
<div>
    <div class="topbar">
        <h2>Quản lý lịch khám</h2>
    </div>
    <% if (error != null && !error.isBlank()) { %>
    <p class="alert error"><%= error %></p>
    <% } %>
    <% if (success != null && !success.isBlank()) { %>
    <p class="alert success"><%= success %></p>
    <% } %>
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
        <form action="DashboardController" method="get" class="filter">
            <input type="hidden" name="view" value="adminBooking">
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
            <a class="btn btn-ghost" href="DashboardController?view=adminBooking">Đặt lại</a>
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
                        <form action="DashboardController" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="approve">
                            <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                            <input type="hidden" name="view" value="adminBooking">
                            <button class="approve" type="submit">Duyệt</button>
                        </form>
                        <form action="DashboardController" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="reject">
                            <input type="hidden" name="bookingId" value="<%= booking.getId() %>">
                            <input type="hidden" name="view" value="adminBooking">
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
        <div class="pagination">
            <% for (int i = 1; i <= totalPages; i++) { %>
            <a class="<%= i == currentPage ? "current" : "" %>" href="DashboardController?view=adminBooking&date=<%= date %>&status=<%= status %>&sort=<%= sort %>&page=<%= i %>"><%= i %></a>
            <% } %>
        </div>
    </section>
</div>
