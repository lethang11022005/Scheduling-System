<%@page import="java.time.LocalDate"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Locale"%>
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

    String error = request.getParameter("error") != null ? request.getParameter("error") : (String) request.getAttribute("error");
    String success = request.getParameter("success") != null ? request.getParameter("success") : (String) request.getAttribute("success");
    String selectedDate = request.getAttribute("selectedDate") == null ? LocalDate.now().toString() : String.valueOf(request.getAttribute("selectedDate"));
    String selectedDuration = request.getAttribute("selectedDuration") == null ? "60" : String.valueOf(request.getAttribute("selectedDuration"));
    List<String> slots = (List<String>) request.getAttribute("slots");
    List<String> unavailableSlots = (List<String>) request.getAttribute("unavailableSlots");

    DateTimeFormatter displayDate = DateTimeFormatter.ofPattern("EEEE, dd MMM yyyy", new Locale("vi", "VN"));
    String selectedDatePretty = LocalDate.parse(selectedDate).format(displayDate);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Đặt lịch khám bệnh</title>
    <style>
        :root {
            --blue: #2063d6;
            --blue-soft: #eaf1ff;
            --text: #1f2937;
            --muted: #667085;
            --line: #d9e2ef;
            --bg1: #c8def7;
            --bg2: #d8edf6;
            --danger: #b91c1c;
            --success: #15803d;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: "Segoe UI", sans-serif;
            color: var(--text);
            min-height: 100vh;
            padding: 24px;
            background: radial-gradient(circle at 2% 100%, #75a8f6 0, rgba(117,168,246,0) 45%), linear-gradient(120deg, var(--bg1), var(--bg2));
        }

        .layout {
            max-width: 1450px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
            align-items: start;
        }

        .panel {
            background: rgba(255, 255, 255, 0.86);
            border: 1px solid rgba(255, 255, 255, 0.9);
            border-radius: 20px;
            box-shadow: 0 18px 48px rgba(20, 55, 100, 0.15);
        }

        .scheduler {
            padding: 22px;
            display: block;
        }

        .confirm label {
            display: block;
            font-size: 13px;
            color: var(--muted);
            margin-bottom: 6px;
        }

        input,
        select,
        button {
            width: 100%;
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 10px 12px;
            font-size: 16px;
        }

        .btn {
            background: var(--blue);
            color: #fff;
            border: none;
            font-weight: 600;
            cursor: pointer;
        }

        .right {
            display: grid;
            grid-template-columns: 1fr 130px;
            gap: 12px;
            min-height: 500px;
        }

        .calendar-shell {
            padding-right: 8px;
        }

        .month-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 8px;
            margin-bottom: 12px;
        }

        .month-controls {
            display: flex;
            gap: 8px;
            align-items: center;
            flex: 1;
        }

        .month-select {
            border: 1px solid #dbe7ff;
            border-radius: 10px;
            background: #fff;
            color: #0f172a;
            font-size: 13px;
            font-weight: 600;
            padding: 7px 10px;
            min-width: 100px;
        }

        .month-today {
            border: 1px solid #c7d2fe;
            background: #eef2ff;
            color: #3730a3;
            border-radius: 10px;
            padding: 7px 11px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }

        .month-nav {
            border: 1px solid var(--line);
            border-radius: 10px;
            width: 36px;
            height: 36px;
            background: #f6f9ff;
            cursor: pointer;
        }

        .weekday,
        .dates {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 6px;
        }

        .dates {
            grid-template-rows: repeat(6, 42px);
            min-height: calc(42px * 6 + 6px * 5);
        }

        .weekday div {
            text-align: center;
            color: #475569;
            font-size: 10px;
            font-weight: 600;
            padding: 6px 0;
            border-radius: 8px;
            background: #eef4ff;
        }

        .day {
            border: 1px solid #dbeafe;
            background: #ffffff;
            border-radius: 10px;
            width: 100%;
            height: 42px;
            font-size: 14px;
            cursor: pointer;
            color: #334155;
            font-weight: 600;
            transition: all .15s ease;
        }

        .day:hover { background: #eff6ff; border-color: #93c5fd; }
        .day.active {
            background: var(--blue);
            border-color: var(--blue);
            color: #fff;
            font-weight: 700;
            box-shadow: 0 6px 16px rgba(37, 99, 235, 0.28);
        }
        .day.weekend {
            color: #dc2626;
            border-color: #fecaca;
            background: #fff5f5;
            font-weight: 700;
        }
        .day:disabled { opacity: .45; cursor: not-allowed; text-decoration: line-through; }
        .day.blank { visibility: hidden; }

        .slot-list {
            min-height: 500px;
            max-height: 500px;
            overflow-y: auto;
            border-left: 1px dashed var(--line);
            padding-left: 10px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .slot {
            border: 1px solid #7aa8ff;
            background: #f8fbff;
            color: #1f56cd;
            border-radius: 999px;
            font-size: 13px;
            font-weight: 600;
            text-align: center;
            padding: 6px 0;
            cursor: pointer;
        }

        .slot.selected {
            background: var(--blue);
            border-color: var(--blue);
            color: #fff;
        }

        .slot:disabled {
            opacity: 0.4;
            cursor: not-allowed;
            text-decoration: line-through;
        }

        .confirm {
            padding: 22px;
        }

        .confirm h2 {
            font-size: 34px;
            margin: 4px 0 12px;
        }

        .summary {
            border: 1px solid #c9daf8;
            border-radius: 14px;
            background: #ebf3ff;
            color: #2b5fd0;
            padding: 14px;
            margin-bottom: 12px;
            line-height: 1.45;
            font-size: 20px;
        }

        .notice { margin: 8px 0; font-size: 14px; }
        .notice.error { color: var(--danger); }
        .notice.success { color: var(--success); }

        .confirm input { margin-bottom: 8px; }

        @media (max-width: 1200px) {
            .layout { grid-template-columns: 1fr; }
            .right { grid-template-columns: 1fr; }
            .slot-list { border-left: none; padding-left: 0; max-height: none; }
        }
    </style>
</head>
<body>
<div class="layout">
    <section class="panel scheduler">
        <input type="hidden" id="selectedDateInput" value="<%= selectedDate %>">

        <div class="right">
            <div class="calendar-shell">
                <div class="month-bar">
                    <button type="button" class="month-nav" id="prevMonth" aria-label="Tháng trước">&#8249;</button>
                    <div class="month-controls">
                        <select id="monthSelect" class="month-select" aria-label="Chọn tháng"></select>
                        <select id="yearSelect" class="month-select" aria-label="Chọn năm"></select>
                        <button type="button" class="month-today" id="todayBtn">Hôm nay</button>
                    </div>
                    <button type="button" class="month-nav" id="nextMonth" aria-label="Tháng sau">&#8250;</button>
                </div>
                <div class="weekday">
                    <div>CN</div><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div>
                </div>
                <div class="dates" id="dateGrid"></div>
            </div>

            <div class="slot-list" id="slotList">
                <%
                    if (slots != null && !slots.isEmpty()) {
                        for (String slot : slots) {
                            boolean disabled = unavailableSlots != null && unavailableSlots.contains(slot);
                %>
                <button type="button" class="slot" data-time="<%= slot %>" <%= disabled ? "disabled" : "" %>><%= slot %></button>
                <%
                        }
                    }
                %>
                <div id="slotHint" style="font-size:12px;color:#64748b;text-align:center;">Chọn ngày để xem giờ trống mới nhất</div>
            </div>
        </div>
    </section>

    <aside class="panel confirm">
        <a href="BookingController?action=showForm" style="text-decoration:none;color:#2b5fd0;">&#8249; Quay lại</a>
        <h2>Xác nhận lịch khám</h2>

        <% if (error != null && !error.isBlank()) { %>
        <div class="notice error"><%= error %></div>
        <% } %>
        <% if (success != null && !success.isBlank()) { %>
        <div class="notice success"><%= success %></div>
        <% } %>
        <div class="notice" id="bookingNotice" style="display:none;"></div>

        <div class="summary">
            <div id="summaryDate"><%= selectedDatePretty %></div>
            <div id="summaryTime">Chọn một khung giờ</div>
            <div style="font-size:16px;margin-top:3px;">Múi giờ: Asia/Ho_Chi_Minh</div>
        </div>

        <form action="BookingController" method="post" id="bookForm">
            <input type="hidden" name="action" value="book">
            <input type="hidden" name="csrfToken" value="<%= session.getAttribute("csrfToken") %>">
            <input type="hidden" name="date" id="bookDate" value="<%= selectedDate %>">
            <input type="hidden" name="duration" id="bookDuration" value="<%= selectedDuration %>">
            <input type="hidden" name="startTime" id="bookStartTime" value="">

            <label>Họ và tên bệnh nhân</label>
            <input type="text" name="customerName" value="<%= session.getAttribute("username") %>" required>

            <label>Số điện thoại liên hệ</label>
            <input type="tel" name="customerPhone" placeholder="0xxxxxxxxx" inputmode="numeric" maxlength="10" pattern="0[0-9]{9}" title="Số điện thoại gồm 10 số, bắt đầu bằng 0" required>

            <button type="submit" class="btn" id="confirmBtn" style="margin-top:8px;" disabled>Xác nhận đặt lịch</button>
        </form>
    </aside>
</div>

<script>
    (function () {
        const selectedDateInput = document.getElementById('selectedDateInput');
        const bookDate = document.getElementById('bookDate');
        const monthSelect = document.getElementById('monthSelect');
        const yearSelect = document.getElementById('yearSelect');
        const todayBtn = document.getElementById('todayBtn');
        const dateGrid = document.getElementById('dateGrid');
        const bookDuration = document.getElementById('bookDuration');
        const slotList = document.getElementById('slotList');
        const bookForm = document.getElementById('bookForm');
        const bookingNotice = document.getElementById('bookingNotice');

        const summaryDate = document.getElementById('summaryDate');
        const summaryTime = document.getElementById('summaryTime');
        const bookStartTime = document.getElementById('bookStartTime');
        const confirmBtn = document.getElementById('confirmBtn');

        const now = new Date(selectedDateInput.value + 'T00:00:00');
        let viewYear = now.getFullYear();
        let viewMonth = now.getMonth();
        let selectedDay = now.getDate();

        const monthNames = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];

        function showNotice(message, isError) {
            if (!bookingNotice) return;
            if (!message) {
                bookingNotice.style.display = 'none';
                bookingNotice.textContent = '';
                bookingNotice.classList.remove('error', 'success');
                return;
            }
            bookingNotice.style.display = 'block';
            bookingNotice.textContent = message;
            bookingNotice.classList.remove('error', 'success');
            bookingNotice.classList.add(isError ? 'error' : 'success');
        }

        function fillMonthYear() {
            // Kept for backward compatibility of initialization flow.
        }

        function toYMD(y, m, d) {
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

        function setActiveDay(dateText) {
            if (!dateGrid) return;
            dateGrid.querySelectorAll('.day.active').forEach((el) => el.classList.remove('active'));
            const dayButton = dateGrid.querySelector('.day[data-date="' + dateText + '"]');
            if (dayButton) {
                dayButton.classList.add('active');
            }
        }

        function populateYearOptions() {
            if (!yearSelect) return;
            const now = new Date();
            const max = new Date(getMaxBookingDateText() + 'T00:00:00');
            const startYear = now.getFullYear();
            const endYear = max.getFullYear();
            const options = [];
            for (let y = startYear; y <= endYear; y++) {
                options.push('<option value="' + y + '">' + y + '</option>');
            }
            yearSelect.innerHTML = options.join('');
        }

        function getRangeParts() {
            const now = new Date();
            const max = new Date(getMaxBookingDateText() + 'T00:00:00');
            return {
                minYear: now.getFullYear(),
                minMonth: now.getMonth(),
                maxYear: max.getFullYear(),
                maxMonth: max.getMonth()
            };
        }

        function populateMonthOptions() {
            if (!monthSelect) return;
            const range = getRangeParts();
            const labels = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
            const startMonth = viewYear === range.minYear ? range.minMonth : 0;
            const endMonth = viewYear === range.maxYear ? range.maxMonth : 11;
            const options = [];
            for (let m = startMonth; m <= endMonth; m++) {
                options.push('<option value="' + m + '">' + labels[m] + '</option>');
            }
            monthSelect.innerHTML = options.join('');

            if (viewMonth < startMonth || viewMonth > endMonth) {
                viewMonth = startMonth;
            }
        }

        function clampCalendarRange() {
            const maxText = getMaxBookingDateText();
            const maxYear = parseInt(maxText.substring(0, 4), 10);
            const maxMonth = parseInt(maxText.substring(5, 7), 10) - 1;
            if (viewYear > maxYear || (viewYear === maxYear && viewMonth > maxMonth)) {
                viewYear = maxYear;
                viewMonth = maxMonth;
            }
            const now = new Date();
            if (viewYear < now.getFullYear()) {
                viewYear = now.getFullYear();
                viewMonth = now.getMonth();
            }
        }

        function syncMonthYearSelectors() {
            if (monthSelect) monthSelect.value = String(viewMonth);
            if (yearSelect) yearSelect.value = String(viewYear);
        }

        function formatPretty(y, m, d) {
            const dt = new Date(y, m, d);
            return dt.toLocaleDateString('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' });
        }

        function clearSlotSelection() {
            bookStartTime.value = '';
            summaryTime.textContent = 'Chọn một khung giờ';
            confirmBtn.disabled = true;
        }

        function renderSlotButtons(slots, unavailableSlots) {
            const unavailable = new Set(unavailableSlots || []);
            const html = (slots || []).map((slot) => {
                const disabled = unavailable.has(slot) ? 'disabled' : '';
                return '<button type="button" class="slot" data-time="' + slot + '" ' + disabled + '>' + slot + '</button>';
            }).join('');

            slotList.innerHTML = html + '<div id="slotHint" style="font-size:12px;color:#64748b;text-align:center;">Khung giờ đã được cập nhật theo ngày và thời lượng hiện tại</div>';
            const availableButtons = slotList.querySelectorAll('.slot:not([disabled])');
            availableButtons.forEach((btn) => {
                btn.addEventListener('click', function () {
                    availableButtons.forEach((b) => b.classList.remove('selected'));
                    this.classList.add('selected');
                    bookStartTime.value = this.dataset.time;
                    summaryTime.textContent = this.dataset.time;
                    confirmBtn.disabled = false;
                });
            });

            clearSlotSelection();
        }

        async function loadSlots() {
            const date = selectedDateInput.value;
            const duration = bookDuration.value || '60';
            bookDuration.value = duration;
            clearSlotSelection();
            showNotice('', false);

            const dt = new Date(date + 'T00:00:00');
            if (!Number.isNaN(dt.getTime()) && (dt.getDay() === 0 || dt.getDay() === 6)) {
                renderSlotButtons([], []);
                showNotice('Thứ 7 và Chủ nhật là ngày nghỉ, không nhận đặt lịch.', true);
                return;
            }

            try {
                const res = await fetch('BookingController?action=slots&date=' + encodeURIComponent(date) + '&duration=' + encodeURIComponent(duration), {
                    headers: { 'Accept': 'application/json' }
                });
                const data = await res.json();
                if (!res.ok || !data.success) {
                    showNotice(data.message || 'Không thể tải khung giờ trống.', true);
                    return;
                }
                renderSlotButtons(data.slots, data.unavailableSlots);
            } catch (err) {
                showNotice('Không thể tải khung giờ trống.', true);
            }
        }

        function renderCalendar() {
            clampCalendarRange();
            populateMonthOptions();
            syncMonthYearSelectors();

            const first = new Date(viewYear, viewMonth, 1);
            const offset = first.getDay();
            const days = new Date(viewYear, viewMonth + 1, 0).getDate();
            const todayText = toDateOnlyText(new Date());
            const maxBookingDateText = getMaxBookingDateText();

            if (selectedDateInput.value > maxBookingDateText) {
                selectedDateInput.value = maxBookingDateText;
                bookDate.value = maxBookingDateText;
                const selectedDt = new Date(maxBookingDateText + 'T00:00:00');
                viewYear = selectedDt.getFullYear();
                viewMonth = selectedDt.getMonth();
                selectedDay = selectedDt.getDate();
            }

            const nodes = [];
            for (let i = 0; i < offset; i++) {
                nodes.push('<button type="button" class="day blank">.</button>');
            }
            for (let d = 1; d <= days; d++) {
                const dateText = toYMD(viewYear, viewMonth, d);
                const active = dateText === selectedDateInput.value ? 'active' : '';
                const jsDay = new Date(viewYear, viewMonth, d).getDay();
                const isWeekend = (jsDay === 0 || jsDay === 6);
                const weekendClass = isWeekend ? 'weekend' : '';
                const disabled = (dateText < todayText || dateText > maxBookingDateText || isWeekend) ? 'disabled' : '';
                nodes.push('<button type="button" class="day ' + active + ' ' + weekendClass + '" data-day="' + d + '" data-date="' + dateText + '" ' + disabled + '>' + d + '</button>');
            }

            dateGrid.innerHTML = nodes.join('');

            dateGrid.querySelectorAll('.day[data-day]:not([disabled])').forEach((btn) => {
                btn.addEventListener('click', function () {
                    selectedDay = Number(this.getAttribute('data-day'));
                    selectedDateInput.value = toYMD(viewYear, viewMonth, selectedDay);
                    bookDate.value = selectedDateInput.value;
                    summaryDate.textContent = formatPretty(viewYear, viewMonth, selectedDay);
                    setActiveDay(selectedDateInput.value);
                    loadSlots();
                });
            });
        }

        fillMonthYear();
        if (monthSelect) {
            monthSelect.addEventListener('change', () => {
                viewMonth = parseInt(monthSelect.value, 10);
                renderCalendar();
            });
        }
        if (yearSelect) {
            populateYearOptions();
            yearSelect.addEventListener('change', () => {
                viewYear = parseInt(yearSelect.value, 10);
                populateMonthOptions();
                renderCalendar();
            });
        }
        if (todayBtn) {
            todayBtn.addEventListener('click', () => {
                const now = new Date();
                viewYear = now.getFullYear();
                viewMonth = now.getMonth();
                selectedDay = now.getDate();
                selectedDateInput.value = toDateOnlyText(now);
                bookDate.value = selectedDateInput.value;
                summaryDate.textContent = formatPretty(viewYear, viewMonth, selectedDay);
                renderCalendar();
                loadSlots();
            });
        }
        renderCalendar();

        document.getElementById('prevMonth').addEventListener('click', function () {
            viewMonth -= 1;
            if (viewMonth < 0) {
                viewMonth = 11;
                viewYear -= 1;
            }
            renderCalendar();
        });

        document.getElementById('nextMonth').addEventListener('click', function () {
            viewMonth += 1;
            if (viewMonth > 11) {
                viewMonth = 0;
                viewYear += 1;
            }

            const maxText = getMaxBookingDateText();
            const maxYear = parseInt(maxText.substring(0, 4), 10);
            const maxMonth = parseInt(maxText.substring(5, 7), 10) - 1;
            if (viewYear > maxYear || (viewYear === maxYear && viewMonth > maxMonth)) {
                viewYear = maxYear;
                viewMonth = maxMonth;
            }

            renderCalendar();
        });

        const initialSlotButtons = document.querySelectorAll('#slotList .slot:not([disabled])');
        initialSlotButtons.forEach((btn) => {
            btn.addEventListener('click', function () {
                initialSlotButtons.forEach((b) => b.classList.remove('selected'));
                this.classList.add('selected');
                bookStartTime.value = this.dataset.time;
                summaryTime.textContent = this.dataset.time;
                confirmBtn.disabled = false;
            });
        });

        bookForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            if (!bookStartTime.value) {
                showNotice('Vui lòng chọn khung giờ trước khi xác nhận.', true);
                return;
            }

            const phoneInput = bookForm.querySelector('input[name="customerPhone"]');
            const phoneText = phoneInput ? (phoneInput.value || '').trim() : '';
            const vnPhoneRegex = /^0\d{9}$/;
            if (!vnPhoneRegex.test(phoneText)) {
                showNotice('Vui lòng nhập số điện thoại hợp lệ (10 số, bắt đầu bằng 0).', true);
                return;
            }

            confirmBtn.disabled = true;
            const originalText = confirmBtn.textContent;
            confirmBtn.textContent = 'Đang gửi...';
            showNotice('', false);

            try {
                const formData = new URLSearchParams();
                formData.set('action', 'book');
                formData.set('ajax', '1');
                formData.set('csrfToken', bookForm.querySelector('input[name="csrfToken"]')?.value || '');
                formData.set('date', bookDate.value || '');
                formData.set('duration', bookDuration.value || '60');
                formData.set('startTime', bookStartTime.value || '');
                formData.set('customerName', bookForm.querySelector('input[name="customerName"]')?.value || '');
                formData.set('customerPhone', phoneText);
                const res = await fetch('BookingController', {
                    method: 'POST',
                    body: formData,
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
                } catch (parseErr) {
                    showNotice('Không thể xử lý phản hồi từ máy chủ. Vui lòng thử lại.', true);
                    confirmBtn.disabled = false;
                    confirmBtn.textContent = originalText;
                    return;
                }
                if (!res.ok || !data.success) {
                    showNotice(data.message || 'Không thể đặt lịch khám.', true);
                    confirmBtn.disabled = false;
                    confirmBtn.textContent = originalText;
                    return;
                }

                showNotice(data.message || 'Đặt lịch khám thành công.', false);
                clearSlotSelection();
                await loadSlots();
            } catch (err) {
                showNotice('Không thể kết nối máy chủ. Vui lòng thử lại.', true);
                confirmBtn.disabled = false;
            } finally {
                confirmBtn.textContent = originalText;
            }
        });
    })();
</script>
</body>
</html>
