package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import service.UserService;

public class ProfileController extends HttpServlet {

    private final UserService userService = new UserService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp?error=Vui lòng đăng nhập trước");
            return;
        }

        String sessionToken = (String) session.getAttribute("csrfToken");
        String requestToken = request.getParameter("csrfToken");
        if (sessionToken == null || !sessionToken.equals(requestToken)) {
            response.sendRedirect("DashboardController?view=profile&error="
                    + URLEncoder.encode("Phiên làm việc không hợp lệ. Vui lòng thử lại.", StandardCharsets.UTF_8));
            return;
        }

        int userId = (Integer) session.getAttribute("userId");
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        try {
            Map<String, Object> result = userService.changePassword(userId, currentPassword, newPassword, confirmPassword);
            boolean success = Boolean.TRUE.equals(result.get("success"));
            String message = String.valueOf(result.get("message"));

            response.sendRedirect("DashboardController?view=profile&" + (success ? "success=" : "error=")
                    + URLEncoder.encode(message, StandardCharsets.UTF_8));
        } catch (Exception ex) {
            response.sendRedirect("DashboardController?view=profile&error="
                    + URLEncoder.encode("Lỗi khi đổi mật khẩu: " + ex.getMessage(), StandardCharsets.UTF_8));
        }
    }

    @Override
    public String getServletInfo() {
        return "Profile controller";
    }
}
