<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String role = String.valueOf(session.getAttribute("role"));
    String username = String.valueOf(session.getAttribute("username"));
%>
<aside class="sidebar">
    <div class="brand"><span>Clinic</span>Care</div>
    <nav class="menu">
        <a class="active" href="#" id="menuHome">Trang chủ</a>
        <% if ("admin".equalsIgnoreCase(role)) { %>
        <a href="DashboardController?view=adminBooking">Quản lý lịch khám</a>
        <a href="#">Nhân sự</a>
        <a href="#">Lịch trực</a>
        <form action="LoginController" method="post" style="margin:0;">
            <input type="hidden" name="action" value="logout">
            <button type="submit" style="width:100%;text-align:left;padding:10px 12px;border-radius:10px;border:1px solid transparent;background:transparent;color:#334155;font-size:14px;cursor:pointer;">Đăng xuất</button>
        </form>
        <% } else { %>
        <a href="#" id="menuBooking">Đặt lịch khám</a>
        <a href="#" id="menuMyBookings">Lịch khám của tôi</a>
        <% } %>
    </nav>
</aside>
