package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import service.BookingService;

public class UserBookingController extends HttpServlet {

    private final BookingService bookingService = new BookingService();
    private static final int USER_PAGE_SIZE = 8;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
            return;
        }

        if ("admin".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("AdminController?action=listAll");
            return;
        }

        String action = request.getParameter("action");
        if (action == null || action.isBlank()) {
            action = "showForm";
        }

        if ("slots".equalsIgnoreCase(action)) {
            loadSlotsAjax(request, response);
            return;
        }

        switch (action) {
            case "listUser":
                showUserBookings(request, response, session);
                break;
            case "showForm":
            default:
                showBookingForm(request, response, session);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        boolean ajaxRequest = isAjaxRequest(request);
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            if (ajaxRequest) {
                writeJson(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "{\"success\":false,\"message\":\"Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.\"}");
                return;
            }
            response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
            return;
        }

        String action = request.getParameter("action");
        if ("book".equalsIgnoreCase(action)) {
            if (!isValidCsrf(request, session)) {
                if (ajaxRequest) {
                    writeJson(response, HttpServletResponse.SC_FORBIDDEN, "{\"success\":false,\"message\":\"Phiên làm việc không hợp lệ. Vui lòng thử lại.\"}");
                    return;
                }
                response.sendRedirect("BookingController?action=showForm&error="
                        + URLEncoder.encode("Phiên làm việc không hợp lệ. Vui lòng thử lại.", StandardCharsets.UTF_8));
                return;
            }
            if (ajaxRequest) {
                createBookingAjax(request, response, session);
                return;
            }
            createBooking(request, response, session);
            return;
        }

        if ("cancel".equalsIgnoreCase(action)) {
            if (!isValidCsrf(request, session)) {
                response.sendRedirect("BookingController?action=listUser&error="
                        + URLEncoder.encode("Phiên làm việc không hợp lệ. Vui lòng thử lại.", StandardCharsets.UTF_8));
                return;
            }
            cancelBooking(request, response, session);
            return;
        }

        response.sendRedirect("BookingController?action=showForm");
    }

    private void showBookingForm(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws ServletException, IOException {
        String selectedDate = request.getParameter("date");
        if (selectedDate == null || selectedDate.isBlank()) {
            selectedDate = LocalDate.now().toString();
        }
        String duration = request.getParameter("duration");
        if (duration == null || duration.isBlank()) {
            duration = "60";
        }

        ensureCsrfToken(session);

        request.setAttribute("selectedDate", selectedDate);
        request.setAttribute("selectedDuration", duration);
        request.setAttribute("slots", bookingService.generateSlots());
        try {
            request.setAttribute("unavailableSlots", bookingService.getUnavailableSlots(selectedDate, duration));
            request.setAttribute("stats", bookingService.getUserStats((Integer) session.getAttribute("userId")));
        } catch (SQLException ex) {
            request.setAttribute("unavailableSlots", java.util.Collections.emptyList());
            request.setAttribute("error", "Không thể tải dữ liệu lịch khám lúc này: " + ex.getMessage());
        }
        request.getRequestDispatcher("booking.jsp").forward(request, response);
    }

    private void loadSlotsAjax(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String selectedDate = request.getParameter("date");
        if (selectedDate == null || selectedDate.isBlank()) {
            selectedDate = LocalDate.now().toString();
        }

        String duration = request.getParameter("duration");
        if (duration == null || duration.isBlank()) {
            duration = "60";
        }

        try {
            LocalDate.parse(selectedDate);
        } catch (DateTimeParseException ex) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST,
                    "{\"success\":false,\"message\":\"Ngày khám không hợp lệ\"}");
            return;
        }

        try {
            List<String> slots = bookingService.generateSlots();
            List<String> unavailable = bookingService.getUnavailableSlots(selectedDate, duration);
            StringBuilder json = new StringBuilder();
            json.append("{\"success\":true,\"date\":\"").append(selectedDate)
                    .append("\",\"duration\":\"").append(duration)
                    .append("\",\"slots\":").append(toJsonArray(slots))
                    .append(",\"unavailableSlots\":").append(toJsonArray(unavailable))
                    .append("}");
            writeJson(response, HttpServletResponse.SC_OK, json.toString());
        } catch (SQLException ex) {
            writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "{\"success\":false,\"message\":\"Không thể tải khung giờ trống\"}");
        }
    }

    private void createBookingAjax(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {
        int userId = (Integer) session.getAttribute("userId");
        String date = request.getParameter("date");
        String startTime = request.getParameter("startTime");
        String duration = request.getParameter("duration");

        try {
            Map<String, Object> result = bookingService.createBooking(userId, date, startTime, duration);
            boolean success = Boolean.TRUE.equals(result.get("success"));
            String message = escapeJson(String.valueOf(result.get("message")));
            String json = "{\"success\":" + success + ",\"message\":\"" + message + "\"}";
            writeJson(response, success ? HttpServletResponse.SC_OK : HttpServletResponse.SC_BAD_REQUEST, json);
        } catch (SQLException ex) {
            writeJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "{\"success\":false,\"message\":\"Không thể tạo lịch khám lúc này\"}");
        } catch (Exception ex) {
            writeJson(response, HttpServletResponse.SC_BAD_REQUEST,
                    "{\"success\":false,\"message\":\"Dữ liệu đặt lịch không hợp lệ.\"}");
        }
    }

    private void createBooking(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws ServletException, IOException {
        int userId = (Integer) session.getAttribute("userId");
        String date = request.getParameter("date");
        String startTime = request.getParameter("startTime");
        String duration = request.getParameter("duration");

        try {
            Map<String, Object> result = bookingService.createBooking(userId, date, startTime, duration);
            if (Boolean.TRUE.equals(result.get("success"))) {
                response.sendRedirect("BookingController?action=showForm&date="
                        + encode(date) + "&duration=" + encode(duration)
                        + "&success=" + encode(String.valueOf(result.get("message"))));
                return;
            } else {
                request.setAttribute("error", result.get("message"));
            }
            request.setAttribute("selectedDate", date);
            request.setAttribute("selectedDuration", duration);
            request.setAttribute("slots", bookingService.generateSlots());
            request.setAttribute("unavailableSlots", bookingService.getUnavailableSlots(date, duration));
            request.setAttribute("stats", bookingService.getUserStats(userId));
            request.getRequestDispatcher("booking.jsp").forward(request, response);
        } catch (Exception ex) {
            request.setAttribute("error", "Không thể tạo lịch khám: " + ex.getMessage());
            request.getRequestDispatcher("booking.jsp").forward(request, response);
        }
    }

    private void showUserBookings(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws ServletException, IOException {
        int userId = (Integer) session.getAttribute("userId");
        int page = parseIntOrDefault(request.getParameter("page"), 1);
        try {
            Map<String, Object> data = bookingService.getUserBookings(userId, page, USER_PAGE_SIZE);
            request.setAttribute("bookings", data.get("bookings"));
            request.setAttribute("currentPage", data.get("currentPage"));
            request.setAttribute("totalPages", data.get("totalPages"));
            request.setAttribute("totalRecords", data.get("totalRecords"));
            request.setAttribute("stats", bookingService.getUserStats(userId));
            ensureCsrfToken(session);
            request.getRequestDispatcher("listBooking.jsp").forward(request, response);
        } catch (Exception ex) {
            request.setAttribute("error", "Không thể tải danh sách lịch khám: " + ex.getMessage());
            request.getRequestDispatcher("listBooking.jsp").forward(request, response);
        }
    }

    private void ensureCsrfToken(HttpSession session) {
        if (session.getAttribute("csrfToken") == null) {
            session.setAttribute("csrfToken", UUID.randomUUID().toString());
        }
    }

    private boolean isValidCsrf(HttpServletRequest request, HttpSession session) {
        String sessionToken = (String) session.getAttribute("csrfToken");
        String requestToken = request.getParameter("csrfToken");
        return sessionToken != null && sessionToken.equals(requestToken);
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        if ("1".equals(request.getParameter("ajax"))) {
            return true;
        }
        String accept = request.getHeader("Accept");
        if (accept != null && accept.toLowerCase().contains("application/json")) {
            return true;
        }
        String requestedWith = request.getHeader("X-Requested-With");
        return requestedWith != null && "XMLHttpRequest".equalsIgnoreCase(requestedWith);
    }

    private int parseIntOrDefault(String value, int defaultValue) {
        try {
            return Integer.parseInt(value);
        } catch (Exception ex) {
            return defaultValue;
        }
    }

    private String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private void writeJson(HttpServletResponse response, int status, String json) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json);
    }

    private String toJsonArray(List<String> values) {
        List<String> safe = values == null ? Collections.emptyList() : values;
        StringBuilder builder = new StringBuilder("[");
        for (int i = 0; i < safe.size(); i++) {
            if (i > 0) {
                builder.append(',');
            }
            builder.append('"').append(escapeJson(safe.get(i))).append('"');
        }
        builder.append(']');
        return builder.toString();
    }

    private String escapeJson(String text) {
        if (text == null) {
            return "";
        }
        return text
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "\\n");
    }

    private void cancelBooking(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {
        int userId = (Integer) session.getAttribute("userId");
        String bookingIdText = request.getParameter("bookingId");

        try {
            int bookingId = Integer.parseInt(bookingIdText);
            boolean cancelled = bookingService.cancelBooking(bookingId, userId);
            if (cancelled) {
                response.sendRedirect("BookingController?action=listUser&success="
                        + URLEncoder.encode("Hủy lịch khám thành công", StandardCharsets.UTF_8));
            } else {
                response.sendRedirect("BookingController?action=listUser&error="
                        + URLEncoder.encode("Không thể hủy lịch khám này", StandardCharsets.UTF_8));
            }
        } catch (NumberFormatException | SQLException ex) {
            response.sendRedirect("BookingController?action=listUser&error="
                    + URLEncoder.encode("Mã lịch khám không hợp lệ", StandardCharsets.UTF_8));
        }
    }

    @Override
    public String getServletInfo() {
        return "User booking controller";
    }
}
