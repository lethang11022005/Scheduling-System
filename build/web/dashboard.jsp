<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="java.time.LocalDate"%>
<%@page import="model.DoctorDuty"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
        return;
    }

    String role = String.valueOf(session.getAttribute("role"));
    String username = String.valueOf(session.getAttribute("username"));
    Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("stats");
    Map<String, Integer> profileStats = (Map<String, Integer>) request.getAttribute("profileStats");
    Map<LocalDate, List<DoctorDuty>> dutyCalendar = (Map<LocalDate, List<DoctorDuty>>) request.getAttribute("dutyCalendar");
    String error = request.getAttribute("error") == null ? null : String.valueOf(request.getAttribute("error"));
    String profileError = request.getParameter("error");
    String profileSuccess = request.getParameter("success");
    String view = request.getParameter("view") == null ? "home" : request.getParameter("view");

    LocalDate now = LocalDate.now();
    LocalDate statsDate = (LocalDate) request.getAttribute("statsDate");
    Integer viewYearAttr = (Integer) request.getAttribute("viewYear");
    Integer viewMonthAttr = (Integer) request.getAttribute("viewMonth");
    Integer maxViewYearAttr = (Integer) request.getAttribute("maxViewYear");
    int viewYear = viewYearAttr == null ? now.getYear() : viewYearAttr;
    int viewMonth = viewMonthAttr == null ? now.getMonthValue() : viewMonthAttr;
    int maxViewYear = maxViewYearAttr == null ? 2030 : maxViewYearAttr;
    if (statsDate == null) {
        statsDate = now;
    }
    int userId = (Integer) session.getAttribute("userId");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tổng quan - Hệ thống đặt lịch khám bệnh</title>
    <style>
        :root {
            --blue: #2467e8;
            --bg: #e9f2ff;
            --panel: #ffffff;
            --line: #dde6f2;
            --text: #1f2937;
            --muted: #6b7280;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: 'Segoe UI', sans-serif;
            background: radial-gradient(circle at 0 100%, #b9d5ff 0%, transparent 42%), linear-gradient(120deg, #dbeafe, #e6f4ff);
            color: var(--text);
            padding: 22px;
        }

        .shell {
            max-width: 1450px;
            margin: 0 auto;
            background: rgba(255,255,255,.75);
            border: 1px solid rgba(255,255,255,.95);
            border-radius: 20px;
            box-shadow: 0 18px 50px rgba(30, 60, 110, .12);
            overflow: hidden;
            display: grid;
            grid-template-columns: 220px 1fr;
            animation: fadeIn .45s ease;
        }

        .sidebar {
            background: rgba(255,255,255,.82);
            border-right: 1px solid var(--line);
            padding: 18px 14px;
            transition: background .2s ease;
        }

        .sidebar:hover { background: rgba(255,255,255,.92); }

        .brand {
            font-size: 34px;
            font-weight: 700;
            margin-bottom: 18px;
        }

        .brand span { color: var(--blue); }

        .menu a {
            display: block;
            padding: 10px 12px;
            border-radius: 10px;
            text-decoration: none;
            color: #334155;
            margin-bottom: 6px;
            border: 1px solid transparent;
            font-size: 14px;
            transition: all .2s ease;
        }

        .menu a:hover,
        .menu a.active {
            background: #eff5ff;
            color: #1d4ed8;
            border-color: #d4e1fb;
        }

        .main {
            padding: 14px;
        }

        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid var(--line);
            border-radius: 14px;
            background: #fff;
            padding: 10px 12px;
            margin-bottom: 12px;
        }

        .avatar-wrap {
            position: relative;
            display: inline-flex;
            align-items: center;
        }

        .topbar .title {
            font-size: 17px;
            color: #475569;
        }

        .avatar {
            width: 36px;
            height: 36px;
            border-radius: 999px;
            background: linear-gradient(120deg, #2d79ff, #22d3ee);
            color: #fff;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            cursor: pointer;
            transition: transform .2s ease, box-shadow .2s ease;
            position: relative;
            overflow: hidden;
        }

        .avatar:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(36,103,232,.25);
        }

        .avatar.tap {
            animation: avatarTap .35s ease;
        }

        .avatar::after {
            content: "";
            position: absolute;
            inset: -2px;
            border-radius: 999px;
            border: 2px solid rgba(255,255,255,.65);
            opacity: 0;
            transform: scale(.75);
            pointer-events: none;
        }

        .avatar.tap::after {
            animation: avatarPulse .45s ease;
        }

        .user-menu {
            position: absolute;
            right: 0;
            top: 44px;
            min-width: 210px;
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 12px;
            box-shadow: 0 16px 30px rgba(15, 23, 42, .14);
            padding: 8px;
            z-index: 20;
            display: none;
            transform-origin: top right;
        }

        .user-menu.open {
            display: block;
            animation: menuDrop .22s ease;
        }

        .user-menu a,
        .user-menu button {
            width: 100%;
            border: 0;
            background: transparent;
            display: block;
            text-align: left;
            text-decoration: none;
            color: #334155;
            border-radius: 8px;
            padding: 9px 10px;
            font-size: 13px;
            cursor: pointer;
        }

        .user-menu form { margin: 0; }

        .user-menu a:hover,
        .user-menu button:hover {
            background: #eff5ff;
            color: #1d4ed8;
        }

        .grid {
            display: grid;
            grid-template-columns: 1.45fr .55fr;
            gap: 12px;
        }

        #homeView {
            align-items: start;
        }

        .card {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 12px;
            transition: transform .2s ease, box-shadow .2s ease;
        }

        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 24px rgba(36,103,232,.08);
        }

        .calendar-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }

        .calendar-nav {
            display: inline-flex;
            gap: 6px;
            align-items: center;
        }

        .cal-nav-btn {
            border: 1px solid #cbd5e1;
            border-radius: 999px;
            background: #f8fafc;
            color: #1f2937;
            width: 28px;
            height: 28px;
            cursor: pointer;
        }

        .calendar-title {
            font-weight: 700;
            font-size: 16px;
        }

        .weekday,
        .date-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 6px;
            text-align: center;
        }

        .weekday div {
            color: var(--muted);
            font-size: 11px;
            font-weight: 600;
            padding: 5px 0;
        }

        .day {
            background: #f8fbff;
            border: 1px solid #edf2f9;
            min-height: 62px;
            border-radius: 8px;
            font-size: 13px;
            display: flex;
            flex-direction: column;
            align-items: flex-start;
            justify-content: flex-start;
            padding: 6px;
            color: #334155;
            cursor: pointer;
            transition: border-color .2s ease, background .2s ease;
            position: relative;
            overflow: visible;
            z-index: 1;
        }

        .day:hover { z-index: 12; }

        .day.today {
            border-color: #90b6ff;
            background: #ecf3ff;
            font-weight: 700;
        }

        .day.weekend {
            background: #fff2f2;
            border-color: #ffd7d7;
            color: #b91c1c;
        }

        .day.active {
            border-color: #6696f3;
            box-shadow: 0 0 0 2px #dbe7ff inset;
        }

        .date-num {
            font-weight: 600;
            margin-bottom: 4px;
        }

        .duty-summary {
            font-size: 10px;
            color: #1e3a8a;
            margin-bottom: 2px;
        }

        .duty-mini {
            font-size: 10px;
            color: #334155;
            line-height: 1.3;
        }

        .duty-off {
            font-size: 10px;
            border-radius: 999px;
            border: 1px solid #fecaca;
            color: #b91c1c;
            background: #fff1f1;
            padding: 1px 6px;
        }

        .duty-popover {
            position: absolute;
            top: calc(100% + 6px);
            left: 0;
            width: 230px;
            border: 1px solid #c9d7ee;
            background: #ffffff;
            border-radius: 10px;
            box-shadow: 0 12px 24px rgba(15, 23, 42, .16);
            padding: 8px;
            opacity: 0;
            visibility: hidden;
            transform: translateY(4px);
            transition: all .16s ease;
            pointer-events: none;
        }

        .day:hover .duty-popover {
            opacity: 1;
            visibility: visible;
            transform: translateY(0);
            pointer-events: auto;
        }

        .duty-pop-title {
            font-size: 11px;
            color: #1f2937;
            font-weight: 700;
            margin-bottom: 6px;
        }

        .duty-scroll {
            max-height: 120px;
            overflow-y: auto;
            padding-right: 2px;
            display: grid;
            gap: 6px;
        }

        .duty-item {
            border: 1px solid #dbe7ff;
            background: #f7faff;
            border-radius: 8px;
            padding: 5px 6px;
            font-size: 11px;
            color: #1e3a8a;
            display: flex;
            justify-content: space-between;
            gap: 8px;
        }

        .duty-item span {
            color: #334155;
            font-weight: 600;
            white-space: nowrap;
        }

        .duty-empty {
            font-size: 11px;
            color: #b91c1c;
            background: #fff5f5;
            border: 1px solid #fecaca;
            border-radius: 8px;
            padding: 6px;
        }

        .badges {
            display: flex;
            flex-wrap: wrap;
            gap: 3px;
        }

        .badge {
            border-radius: 999px;
            font-size: 10px;
            padding: 1px 6px;
            line-height: 1.3;
            border: 1px solid transparent;
            white-space: nowrap;
        }

        .b-green { background: #ecfdf3; color: #15803d; border-color: #b7eec8; }
        .b-yellow { background: #fffbeb; color: #a16207; border-color: #fde68a; }
        .b-blue { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
        .b-red { background: #fef2f2; color: #b91c1c; border-color: #fecaca; }

        .actions {
            display: grid;
            gap: 10px;
        }

        .btn {
            text-decoration: none;
            display: block;
            text-align: center;
            background: var(--blue);
            color: #fff;
            border-radius: 10px;
            padding: 11px;
            font-weight: 600;
            font-size: 14px;
        }

        .btn.secondary {
            background: #fff;
            color: #2563eb;
            border: 1px solid #bcd0f7;
        }

        .stats {
            display: grid;
            gap: 8px;
            margin-top: 10px;
        }

        .stat {
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px;
            display: flex;
            justify-content: space-between;
            background: #fbfdff;
            font-size: 13px;
        }

        .stat b { color: #1d4ed8; }

        .intro {
            margin-top: 12px;
            border: 1px dashed #c9d7ee;
            border-radius: 10px;
            padding: 10px;
            font-size: 14px;
            color: #475569;
            background: #f8fbff;
        }

        #dayDetailsPanel {
            display: flex;
            flex-direction: column;
            max-height: 76vh;
            overflow: hidden;
        }

        #dayDetailsPanel .stats {
            flex: 0 0 auto;
        }

        #dayDetailsPanel .details-list {
            margin-top: 8px;
            display: grid;
            gap: 8px;
            flex: 1 1 auto;
            min-height: 0;
            max-height: calc(76vh - 250px);
            overflow-y: auto;
            padding-right: 4px;
            scrollbar-gutter: stable;
        }

        .detail-item {
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 8px;
            background: #fbfdff;
            font-size: 13px;
        }

        .detail-item .time {
            float: right;
            color: #1d4ed8;
            font-weight: 600;
        }

        .meeting-note {
            font-size: 13px;
            border: 1px dashed #c9d7ee;
            border-radius: 10px;
            padding: 10px;
            color: #475569;
            background: #f8fbff;
        }

        .profile-box {
            border: 1px solid var(--line);
            border-radius: 12px;
            background: #f9fbff;
            padding: 10px;
            margin-bottom: 10px;
            font-size: 14px;
        }

        .password-panel {
            border: 1px solid var(--line);
            border-radius: 12px;
            background: linear-gradient(140deg, #f8fbff, #eef5ff);
            padding: 14px;
        }

        .password-panel label {
            display: block;
            font-size: 13px;
            color: #475569;
            margin-bottom: 6px;
            margin-top: 8px;
        }

        .password-panel input {
            width: 100%;
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            padding: 10px;
            font-size: 14px;
            background: #fff;
        }

        .password-panel .submit-btn {
            margin-top: 12px;
            width: 100%;
            border: none;
            border-radius: 10px;
            padding: 10px;
            background: linear-gradient(120deg, #2563eb, #3b82f6);
            color: #fff;
            font-weight: 600;
            cursor: pointer;
        }

        .flash-ok {
            color: #166534;
            background: #ecfdf5;
            border: 1px solid #bbf7d0;
            border-radius: 10px;
            padding: 8px 10px;
            font-size: 13px;
            margin-bottom: 8px;
        }

        .flash-bad {
            color: #991b1b;
            background: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: 10px;
            padding: 8px 10px;
            font-size: 13px;
            margin-bottom: 8px;
        }

        .booking-layout {
            display: grid;
            grid-template-columns: 1.55fr 1fr;
            gap: 14px;
            align-items: start;
        }

        .booking-card {
            border: 1px solid var(--line);
            border-radius: 14px;
            background: #ffffff;
            padding: 14px;
            height: 100%;
        }

        .booking-left {
            display: grid;
            grid-template-columns: 1fr;
            grid-template-areas:
                "calendar"
                "slots";
            gap: 12px;
            align-items: start;
            min-height: 560px;
        }

        .booking-calendar { grid-area: calendar; }

        .booking-time-wrap {
            grid-area: slots;
            border-top: 1px dashed #dbeafe;
            padding-top: 12px;
        }

        .booking-time-title {
            margin: 0 0 8px;
            font-size: 13px;
            font-weight: 700;
            color: #1e3a8a;
        }

        .booking-calendar {
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 12px;
            background: linear-gradient(180deg, #f8fbff 0%, #ffffff 38%);
            box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
        }

        .booking-cal-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 8px;
            margin-bottom: 10px;
        }

        .booking-cal-controls {
            display: flex;
            align-items: center;
            gap: 8px;
            flex: 1;
        }

        .booking-cal-select {
            border: 1px solid #dbe7ff;
            border-radius: 10px;
            background: #fff;
            color: #0f172a;
            font-size: 13px;
            font-weight: 600;
            padding: 7px 10px;
            min-width: 98px;
        }

        .booking-cal-today {
            border: 1px solid #c7d2fe;
            background: #eef2ff;
            color: #3730a3;
            border-radius: 10px;
            padding: 7px 11px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }

        .booking-cal-nav {
            width: 34px;
            height: 34px;
            border: 1px solid #cbd5e1;
            border-radius: 999px;
            background: #f8fafc;
            color: #334155;
            font-size: 20px;
            line-height: 1;
            cursor: pointer;
        }

        .booking-weekdays,
        .booking-date-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 6px;
        }

        .booking-date-grid {
            grid-template-rows: repeat(6, 42px);
            min-height: calc(42px * 6 + 6px * 5);
        }

        .booking-weekdays div {
            text-align: center;
            color: #475569;
            font-size: 10px;
            font-weight: 700;
            padding: 6px 0;
            border-radius: 8px;
            background: #eef4ff;
        }

        .booking-day {
            border: 1px solid #dbeafe;
            background: #ffffff;
            width: 100%;
            height: 42px;
            border-radius: 10px;
            cursor: pointer;
            color: #1f2937;
            font-size: 14px;
            font-weight: 600;
            transition: all .15s ease;
        }

        .booking-day:hover {
            background: #eff6ff;
            border-color: #93c5fd;
        }

        .booking-day.active {
            background: #2563eb;
            border-color: #2563eb;
            color: #fff;
            font-weight: 700;
            box-shadow: 0 6px 16px rgba(37, 99, 235, 0.28);
        }

        .booking-day.weekend {
            color: #dc2626;
            border-color: #fecaca;
            background: #fff5f5;
        }

        .booking-day:disabled,
        .booking-day.past {
            opacity: .45;
            cursor: not-allowed;
            text-decoration: line-through;
        }

        .booking-day.blank { visibility: hidden; }

        .booking-time-col {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(94px, 1fr));
            gap: 6px;
            align-content: start;
            min-height: 220px;
            max-height: none;
            overflow-y: visible;
            transition: opacity .15s ease;
        }

        .booking-time-col.loading {
            opacity: .65;
            pointer-events: none;
        }

        .bk-slot {
            border: 1px solid #3b82f6;
            background: #fff;
            color: #1d4ed8;
            border-radius: 999px;
            width: 100%;
            padding: 7px 10px;
            font-size: 14px;
            font-weight: 600;
            text-align: center;
            cursor: pointer;
            min-width: 0;
            height: 38px;
        }

        .bk-slot.selected {
            background: #2563eb;
            border-color: #2563eb;
            color: #fff;
        }

        .bk-slot[disabled] {
            opacity: .5;
            text-decoration: line-through;
            cursor: not-allowed;
        }

        .booking-meta {
            display: grid;
            gap: 8px;
            margin-top: 10px;
        }

        .booking-meta label {
            font-size: 12px;
            color: #64748b;
        }

        .booking-meta input,
        .booking-meta select {
            width: 100%;
            border: 1px solid #cbd5e1;
            border-radius: 10px;
            padding: 8px 9px;
            font-size: 12px;
            background: #fff;
        }

        .booking-confirm h3 {
            margin: 0;
            font-size: 36px;
            color: #0f172a;
        }

        .booking-box {
            border: 1px solid var(--line);
            border-radius: 12px;
            background: #eef4ff;
            padding: 12px;
            margin: 10px 0;
        }

        .booking-msg {
            min-height: 18px;
            font-size: 13px;
            color: #64748b;
        }

        .booking-msg.error { color: #b91c1c; }
        .booking-msg.success { color: #166534; }

        .booking-submit {
            width: 100%;
            border: none;
            border-radius: 999px;
            padding: 10px;
            background: linear-gradient(120deg, #2563eb, #3b82f6);
            color: #fff;
            font-weight: 600;
            cursor: pointer;
        }

        .booking-submit:disabled {
            opacity: .6;
            cursor: not-allowed;
        }

        .hidden { display: none; }

        .error { color: #b91c1c; margin-top: 8px; font-size: 13px; }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @keyframes avatarTap {
            0% { transform: scale(1); }
            45% { transform: scale(.9); }
            100% { transform: scale(1); }
        }

        @keyframes avatarPulse {
            0% { opacity: .85; transform: scale(.75); }
            100% { opacity: 0; transform: scale(1.25); }
        }

        @keyframes menuDrop {
            0% { opacity: 0; transform: translateY(-6px) scale(.96); }
            100% { opacity: 1; transform: translateY(0) scale(1); }
        }

        @media (max-width: 1100px) {
            .shell { grid-template-columns: 1fr; }
            .grid { grid-template-columns: 1fr; }
            .booking-layout { grid-template-columns: 1fr; }
            .booking-left {
                grid-template-columns: 1fr;
                grid-template-areas:
                    "calendar"
                    "slots";
            }
            .booking-calendar {
                border: none;
                padding: 0;
            }
            .booking-time-col {
                max-height: none;
            }
        }
    </style>
</head>
<body data-year="<%= viewYear %>" data-month="<%= viewMonth %>" data-max-year="<%= maxViewYear %>" data-view="<%= view %>">
<div class="shell">
    <jsp:include page="sidebar.jsp"/>

    <main class="main">
        <div class="topbar">
            <div class="title">Xin chào, <b><%= username %></b> | Vai trò: <%= "admin".equalsIgnoreCase(role) ? "Quản trị" : "Bệnh nhân" %></div>
            <div class="avatar-wrap">
                <div class="avatar" id="avatarTrigger" title="Mở menu tài khoản"><%= username.isBlank() ? "U" : username.substring(0, 1).toUpperCase() %></div>
                <% if (!"admin".equalsIgnoreCase(role)) { %>
                <div class="user-menu" id="userMenu">
                    <button type="button" id="openProfileBtn">Hồ sơ của tôi</button>
                    <form action="LoginController" method="post">
                        <input type="hidden" name="action" value="logout">
                        <button type="submit">Đăng xuất</button>
                    </form>
                </div>
                <% } %>
            </div>
        </div>

        <% if ("admin".equalsIgnoreCase(role) && "adminBooking".equals(view)) { %>
            <jsp:include page="adminBooking.jsp"/>
        <% } else { %>
        <div class="grid" id="homeView">
            <section class="card">
                <div class="calendar-head">
                    <div class="calendar-nav">
                        <button type="button" class="cal-nav-btn" id="calendarPrevBtn">&#8249;</button>
                        <div class="calendar-title">Lịch khám tổng quan - <%= viewMonth %>/<%= viewYear %></div>
                        <button type="button" class="cal-nav-btn" id="calendarNextBtn">&#8250;</button>
                    </div>
                    <span style="font-size:12px;color:#64748b;">Hôm nay: <%= now %></span>
                </div>
                <div class="weekday">
                    <div>CN</div><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div>
                </div>
                <div class="date-grid" id="calendarGrid">
                    <% 
                        LocalDate first = LocalDate.of(viewYear, viewMonth, 1);
                        int startIndex = first.getDayOfWeek().getValue() % 7;
                        int daysInMonth = first.lengthOfMonth();
                        for (int i = 0; i < startIndex; i++) {
                    %>
                    <div class="day"></div>
                    <% }
                        for (int d = 1; d <= daysInMonth; d++) {
                            LocalDate current = first.withDayOfMonth(d);
                            boolean today = current.equals(now);
                            boolean weekend = current.getDayOfWeek().getValue() >= 6;
                            List<DoctorDuty> dayDuties = dutyCalendar == null
                                    ? java.util.Collections.emptyList()
                                    : dutyCalendar.getOrDefault(current, java.util.Collections.emptyList());
                            int doctorCount = dayDuties.size();
                    %>
                    <div class="day <%= today ? "today" : "" %> <%= weekend ? "weekend" : "" %> <%= current.equals(statsDate) ? "active" : "" %>" data-day="<%= d %>" data-date="<%= current %>">
                        <div class="date-num"><%= d %></div>
                        <% if (!weekend && doctorCount > 0) { %>
                        <div class="duty-summary">Trực: <%= doctorCount %> bác sĩ</div>
                        <div class="duty-mini">
                            <%= dayDuties.get(0).getDoctorName() %><br><%= dayDuties.get(0).getShiftStart() %>-<%= dayDuties.get(0).getShiftEnd() %>
                        </div>
                        <div class="duty-popover">
                            <div class="duty-pop-title">Danh sách bác sĩ trực</div>
                            <div class="duty-scroll">
                                <% for (DoctorDuty duty : dayDuties) {
                                    String doctor = duty.getDoctorName();
                                    String shift = duty.getShiftStart() + "-" + duty.getShiftEnd();
                                %>
                                <div class="duty-item" data-doctor="<%= doctor %>" data-shift="<%= shift %>"><b><%= doctor %></b><span><%= shift %></span></div>
                                <% } %>
                            </div>
                        </div>
                        <% } else if (!weekend) { %>
                        <span class="duty-off" style="border-color:#c7d2fe;color:#1e3a8a;background:#eef2ff;">Chưa phân ca</span>
                        <div class="duty-popover">
                            <div class="duty-pop-title">Thông tin trực</div>
                            <div class="duty-empty" style="color:#1e3a8a;background:#eef2ff;border-color:#c7d2fe;">Chưa có bác sĩ được phân ca trong ngày này.</div>
                        </div>
                        <% } else { %>
                        <span class="duty-off">Nghỉ</span>
                        <div class="duty-popover">
                            <div class="duty-pop-title">Thông tin trực</div>
                            <div class="duty-empty">Ngày nghỉ cuối tuần, không bố trí bác sĩ trực.</div>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <div class="intro">
                    Lịch làm việc tiêu chuẩn từ thứ 2 đến thứ 6; thứ 7 và chủ nhật được tô đỏ để phân biệt ngày nghỉ.
                </div>
                <% if (error != null && !error.isBlank()) { %>
                <div class="error"><%= error %></div>
                <% } %>
            </section>
        </div>
        <% } %>

            <aside class="card" id="dayDetailsPanel">
                <h3 style="margin:0 0 8px;" id="activityTitle">Hoạt động ngày <%= statsDate %></h3>
                <div class="stats">
                    <div class="stat"><span>Chờ duyệt</span><b id="statPending"><%= stats == null ? 0 : stats.get("pending") %></b></div>
                    <div class="stat"><span>Đã duyệt</span><b id="statApproved"><%= stats == null ? 0 : stats.get("approved") %></b></div>
                    <div class="stat"><span>Từ chối</span><b id="statRejected"><%= stats == null ? 0 : stats.get("rejected") %></b></div>
                    <div class="stat"><span>Đã hủy</span><b id="statCancelled"><%= stats == null ? 0 : stats.get("cancelled") %></b></div>
                    <div class="stat"><span>Tổng trong ngày</span><b id="statToday"><%= stats == null ? 0 : stats.get("today") %></b></div>
                </div>

                <h3 style="margin:14px 0 8px;">Chi tiết ngày</h3>
                <div id="detailsDayLabel" style="font-size:13px;color:#64748b;margin-bottom:6px;">Chọn ngày trên lịch để xem chi tiết</div>
                <div class="details-list" id="detailsList">
                    <div class="detail-item">Bấm vào ngày để xem danh sách bác sĩ trực.</div>
                </div>
            </aside>
        </div>

        <% if (!"admin".equalsIgnoreCase(role)) { %>
        <div class="hidden" id="bookingView">
            <section class="card booking-layout">
                <div class="booking-card booking-left">
                    <div class="booking-calendar">
                        <div class="booking-cal-head">
                            <button type="button" class="booking-cal-nav" id="bookingPrevMonth" aria-label="Tháng trước">&#8249;</button>
                            <div class="booking-cal-controls">
                                <select id="bookingMonthSelect" class="booking-cal-select" aria-label="Chọn tháng"></select>
                                <select id="bookingYearSelect" class="booking-cal-select" aria-label="Chọn năm"></select>
                                <button type="button" class="booking-cal-today" id="bookingTodayBtn">Hôm nay</button>
                            </div>
                            <button type="button" class="booking-cal-nav" id="bookingNextMonth" aria-label="Tháng sau">&#8250;</button>
                        </div>
                        <div class="booking-weekdays">
                            <div>CN</div><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div>
                        </div>
                        <div class="booking-date-grid" id="bookingCalendarGrid"></div>
                    </div>

                    <div class="booking-time-wrap">
                        <h4 class="booking-time-title">Giờ khám trống</h4>
                        <div class="booking-time-col" id="bookingSlots">
                            <button type="button" class="bk-slot" disabled>Đang tải...</button>
                        </div>
                    </div>
                    <input type="hidden" id="bookingDate" value="<%= statsDate %>">
                </div>

                <div class="booking-card booking-confirm">
                    <h3>Xác nhận lịch</h3>
                    <div class="booking-box">
                        <div id="bookingSummaryDate">Ngày: <%= statsDate %></div>
                        <div id="bookingSummaryTime" style="margin-top:6px;">Giờ: Chưa chọn</div>
                    </div>
                    <div class="booking-meta" style="margin-top:0;">
                        <div>
                            <label>Họ tên</label>
                            <input type="text" id="bookingName" value="<%= username %>">
                        </div>
                        <div>
                            <label>Số điện thoại</label>
                            <input type="tel" id="bookingPhone" placeholder="0xxxxxxxxx" inputmode="numeric" maxlength="10" pattern="0[0-9]{9}" title="Số điện thoại gồm 10 số, bắt đầu bằng 0">
                        </div>
                    </div>
                    <div class="booking-msg" id="bookingMsg"></div>
                    <button type="button" id="bookingSubmitBtn" class="booking-submit" disabled>Xác nhận đặt lịch</button>
                    <input type="hidden" id="bookingCsrf" value="<%= session.getAttribute("csrfToken") %>">
                </div>
            </section>
        </div>
        <% } %>

        <% if (!"admin".equalsIgnoreCase(role)) { %>
        <div class="hidden" id="myBookingsView">
            <section class="card" style="padding:0;overflow:hidden;">
                <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 14px;border-bottom:1px solid var(--line);background:#f8fbff;">
                    <h3 style="margin:0;font-size:18px;color:#0f172a;">Lịch khám của tôi</h3>
                    <button type="button" id="refreshMyBookingsBtn" class="booking-cal-today" style="padding:6px 10px;">Làm mới</button>
                </div>
                <iframe id="myBookingsFrame" src="BookingController?action=listUser" style="width:100%;height:72vh;border:none;background:#fff;" loading="lazy"></iframe>
            </section>
        </div>
        <% } %>

        <% if (!"admin".equalsIgnoreCase(role)) { %>
        <div class="grid hidden" id="profileView">
            <section class="card">
                <h3 style="margin:0 0 10px;">Đổi mật khẩu</h3>
                <% if (profileSuccess != null && !profileSuccess.isBlank()) { %>
                <div class="flash-ok"><%= profileSuccess %></div>
                <% } %>
                <% if (profileError != null && !profileError.isBlank()) { %>
                <div class="flash-bad"><%= profileError %></div>
                <% } %>

                <div class="password-panel">
                    <form action="ProfileController" method="post">
                        <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
                        <label>Mật khẩu hiện tại</label>
                        <input type="password" name="currentPassword" required>

                        <label>Mật khẩu mới</label>
                        <input type="password" name="newPassword" minlength="6" required>

                        <label>Xác nhận mật khẩu mới</label>
                        <input type="password" name="confirmPassword" minlength="6" required>

                        <button class="submit-btn" type="submit">Cập nhật mật khẩu</button>
                    </form>
                </div>

                <h3 style="margin:14px 0 8px;">Tình trạng lịch khám</h3>
                <div class="stats">
                    <div class="stat"><span>Chờ duyệt</span><b><%= profileStats == null ? 0 : profileStats.get("pending") %></b></div>
                    <div class="stat"><span>Đã duyệt</span><b><%= profileStats == null ? 0 : profileStats.get("approved") %></b></div>
                    <div class="stat"><span>Từ chối</span><b><%= profileStats == null ? 0 : profileStats.get("rejected") %></b></div>
                    <div class="stat"><span>Đã hủy</span><b><%= profileStats == null ? 0 : profileStats.get("cancelled") %></b></div>
                </div>
            </section>
        </div>
        <% } %>
    </main>
</div>

<script>
    (function () {
        const detailsList = document.getElementById('detailsList');
        const detailsLabel = document.getElementById('detailsDayLabel');
        const days = document.querySelectorAll('.day[data-day]');
        const pageRoot = document.body;
        const year = Number(pageRoot.getAttribute('data-year') || '0');
        const month = Number(pageRoot.getAttribute('data-month') || '0');
        const maxYear = Number(pageRoot.getAttribute('data-max-year') || '2030');
        const initialView = pageRoot.getAttribute('data-view') || 'home';
        const calendarPrevBtn = document.getElementById('calendarPrevBtn');
        const calendarNextBtn = document.getElementById('calendarNextBtn');
        const activityTitle = document.getElementById('activityTitle');
        const statPending = document.getElementById('statPending');
        const statApproved = document.getElementById('statApproved');
        const statRejected = document.getElementById('statRejected');
        const statCancelled = document.getElementById('statCancelled');
        const statToday = document.getElementById('statToday');

        async function loadActivityByDate(dateText) {
            if (!dateText) return;
            try {
                const res = await fetch('DashboardController?ajax=stats&statsDate=' + encodeURIComponent(dateText), {
                    headers: { 'Accept': 'application/json' }
                });
                if (!res.ok) return;

                const data = await res.json();
                if (activityTitle) activityTitle.textContent = 'Hoạt động ngày ' + (data.date || dateText);
                if (statPending) statPending.textContent = String(data.pending || 0);
                if (statApproved) statApproved.textContent = String(data.approved || 0);
                if (statRejected) statRejected.textContent = String(data.rejected || 0);
                if (statCancelled) statCancelled.textContent = String(data.cancelled || 0);
                if (statToday) statToday.textContent = String(data.today || 0);
            } catch (err) {
                console.error('Không thể tải thống kê theo ngày', err);
            }
        }

        days.forEach((cell) => {
            cell.addEventListener('click', () => {
                days.forEach((d) => d.classList.remove('active'));
                cell.classList.add('active');

                const pickedDate = cell.getAttribute('data-date') || '';

                const day = Number(cell.getAttribute('data-day'));
                detailsLabel.textContent = 'Chi tiết ngày ' + String(day).padStart(2, '0') + '/' + String(month).padStart(2, '0') + '/' + year;

                const doctorItems = cell.querySelectorAll('.duty-item');
                if (!doctorItems.length) {
                    detailsList.innerHTML = '<div class="detail-item">Ngày nghỉ, không có bác sĩ trực.</div>';
                } else {
                    detailsList.innerHTML = Array.from(doctorItems).map((item) => {
                        const doctor = item.getAttribute('data-doctor') || '';
                        const shift = item.getAttribute('data-shift') || '';
                        return '<div class="detail-item"><span class="time">' + shift + '</span><b>' + doctor + '</b><div style="font-size:12px;color:#64748b;">Bác sĩ trực trong ngày</div></div>';
                    }
                    ).join('');
                }

                loadActivityByDate(pickedDate);
            });
        });

        function navigateCalendar(direction) {
            let targetMonth = month + direction;
            let targetYear = year;
            if (targetMonth < 1) {
                targetMonth = 12;
                targetYear -= 1;
            } else if (targetMonth > 12) {
                targetMonth = 1;
                targetYear += 1;
            }
            if (targetYear > maxYear) {
                return;
            }
            const params = new URLSearchParams(window.location.search);
            params.set('year', String(targetYear));
            params.set('month', String(targetMonth));
            if (initialView) {
                params.set('view', initialView);
            }
            window.location.search = params.toString();
        }

        if (calendarPrevBtn) {
            calendarPrevBtn.addEventListener('click', () => navigateCalendar(-1));
        }
        if (calendarNextBtn) {
            calendarNextBtn.addEventListener('click', () => navigateCalendar(1));
        }

        const menuHome = document.getElementById('menuHome');
        const menuBooking = document.getElementById('menuBooking');
        const menuMyBookings = document.getElementById('menuMyBookings');
        const avatarTrigger = document.getElementById('avatarTrigger');
        const userMenu = document.getElementById('userMenu');
        const openProfileBtn = document.getElementById('openProfileBtn');
        const homeView = document.getElementById('homeView');
        const bookingView = document.getElementById('bookingView');
        const myBookingsView = document.getElementById('myBookingsView');
        const myBookingsFrame = document.getElementById('myBookingsFrame');
        const refreshMyBookingsBtn = document.getElementById('refreshMyBookingsBtn');
        const profileView = document.getElementById('profileView');

        const bookingDate = document.getElementById('bookingDate');
        const bookingSlots = document.getElementById('bookingSlots');
        const bookingMsg = document.getElementById('bookingMsg');
        const bookingSummaryDate = document.getElementById('bookingSummaryDate');
        const bookingSummaryTime = document.getElementById('bookingSummaryTime');
        const bookingName = document.getElementById('bookingName');
        const bookingPhone = document.getElementById('bookingPhone');
        const bookingSubmitBtn = document.getElementById('bookingSubmitBtn');
        const bookingCsrf = document.getElementById('bookingCsrf');
        const bookingMonthSelect = document.getElementById('bookingMonthSelect');
        const bookingYearSelect = document.getElementById('bookingYearSelect');
        const bookingTodayBtn = document.getElementById('bookingTodayBtn');
        const bookingCalendarGrid = document.getElementById('bookingCalendarGrid');
        const bookingPrevMonth = document.getElementById('bookingPrevMonth');
        const bookingNextMonth = document.getElementById('bookingNextMonth');

        let selectedBookingTime = '';
        let bookingCalendarYear = 0;
        let bookingCalendarMonth = 0;

        function setBookingMsg(message, isError) {
            if (!bookingMsg) return;
            bookingMsg.textContent = message || '';
            bookingMsg.classList.remove('error', 'success');
            if (message) {
                bookingMsg.classList.add(isError ? 'error' : 'success');
            }
        }

        function setBookingSelection(timeText) {
            selectedBookingTime = timeText || '';
            if (bookingSummaryTime) {
                bookingSummaryTime.textContent = 'Giờ: ' + (selectedBookingTime || 'Chưa chọn');
            }
            if (bookingSubmitBtn) {
                bookingSubmitBtn.disabled = !selectedBookingTime;
            }
        }

        function setBookingLoading(isLoading) {
            if (!bookingSlots) return;
            bookingSlots.classList.toggle('loading', !!isLoading);
        }

        function syncBookingCalendarStateFromDate() {
            if (!bookingDate || !bookingDate.value) return;
            const dt = new Date(bookingDate.value + 'T00:00:00');
            if (Number.isNaN(dt.getTime())) return;
            bookingCalendarYear = dt.getFullYear();
            bookingCalendarMonth = dt.getMonth();
        }

        function formatBookingDate(y, m, d) {
            const mm = String(m + 1).padStart(2, '0');
            const dd = String(d).padStart(2, '0');
            return y + '-' + mm + '-' + dd;
        }

        function toDateOnlyText(dateObj) {
            return dateObj.getFullYear()
                + '-' + String(dateObj.getMonth() + 1).padStart(2, '0')
                + '-' + String(dateObj.getDate()).padStart(2, '0');
        }

        function getMaxBookingDateText() {
            const now = new Date();
            return now.getFullYear() + '-04-30';
        }

        function setActiveBookingDay(dateText) {
            if (!bookingCalendarGrid) return;
            bookingCalendarGrid.querySelectorAll('.booking-day.active').forEach((el) => el.classList.remove('active'));
            const target = bookingCalendarGrid.querySelector('.booking-day[data-date="' + dateText + '"]');
            if (target) {
                target.classList.add('active');
            }
        }

        function populateBookingYearOptions() {
            if (!bookingYearSelect) return;
            const now = new Date();
            const max = new Date(getMaxBookingDateText() + 'T00:00:00');
            const startYear = now.getFullYear();
            const endYear = max.getFullYear();
            const opts = [];
            for (let y = startYear; y <= endYear; y++) {
                opts.push('<option value="' + y + '">' + y + '</option>');
            }
            bookingYearSelect.innerHTML = opts.join('');
        }

        function updateBookingSelectors() {
            if (bookingMonthSelect) {
                bookingMonthSelect.value = String(bookingCalendarMonth);
            }
            if (bookingYearSelect) {
                bookingYearSelect.value = String(bookingCalendarYear);
            }
        }

        function getBookingRangeParts() {
            const now = new Date();
            const maxDate = new Date(getMaxBookingDateText() + 'T00:00:00');
            return {
                minYear: now.getFullYear(),
                minMonth: now.getMonth(),
                maxYear: maxDate.getFullYear(),
                maxMonth: maxDate.getMonth()
            };
        }

        function populateBookingMonthOptions() {
            if (!bookingMonthSelect) return;
            const range = getBookingRangeParts();
            const startMonth = bookingCalendarYear === range.minYear ? range.minMonth : 0;
            const endMonth = bookingCalendarYear === range.maxYear ? range.maxMonth : 11;
            const labels = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];

            const options = [];
            for (let m = startMonth; m <= endMonth; m++) {
                options.push('<option value="' + m + '">' + labels[m] + '</option>');
            }
            bookingMonthSelect.innerHTML = options.join('');

            if (bookingCalendarMonth < startMonth || bookingCalendarMonth > endMonth) {
                bookingCalendarMonth = startMonth;
            }
        }

        function clampBookingCalendarRange() {
            const maxText = getMaxBookingDateText();
            const maxYear = parseInt(maxText.substring(0, 4), 10);
            const maxMonth = parseInt(maxText.substring(5, 7), 10) - 1;
            if (bookingCalendarYear > maxYear || (bookingCalendarYear === maxYear && bookingCalendarMonth > maxMonth)) {
                bookingCalendarYear = maxYear;
                bookingCalendarMonth = maxMonth;
            }
            const now = new Date();
            if (bookingCalendarYear < now.getFullYear()) {
                bookingCalendarYear = now.getFullYear();
                bookingCalendarMonth = now.getMonth();
            }
        }

        function renderBookingCalendar() {
            if (!bookingCalendarGrid) return;
            clampBookingCalendarRange();
            populateBookingMonthOptions();

            const first = new Date(bookingCalendarYear, bookingCalendarMonth, 1);
            const offset = first.getDay();
            const total = new Date(bookingCalendarYear, bookingCalendarMonth + 1, 0).getDate();

            const selectedText = bookingDate ? bookingDate.value : '';
            const now = new Date();
            const todayText = now.getFullYear()
                + '-' + String(now.getMonth() + 1).padStart(2, '0')
                + '-' + String(now.getDate()).padStart(2, '0');
            const maxBookingDateText = getMaxBookingDateText();

            if (bookingDate && bookingDate.value > maxBookingDateText) {
                bookingDate.value = maxBookingDateText;
            }

            updateBookingSelectors();

            const nodes = [];
            for (let i = 0; i < offset; i++) {
                nodes.push('<button type="button" class="booking-day blank">.</button>');
            }

            for (let d = 1; d <= total; d++) {
                const dateText = formatBookingDate(bookingCalendarYear, bookingCalendarMonth, d);
                const active = dateText === (bookingDate ? bookingDate.value : selectedText) ? 'active' : '';
                const isPastDate = dateText < todayText;
                const isAfterMaxDate = dateText > maxBookingDateText;
                const jsDay = new Date(bookingCalendarYear, bookingCalendarMonth, d).getDay();
                const isWeekend = (jsDay === 0 || jsDay === 6);
                const pastClass = isPastDate ? 'past' : '';
                const weekendClass = isWeekend ? 'weekend' : '';
                const disabled = (isPastDate || isAfterMaxDate || isWeekend) ? 'disabled' : '';
                nodes.push('<button type="button" class="booking-day ' + active + ' ' + pastClass + ' ' + weekendClass + '" data-date="' + dateText + '" ' + disabled + '>' + d + '</button>');
            }

            bookingCalendarGrid.innerHTML = nodes.join('');
            bookingCalendarGrid.querySelectorAll('.booking-day[data-date]:not([disabled])').forEach((btn) => {
                btn.addEventListener('click', () => {
                    if (!bookingDate) return;
                    bookingDate.value = btn.getAttribute('data-date') || bookingDate.value;
                    setActiveBookingDay(bookingDate.value);
                    loadBookingSlots();
                });
            });
        }

        function renderBookingSlots(slots, unavailableSlots) {
            if (!bookingSlots) return;
            const unavailable = new Set(unavailableSlots || []);

            const isToday = (() => {
                if (!bookingDate || !bookingDate.value) return false;
                const today = new Date();
                const yyyy = today.getFullYear();
                const mm = String(today.getMonth() + 1).padStart(2, '0');
                const dd = String(today.getDate()).padStart(2, '0');
                return bookingDate.value === (yyyy + '-' + mm + '-' + dd);
            })();

            const currentMinutes = (() => {
                if (!isToday) return -1;
                const now = new Date();
                return now.getHours() * 60 + now.getMinutes();
            })();

            const isPastDay = (() => {
                if (!bookingDate || !bookingDate.value) return false;
                const today = new Date();
                const todayText = today.getFullYear()
                    + '-' + String(today.getMonth() + 1).padStart(2, '0')
                    + '-' + String(today.getDate()).padStart(2, '0');
                return bookingDate.value < todayText;
            })();

            const html = (slots || []).map((slot) => {
                const parts = String(slot).split(':');
                const slotMinutes = (parseInt(parts[0], 10) * 60) + parseInt(parts[1], 10);
                const isPast = isToday && slotMinutes <= currentMinutes;
                const disabled = (unavailable.has(slot) || isPast || isPastDay) ? 'disabled' : '';
                return '<button type="button" class="bk-slot" data-time="' + slot + '" ' + disabled + '>' + slot + '</button>';
            }).join('');

            bookingSlots.innerHTML = html || '<button type="button" class="bk-slot" disabled>Không có giờ trống</button>';
            bookingSlots.querySelectorAll('.bk-slot:not([disabled])').forEach((btn) => {
                btn.addEventListener('click', () => {
                    bookingSlots.querySelectorAll('.bk-slot').forEach((item) => item.classList.remove('selected'));
                    btn.classList.add('selected');
                    setBookingSelection(btn.getAttribute('data-time') || '');
                });
            });
            setBookingSelection('');
        }

        async function loadBookingSlots(preserveMessage) {
            if (!bookingDate || !bookingSlots) return;

            const date = bookingDate.value;
            const duration = '60';
            const maxBookingDateText = getMaxBookingDateText();
            const selectedDt = new Date(date + 'T00:00:00');
            const isWeekend = !Number.isNaN(selectedDt.getTime()) && (selectedDt.getDay() === 0 || selectedDt.getDay() === 6);
            if (bookingSummaryDate) {
                bookingSummaryDate.textContent = 'Ngày: ' + date;
            }
            setBookingLoading(true);
            if (!preserveMessage) {
                setBookingMsg('', false);
            }

            if (date > maxBookingDateText) {
                renderBookingSlots([], []);
                setBookingMsg('Chỉ được đặt lịch đến hết tháng 4.', true);
                setBookingLoading(false);
                return;
            }

            if (isWeekend) {
                renderBookingSlots([], []);
                setBookingMsg('Thứ 7 và Chủ nhật là ngày nghỉ, không nhận đặt lịch.', true);
                setBookingLoading(false);
                return;
            }

            try {
                const res = await fetch('BookingController?action=slots&date=' + encodeURIComponent(date) + '&duration=' + encodeURIComponent(duration), {
                    headers: { 'Accept': 'application/json' }
                });
                const data = await res.json();
                if (!res.ok || !data.success) {
                    renderBookingSlots([], []);
                    setBookingMsg(data.message || 'Không thể tải giờ trống.', true);
                    setBookingLoading(false);
                    return;
                }
                renderBookingSlots(data.slots, data.unavailableSlots);
            } catch (err) {
                renderBookingSlots([], []);
                setBookingMsg('Không kết nối được máy chủ.', true);
            } finally {
                setBookingLoading(false);
            }
        }

        function showHomeView() {
            if (!homeView) return;
            homeView.classList.remove('hidden');
            if (bookingView) bookingView.classList.add('hidden');
            if (myBookingsView) myBookingsView.classList.add('hidden');
            if (profileView) profileView.classList.add('hidden');
            if (menuHome) menuHome.classList.add('active');
            if (menuBooking) menuBooking.classList.remove('active');
            if (menuMyBookings) menuMyBookings.classList.remove('active');
        }

        function showBookingView() {
            if (!bookingView || !homeView) return;
            homeView.classList.add('hidden');
            bookingView.classList.remove('hidden');
            if (myBookingsView) myBookingsView.classList.add('hidden');
            if (profileView) profileView.classList.add('hidden');
            if (menuHome) menuHome.classList.remove('active');
            if (menuBooking) menuBooking.classList.add('active');
            if (menuMyBookings) menuMyBookings.classList.remove('active');
            syncBookingCalendarStateFromDate();
            renderBookingCalendar();
            loadBookingSlots(false);
        }

        function showMyBookingsView() {
            if (!myBookingsView || !homeView) return;
            homeView.classList.add('hidden');
            if (bookingView) bookingView.classList.add('hidden');
            myBookingsView.classList.remove('hidden');
            if (profileView) profileView.classList.add('hidden');
            if (menuHome) menuHome.classList.remove('active');
            if (menuBooking) menuBooking.classList.remove('active');
            if (menuMyBookings) menuMyBookings.classList.add('active');
            if (myBookingsFrame && !myBookingsFrame.src) {
                myBookingsFrame.src = 'BookingController?action=listUser';
            }
        }

        function showProfileView() {
            if (!profileView || !homeView) return;
            homeView.classList.add('hidden');
            if (bookingView) bookingView.classList.add('hidden');
            if (myBookingsView) myBookingsView.classList.add('hidden');
            profileView.classList.remove('hidden');
            if (menuHome) menuHome.classList.remove('active');
            if (menuBooking) menuBooking.classList.remove('active');
            if (menuMyBookings) menuMyBookings.classList.remove('active');
        }

        if (menuHome && homeView) {
            menuHome.addEventListener('click', (e) => {
                e.preventDefault();
                showHomeView();
            });
        }

        if (menuBooking && bookingView) {
            menuBooking.addEventListener('click', (e) => {
                e.preventDefault();
                showBookingView();
            });
        }

        if (menuMyBookings && myBookingsView) {
            menuMyBookings.addEventListener('click', (e) => {
                e.preventDefault();
                showMyBookingsView();
            });
        }

        if (refreshMyBookingsBtn && myBookingsFrame) {
            refreshMyBookingsBtn.addEventListener('click', () => {
                const src = myBookingsFrame.src || 'BookingController?action=listUser';
                myBookingsFrame.src = src;
            });
        }

        if (openProfileBtn && profileView && homeView) {
            openProfileBtn.addEventListener('click', (e) => {
                e.preventDefault();
                showProfileView();
                if (userMenu) userMenu.classList.remove('open');
            });
        }

        if (bookingDate) {
            bookingDate.addEventListener('change', () => {
                syncBookingCalendarStateFromDate();
                renderBookingCalendar();
                loadBookingSlots(false);
            });
        }

        if (bookingPrevMonth) {
            bookingPrevMonth.addEventListener('click', () => {
                bookingCalendarMonth -= 1;
                if (bookingCalendarMonth < 0) {
                    bookingCalendarMonth = 11;
                    bookingCalendarYear -= 1;
                }
                renderBookingCalendar();
            });
        }

        if (bookingMonthSelect) {
            bookingMonthSelect.addEventListener('change', () => {
                bookingCalendarMonth = parseInt(bookingMonthSelect.value, 10);
                renderBookingCalendar();
            });
        }

        if (bookingYearSelect) {
            populateBookingYearOptions();
            bookingYearSelect.addEventListener('change', () => {
                bookingCalendarYear = parseInt(bookingYearSelect.value, 10);
                populateBookingMonthOptions();
                renderBookingCalendar();
            });
        }

        if (bookingTodayBtn) {
            bookingTodayBtn.addEventListener('click', () => {
                const now = new Date();
                bookingCalendarYear = now.getFullYear();
                bookingCalendarMonth = now.getMonth();
                if (bookingDate) {
                    bookingDate.value = toDateOnlyText(now);
                }
                renderBookingCalendar();
                loadBookingSlots(false);
            });
        }

        if (bookingNextMonth) {
            bookingNextMonth.addEventListener('click', () => {
                bookingCalendarMonth += 1;
                if (bookingCalendarMonth > 11) {
                    bookingCalendarMonth = 0;
                    bookingCalendarYear += 1;
                }

                const maxText = getMaxBookingDateText();
                const maxYear = parseInt(maxText.substring(0, 4), 10);
                const maxMonth = parseInt(maxText.substring(5, 7), 10) - 1;
                if (bookingCalendarYear > maxYear || (bookingCalendarYear === maxYear && bookingCalendarMonth > maxMonth)) {
                    bookingCalendarYear = maxYear;
                    bookingCalendarMonth = maxMonth;
                }

                renderBookingCalendar();
            });
        }

        if (bookingSubmitBtn) {
            bookingSubmitBtn.addEventListener('click', async () => {
                if (!selectedBookingTime || !bookingDate) {
                    setBookingMsg('Vui lòng chọn giờ khám.', true);
                    return;
                }

                const phoneRaw = bookingPhone ? (bookingPhone.value || '').trim() : '';
                const vnPhoneRegex = /^0\d{9}$/;
                if (!vnPhoneRegex.test(phoneRaw)) {
                    setBookingMsg('Vui lòng nhập số điện thoại hợp lệ (10 số, bắt đầu bằng 0).', true);
                    return;
                }

                bookingSubmitBtn.disabled = true;
                const body = new URLSearchParams();
                body.set('action', 'book');
                body.set('ajax', '1');
                body.set('date', bookingDate.value);
                body.set('duration', '60');
                body.set('startTime', selectedBookingTime);
                body.set('customerName', bookingName ? (bookingName.value || '').trim() : '');
                body.set('customerPhone', phoneRaw);
                body.set('csrfToken', bookingCsrf ? bookingCsrf.value : '');

                try {
                    const res = await fetch('BookingController', {
                        method: 'POST',
                        body,
                        headers: {
                            'Accept': 'application/json',
                            'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                            'X-Requested-With': 'XMLHttpRequest'
                        }
                    });
                    const raw = await res.text();
                    let data;
                    try {
                        data = JSON.parse(raw);
                    } catch (e) {
                        setBookingMsg('Không thể xử lý phản hồi từ máy chủ. Vui lòng thử lại.', true);
                        bookingSubmitBtn.disabled = false;
                        return;
                    }

                    if (!res.ok || !data.success) {
                        setBookingMsg(data.message || 'Không thể đặt lịch.', true);
                        bookingSubmitBtn.disabled = false;
                        return;
                    }

                    await loadActivityByDate(bookingDate.value);
                    await loadBookingSlots(true);
                    setBookingMsg((data.message || 'Đặt lịch thành công.') + ' Vào "Lịch khám của tôi" để kiểm tra ngay.', false);
                } catch (err) {
                    setBookingMsg('Không kết nối được máy chủ.', true);
                    bookingSubmitBtn.disabled = false;
                }
            });
        }

        if (avatarTrigger) {
            avatarTrigger.addEventListener('click', (e) => {
                e.preventDefault();
                avatarTrigger.classList.remove('tap');
                void avatarTrigger.offsetWidth;
                avatarTrigger.classList.add('tap');
                if (userMenu) {
                    userMenu.classList.toggle('open');
                } else {
                    showHomeView();
                }
            });
        }

        document.addEventListener('click', (e) => {
            if (!userMenu || !avatarTrigger) return;
            const clickedInsideMenu = userMenu.contains(e.target);
            const clickedAvatar = avatarTrigger.contains(e.target);
            if (!clickedInsideMenu && !clickedAvatar) {
                userMenu.classList.remove('open');
            }
        });

        if (initialView === 'profile' && profileView && homeView) {
            showProfileView();
        } else if (initialView === 'myBookings' && myBookingsView && homeView) {
            showMyBookingsView();
        } else if (initialView === 'booking' && bookingView && homeView) {
            showBookingView();
        }
    })();
</script>
</body>
</html>
