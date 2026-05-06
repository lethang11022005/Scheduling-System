/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import model.User;
import utils.DBUtils;

/**
 *
 * @author letha
 */
public class UserDAO {

	private static final String FIND_BY_USERNAME = "SELECT id, username, password, role FROM [User] WHERE username = ?";
	private static final String FIND_BY_ID = "SELECT id, username, password, role FROM [User] WHERE id = ?";
	private static final String FIND_LEGACY_USERS = "SELECT id, username, password, role FROM [User] WHERE [password] NOT LIKE 'pbkdf2$%'";
	private static final String UPDATE_PASSWORD_BY_ID = "UPDATE [User] SET [password] = ? WHERE id = ?";
	private static final String UPDATE_PASSWORD_IF_CURRENT = "UPDATE [User] SET [password] = ? WHERE id = ? AND [password] = ?";

	public User findByUsername(String username) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(FIND_BY_USERNAME)) {
			stm.setString(1, username);

			try (ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					return mapUser(rs);
				}
			}
		}
		return null;
	}

	public User findById(int userId) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(FIND_BY_ID)) {
			stm.setInt(1, userId);
			try (ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					return mapUser(rs);
				}
			}
		}
		return null;
	}

	public java.util.List<User> findLegacyPasswordUsers() throws SQLException {
		java.util.List<User> users = new java.util.ArrayList<>();
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(FIND_LEGACY_USERS); ResultSet rs = stm.executeQuery()) {
			while (rs.next()) {
				users.add(mapUser(rs));
			}
		}
		return users;
	}

	public boolean updatePasswordById(int userId, String newPassword) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(UPDATE_PASSWORD_BY_ID)) {
			stm.setString(1, newPassword);
			stm.setInt(2, userId);
			return stm.executeUpdate() > 0;
		}
	}

	public boolean updatePasswordIfCurrent(int userId, String currentPassword, String newPassword) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(UPDATE_PASSWORD_IF_CURRENT)) {
			stm.setString(1, newPassword);
			stm.setInt(2, userId);
			stm.setString(3, currentPassword);
			return stm.executeUpdate() > 0;
		}
	}

	private User mapUser(ResultSet rs) throws SQLException {
		return new User(
				rs.getInt("id"),
				rs.getString("username"),
				rs.getString("password"),
				rs.getString("role")
		);
	}
}
