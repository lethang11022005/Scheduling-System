package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import model.DoctorDuty;
import service.BookingService;

public class DashboardController extends HttpServlet {

    private final BookingService bookingService = new BookingService();
    private static final int MAX_VIEW_YEAR = 2030;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
            return;
        }
        if (session.getAttribute("csrfToken") == null) {
            session.setAttribute("csrfToken", UUID.randomUUID().toString());
        }
        int userId = (Integer) session.getAttribute("userId");

        LocalDate now = LocalDate.now();
        int viewYear = parseIntOrDefault(request.getParameter("year"), now.getYear());
        int viewMonth = parseIntOrDefault(request.getParameter("month"), now.getMonthValue());
        if (viewMonth < 1) {
            viewMonth = 1;
        } else if (viewMonth > 12) {
            viewMonth = 12;
        }
        if (viewYear > MAX_VIEW_YEAR) {
            viewYear = MAX_VIEW_YEAR;
            viewMonth = 12;
        }

        LocalDate statsDate = now;
        String statsDateText = request.getParameter("statsDate");
        if (statsDateText != null && !statsDateText.isBlank()) {
            try {
                statsDate = LocalDate.parse(statsDateText);
            } catch (DateTimeParseException ignored) {
                statsDate = now;
            }
        }

        request.setAttribute("view", request.getParameter("view"));
        request.setAttribute("statsDate", statsDate);
    request.setAttribute("viewYear", viewYear);
    request.setAttribute("viewMonth", viewMonth);
    request.setAttribute("maxViewYear", MAX_VIEW_YEAR);

        String ajax = request.getParameter("ajax");
        if ("stats".equalsIgnoreCase(ajax)) {
            response.setContentType("application/json;charset=UTF-8");
            response.setCharacterEncoding("UTF-8");
            try {
                Map<String, Integer> stats = bookingService.getUserStatsByDate(userId, statsDate);
                response.getWriter().write(toStatsJson(statsDate, stats));
            } catch (SQLException ex) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("{\"error\":\"Không thể tải thống kê\"}");
            }
            return;
        }

        try {
            Map<String, Integer> stats = bookingService.getUserStatsByDate(userId, statsDate);
            request.setAttribute("stats", stats);
            request.setAttribute("profileStats", bookingService.getUserStats(userId));

            Map<LocalDate, List<DoctorDuty>> dutyCalendar = bookingService.getDoctorDutiesByMonth(viewYear, viewMonth);
            request.setAttribute("dutyCalendar", dutyCalendar);
        } catch (SQLException ex) {
            request.setAttribute("error", "Không thể tải thống kê trang tổng quan: " + ex.getMessage());
        }

        request.getRequestDispatcher("dashboard.jsp").forward(request, response);
    }

    @Override
    public String getServletInfo() {
        return "Dashboard controller";
    }

    private String toStatsJson(LocalDate statsDate, Map<String, Integer> stats) {
        int pending = readStat(stats, "pending");
        int approved = readStat(stats, "approved");
        int rejected = readStat(stats, "rejected");
        int cancelled = readStat(stats, "cancelled");
        int total = readStat(stats, "today");

        return "{"
                + "\"date\":\"" + statsDate + "\"," 
                + "\"pending\":" + pending + ","
                + "\"approved\":" + approved + ","
                + "\"rejected\":" + rejected + ","
                + "\"cancelled\":" + cancelled + ","
                + "\"today\":" + total
                + "}";
    }

    private int readStat(Map<String, Integer> stats, String key) {
        if (stats == null) {
            return 0;
        }
        Integer value = stats.get(key);
        return value == null ? 0 : value;
    }

    private int parseIntOrDefault(String text, int defaultValue) {
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }
}
