/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package service;

import dao.UserDAO;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import model.User;
import utils.PasswordUtils;

/**
 *
 * @author letha
 */
public class UserService {

	private final UserDAO userDAO;
	private static volatile boolean legacyPasswordsMigrated = false;

	public UserService() {
		this.userDAO = new UserDAO();
	}

	public User login(String username, String password) throws SQLException {
		if (username == null || username.isBlank() || password == null || password.isBlank()) {
			return null;
		}

		migrateLegacyPasswordsIfNeeded();

		User user = userDAO.findByUsername(username.trim());
		if (user == null || user.getPassword() == null) {
			return null;
		}

		String inputPassword = password.trim();
		String storedPassword = user.getPassword();

		if (PasswordUtils.isHashedPassword(storedPassword)) {
			return PasswordUtils.verifyPassword(inputPassword, storedPassword) ? user : null;
		}

		if (!storedPassword.equals(inputPassword)) {
			return null;
		}

		String newHash = PasswordUtils.hashPassword(inputPassword);
		userDAO.updatePasswordIfCurrent(user.getId(), storedPassword, newHash);
		user.setPassword(newHash);
		return user;
	}

	public Map<String, Object> changePassword(int userId, String currentPassword, String newPassword, String confirmPassword) throws SQLException {
		Map<String, Object> result = new HashMap<>();

		String current = currentPassword == null ? null : currentPassword.trim();
		String next = newPassword == null ? null : newPassword.trim();
		String confirm = confirmPassword == null ? null : confirmPassword.trim();

		if (current == null || current.isBlank()) {
			result.put("success", false);
			result.put("message", "Vui lòng nhập mật khẩu hiện tại.");
			return result;
		}

		if (next == null || next.isBlank()) {
			result.put("success", false);
			result.put("message", "Vui lòng nhập mật khẩu mới.");
			return result;
		}

		if (next.length() < 6) {
			result.put("success", false);
			result.put("message", "Mật khẩu mới phải có ít nhất 6 ký tự.");
			return result;
		}

		if (!next.equals(confirm)) {
			result.put("success", false);
			result.put("message", "Xác nhận mật khẩu mới không khớp.");
			return result;
		}

		User user = userDAO.findById(userId);
		if (user == null || user.getPassword() == null) {
			result.put("success", false);
			result.put("message", "Không tìm thấy người dùng.");
			return result;
		}

		String storedPassword = user.getPassword();
		boolean currentPasswordMatched = matchesPassword(current, storedPassword);

		if (!currentPasswordMatched) {
			result.put("success", false);
			result.put("message", "Mật khẩu hiện tại không đúng.");
			return result;
		}

		if (matchesPassword(next, storedPassword) || next.equals(current)) {
			result.put("success", false);
			result.put("message", "Mật khẩu mới phải khác mật khẩu hiện tại.");
			return result;
		}

		String newHash = PasswordUtils.hashPassword(next);
		boolean updated = userDAO.updatePasswordById(userId, newHash);
		result.put("success", updated);
		result.put("message", updated ? "Đổi mật khẩu thành công." : "Đổi mật khẩu thất bại. Vui lòng thử lại.");
		return result;
	}

	private boolean matchesPassword(String rawPassword, String storedPassword) {
		if (rawPassword == null || storedPassword == null) {
			return false;
		}
		if (PasswordUtils.isHashedPassword(storedPassword)) {
			return PasswordUtils.verifyPassword(rawPassword, storedPassword);
		}
		return storedPassword.equals(rawPassword);
	}

	private void migrateLegacyPasswordsIfNeeded() throws SQLException {
		if (legacyPasswordsMigrated) {
			return;
		}

		synchronized (UserService.class) {
			if (legacyPasswordsMigrated) {
				return;
			}

			for (User legacyUser : userDAO.findLegacyPasswordUsers()) {
				String raw = legacyUser.getPassword();
				if (raw == null || raw.isBlank() || PasswordUtils.isHashedPassword(raw)) {
					continue;
				}
				userDAO.updatePasswordById(legacyUser.getId(), PasswordUtils.hashPassword(raw));
			}

			legacyPasswordsMigrated = true;
		}
	}
}
