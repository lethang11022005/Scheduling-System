/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */

package controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.DoctorDuty;
import service.BookingService;

/**
 *
 * @author letha
 */
public class AdminController extends HttpServlet {
    private static final int PAGE_SIZE = 10;
    private final BookingService bookingService = new BookingService();

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /** 
     * Handles the HTTP <code>GET</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        String action = request.getParameter("action");
        if (action == null || action.isBlank()) {
            action = "listAll";
        }

        if ("listAll".equalsIgnoreCase(action)) {
            listAllBookings(request, response);
            return;
        }

        if ("deleteDuty".equalsIgnoreCase(action)) {
            response.sendRedirect(buildListAllUrl(request, "", "", "Xóa lịch trực phải dùng phương thức POST."));
            return;
        }

        response.sendRedirect("AdminController?action=listAll");
    } 

    /** 
     * Handles the HTTP <code>POST</code> method.
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        if (!isAdmin(request, response)) {
            return;
        }

        String action = request.getParameter("action");
        if ("addDuty".equalsIgnoreCase(action) || "deleteDuty".equalsIgnoreCase(action)) {
            if (!isValidCsrf(request, request.getSession(false))) {
                response.sendRedirect("AdminController?action=listAll&error="
                        + encodeQueryParam("Phiên làm việc không hợp lệ. Vui lòng thử lại."));
                return;
            }
            handleDoctorDutyAction(request, response, action);
            return;
        }

        if ("approve".equalsIgnoreCase(action) || "reject".equalsIgnoreCase(action)) {
            if (!isValidCsrf(request, request.getSession(false))) {
                response.sendRedirect("AdminController?action=listAll&error="
                        + encodeQueryParam("Phiên làm việc không hợp lệ. Vui lòng thử lại."));
                return;
            }
            updateStatus(request, response, action);
            return;
        }

        response.sendRedirect("AdminController?action=listAll");
    }

    private boolean isAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
            return false;
        }

        String role = String.valueOf(session.getAttribute("role"));
        if (!"admin".equalsIgnoreCase(role)) {
            response.sendRedirect("BookingController?action=showForm&error=Bạn không có quyền truy cập");
            return false;
        }
        if (session.getAttribute("csrfToken") == null) {
            session.setAttribute("csrfToken", UUID.randomUUID().toString());
        }
        return true;
    }

    private void listAllBookings(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String dateFilter = normalizeDateFilter(request.getParameter("date"));
        String statusFilter = normalizeStatusFilter(request.getParameter("status"));
        String sort = normalizeSort(request.getParameter("sort"));
        int page = parseIntOrDefault(request.getParameter("page"), 1);
        String dutyDate = normalizeDateFilter(request.getParameter("dutyDate"));
        if (dutyDate.isBlank()) {
            dutyDate = LocalDate.now().toString();
        }

        try {
            Map<String, Object> data = bookingService.getAdminBookings(dateFilter, statusFilter, sort, page, PAGE_SIZE);
            List<DoctorDuty> duties = bookingService.getDoctorDutiesByDate(dutyDate);
            List<String> doctorNames = bookingService.getAllDoctorNames();
            Map<String, Integer> stats = dateFilter.isBlank()
                    ? bookingService.getAdminStats()
                    : bookingService.getSystemStatsByDate(LocalDate.parse(dateFilter));
            request.setAttribute("bookings", data.get("bookings"));
            request.setAttribute("currentPage", data.get("currentPage"));
            request.setAttribute("totalPages", data.get("totalPages"));
            request.setAttribute("totalRecords", data.get("totalRecords"));
            request.setAttribute("stats", stats);
            request.setAttribute("duties", duties);
            request.setAttribute("doctorNames", doctorNames);
            request.setAttribute("dutyDate", dutyDate);
            request.setAttribute("date", dateFilter);
            request.setAttribute("status", statusFilter);
            request.setAttribute("sort", sort);
            request.getRequestDispatcher("admin.jsp").forward(request, response);
        } catch (SQLException ex) {
            request.setAttribute("error", "Không thể tải danh sách lịch khám quản trị: " + ex.getMessage());
            request.getRequestDispatcher("admin.jsp").forward(request, response);
        }
    }

    private void updateStatus(HttpServletRequest request, HttpServletResponse response, String action) throws IOException {
        int bookingId = parseIntOrDefault(request.getParameter("bookingId"), -1);
        String newStatus = "approve".equalsIgnoreCase(action) ? BookingService.STATUS_APPROVED : BookingService.STATUS_REJECTED;
        String message;

        try {
            boolean updated = bookingService.updateStatus(bookingId, newStatus);
            message = updated ? "Cập nhật trạng thái thành công" : "Không thể cập nhật trạng thái lịch khám";
        } catch (SQLException ex) {
            message = "Cập nhật thất bại: " + ex.getMessage();
        }

        String date = encodeQueryParam(safeParam(request.getParameter("date")));
        String status = encodeQueryParam(safeParam(request.getParameter("status")));
        String sort = encodeQueryParam(safeParam(request.getParameter("sort")));
        String page = encodeQueryParam(safeParam(request.getParameter("page")));
        String dutyDate = encodeQueryParam(safeParam(request.getParameter("dutyDate")));
        String success = encodeQueryParam(message);
        response.sendRedirect("AdminController?action=listAll&date=" + date + "&status=" + status + "&sort=" + sort + "&page=" + page + "&dutyDate=" + dutyDate + "&success=" + success);
    }

    private void handleDoctorDutyAction(HttpServletRequest request, HttpServletResponse response, String action) throws IOException {
        if ("addDuty".equalsIgnoreCase(action)) {
            try {
                Map<String, Object> result = bookingService.createDoctorDuty(
                        request.getParameter("dutyDate"),
                        request.getParameter("doctorName"),
                        request.getParameter("specialty"),
                        request.getParameter("shiftStart"),
                        request.getParameter("shiftEnd")
                );

                boolean success = Boolean.TRUE.equals(result.get("success"));
                String msg = String.valueOf(result.get("message"));
                response.sendRedirect(buildListAllUrl(request, success ? msg : "", success ? "" : msg, ""));
                return;
            } catch (Exception ex) {
                response.sendRedirect(buildListAllUrl(request, "", "Lỗi khi lưu lịch trực: " + ex.getMessage(), ""));
                return;
            }
        }

        int dutyId = parseIntOrDefault(request.getParameter("dutyId"), -1);
        if (dutyId <= 0) {
            response.sendRedirect(buildListAllUrl(request, "", "Mã lịch trực không hợp lệ.", ""));
            return;
        }

        try {
            boolean deleted = bookingService.deleteDoctorDuty(dutyId);
            response.sendRedirect(buildListAllUrl(request, deleted ? "Xóa lịch trực thành công." : "", deleted ? "" : "Không thể xóa lịch trực.", ""));
        } catch (Exception ex) {
            response.sendRedirect(buildListAllUrl(request, "", "Lỗi khi xóa lịch trực: " + ex.getMessage(), ""));
        }
    }

    private String buildListAllUrl(HttpServletRequest request, String successMsg, String errorMsg, String fallbackError) {
        String date = encodeQueryParam(safeParam(request.getParameter("date")));
        String status = encodeQueryParam(safeParam(request.getParameter("status")));
        String sort = encodeQueryParam(safeParam(request.getParameter("sort")));
        String page = encodeQueryParam(safeParam(request.getParameter("page")));
        String dutyDate = encodeQueryParam(safeParam(request.getParameter("dutyDate")));

        if (dutyDate.isBlank()) {
            dutyDate = encodeQueryParam(LocalDate.now().toString());
        }

        StringBuilder url = new StringBuilder("AdminController?action=listAll&date=")
                .append(date)
                .append("&status=").append(status)
                .append("&sort=").append(sort)
                .append("&page=").append(page)
                .append("&dutyDate=").append(dutyDate);

        if (successMsg != null && !successMsg.isBlank()) {
            url.append("&success=").append(encodeQueryParam(successMsg));
        } else if (errorMsg != null && !errorMsg.isBlank()) {
            url.append("&error=").append(encodeQueryParam(errorMsg));
        } else if (fallbackError != null && !fallbackError.isBlank()) {
            url.append("&error=").append(encodeQueryParam(fallbackError));
        }
        return url.toString();
    }

    private int parseIntOrDefault(String value, int defaultValue) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    private String safeParam(String value) {
        return value == null ? "" : value;
    }

    private String encodeQueryParam(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private boolean isValidCsrf(HttpServletRequest request, HttpSession session) {
        if (session == null) {
            return false;
        }
        String sessionToken = (String) session.getAttribute("csrfToken");
        String requestToken = request.getParameter("csrfToken");
        return sessionToken != null && sessionToken.equals(requestToken);
    }

    private String normalizeStatusFilter(String status) {
        if (status == null || status.isBlank()) {
            return "";
        }
        switch (status) {
            case BookingService.STATUS_PENDING:
            case BookingService.STATUS_APPROVED:
            case BookingService.STATUS_REJECTED:
            case BookingService.STATUS_CANCELLED:
                return status;
            default:
                return "";
        }
    }

    private String normalizeSort(String sort) {
        return "status".equalsIgnoreCase(sort) ? "status" : "date";
    }

    private String normalizeDateFilter(String date) {
        if (date == null || date.isBlank()) {
            return "";
        }
        try {
            java.time.LocalDate.parse(date);
            return date;
        } catch (java.time.format.DateTimeParseException ex) {
            return "";
        }
    }

    /** 
     * Returns a short description of the servlet.
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
