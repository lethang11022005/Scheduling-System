<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String error = request.getParameter("error") != null ? request.getParameter("error") : (String) request.getAttribute("error");
    String success = request.getParameter("success") != null ? request.getParameter("success") : (String) request.getAttribute("success");
    Object role = session.getAttribute("role");
    if (role != null) {
        response.sendRedirect("DashboardController");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Đăng nhập - Hệ thống đặt lịch khám bệnh</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(120deg, #eef2ff, #dbeafe);
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
        }
        .card {
            background: #fff;
            padding: 24px;
            width: 360px;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
        }
        h2 { margin-top: 0; color: #1f2937; }
        label { display: block; margin-top: 12px; color: #374151; }
        input {
            width: 100%;
            padding: 10px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            margin-top: 6px;
            box-sizing: border-box;
        }
        button {
            width: 100%;
            margin-top: 16px;
            background: #2563eb;
            color: #fff;
            border: none;
            padding: 10px;
            border-radius: 8px;
            cursor: pointer;
        }
        .error { color: #b91c1c; margin-top: 10px; }
        .success { color: #15803d; margin-top: 10px; }
    </style>
</head>
<body>
<div class="card">
    <h2>Đăng nhập hệ thống khám bệnh</h2>
    <form action="LoginController" method="post" id="loginForm" autocomplete="on">
        <label>Tên đăng nhập</label>
        <input type="text" name="username" id="username" required autocomplete="username">

        <label>Mật khẩu</label>
        <input type="password" name="password" id="password" required autocomplete="current-password">

        <label style="display:flex;align-items:center;gap:8px;margin-top:12px;">
            <input type="checkbox" id="rememberMe" style="width:auto;margin:0;">
            Ghi nhớ tên đăng nhập
        </label>

        <button type="submit">Đăng nhập</button>
    </form>

    <% if (error != null && !error.isBlank()) { %>
    <p class="error"><%= error %></p>
    <% } %>

    <% if (success != null && !success.isBlank()) { %>
    <p class="success"><%= success %></p>
    <% } %>
</div>

<script>
    (function () {
        const usernameInput = document.getElementById('username');
        const rememberMe = document.getElementById('rememberMe');
        const loginForm = document.getElementById('loginForm');

        const savedUsername = localStorage.getItem('booking_saved_username');
        const rememberFlag = localStorage.getItem('booking_remember_me');

        if (rememberFlag === 'true' && savedUsername) {
            usernameInput.value = savedUsername;
            rememberMe.checked = true;
        }

        loginForm.addEventListener('submit', function () {
            if (rememberMe.checked) {
                localStorage.setItem('booking_saved_username', usernameInput.value || '');
                localStorage.setItem('booking_remember_me', 'true');
            } else {
                localStorage.removeItem('booking_saved_username');
                localStorage.setItem('booking_remember_me', 'false');
            }

        });
    })();
</script>
</body>
</html>
