/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import model.Booking;
import utils.DBUtils;

/**
 *
 * @author letha
 */
public class BookingDAO {

	private static final String INSERT_BOOKING = "INSERT INTO Booking (user_id, booking_date, start_time, end_time, status) VALUES (?, ?, ?, ?, ?)";
	private static final String OVERLAP_CHECK = "SELECT COUNT(1) AS total FROM Booking WHERE booking_date = ? AND status <> 'rejected' AND status <> 'cancelled' AND NOT (end_time <= ? OR start_time >= ?)";
	private static final String COUNT_ACTIVE_BY_DATE = "SELECT COUNT(1) AS total FROM Booking WHERE booking_date = ? AND status <> 'rejected' AND status <> 'cancelled'";
	private static final String SELECT_BY_USER = "SELECT id, user_id, booking_date, start_time, end_time, status FROM Booking WHERE user_id = ? ORDER BY booking_date DESC, start_time DESC";
	private static final String SELECT_BY_ID = "SELECT id, user_id, booking_date, start_time, end_time, status FROM Booking WHERE id = ?";
	private static final String SELECT_ACTIVE_BY_DATE = "SELECT id, user_id, booking_date, start_time, end_time, status FROM Booking WHERE booking_date = ? AND status <> 'rejected' AND status <> 'cancelled' ORDER BY start_time ASC";
	private static final String ADMIN_STATUS_SUMMARY = "SELECT b.status, COUNT(1) AS total FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE u.username NOT LIKE 'user_demo_%' GROUP BY b.status";
	private static final String SYSTEM_DAILY_STATUS_SUMMARY = "SELECT b.status, COUNT(1) AS total FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE b.booking_date = CAST(GETDATE() AS DATE) AND u.username NOT LIKE 'user_demo_%' GROUP BY b.status";
	private static final String USER_STATUS_SUMMARY = "SELECT status, COUNT(1) AS total FROM Booking WHERE user_id = ? GROUP BY status";
	private static final String TODAY_TOTAL = "SELECT COUNT(1) AS total FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE b.booking_date = CAST(GETDATE() AS DATE) AND u.username NOT LIKE 'user_demo_%'";

	public boolean create(Booking booking) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(INSERT_BOOKING)) {
			stm.setInt(1, booking.getUserId());
			stm.setDate(2, Date.valueOf(booking.getBookingDate()));
			stm.setTime(3, Time.valueOf(booking.getStartTime()));
			stm.setTime(4, Time.valueOf(booking.getEndTime()));
			stm.setString(5, booking.getStatus());
			return stm.executeUpdate() > 0;
		}
	}

	public boolean hasOverlap(LocalDate date, LocalTime startTime, LocalTime endTime) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(OVERLAP_CHECK)) {
			stm.setDate(1, Date.valueOf(date));
			stm.setTime(2, Time.valueOf(startTime));
			stm.setTime(3, Time.valueOf(endTime));
			try (ResultSet rs = stm.executeQuery()) {
				return rs.next() && rs.getInt("total") > 0;
			}
		}
	}

	public int countActiveByDate(LocalDate date) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(COUNT_ACTIVE_BY_DATE)) {
			stm.setDate(1, Date.valueOf(date));
			try (ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					return rs.getInt("total");
				}
			}
		}
		return 0;
	}

	public List<Booking> findByUser(int userId) throws SQLException {
		List<Booking> bookings = new ArrayList<>();
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(SELECT_BY_USER)) {
			stm.setInt(1, userId);
			try (ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					bookings.add(mapBooking(rs));
				}
			}
		}
		return bookings;
	}

	public Booking findById(int bookingId) throws SQLException {
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(SELECT_BY_ID)) {
			stm.setInt(1, bookingId);
			try (ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					return mapBooking(rs);
				}
			}
		}
		return null;
	}

	public List<Booking> findAll(String dateFilter, String statusFilter, String sortBy) throws SQLException {
		List<Booking> bookings = new ArrayList<>();
		StringBuilder sql = new StringBuilder(
				"SELECT b.id, b.user_id, b.booking_date, b.start_time, b.end_time, b.status, u.username "
				+ "FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE 1=1 AND u.username NOT LIKE 'user_demo_%'"
		);

		List<Object> params = new ArrayList<>();
		if (dateFilter != null && !dateFilter.isBlank()) {
			sql.append(" AND b.booking_date = ?");
			params.add(Date.valueOf(dateFilter));
		}
		if (statusFilter != null && !statusFilter.isBlank()) {
			sql.append(" AND b.status = ?");
			params.add(statusFilter);
		}

		if ("status".equalsIgnoreCase(sortBy)) {
			sql.append(" ORDER BY b.status ASC, b.booking_date DESC, b.start_time DESC");
		} else {
			sql.append(" ORDER BY b.booking_date DESC, b.start_time DESC");
		}

		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(sql.toString())) {
			for (int i = 0; i < params.size(); i++) {
				stm.setObject(i + 1, params.get(i));
			}
			try (ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					Booking booking = mapBooking(rs);
					booking.setUsername(rs.getString("username"));
					bookings.add(booking);
				}
			}
		}
		return bookings;
	}

	public boolean updateStatus(int bookingId, String status) throws SQLException {
		String sql = "UPDATE Booking SET status = ? WHERE id = ?";
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(sql)) {
			stm.setString(1, status);
			stm.setInt(2, bookingId);
			return stm.executeUpdate() > 0;
		}
	}

	public List<Booking> findActiveByDate(LocalDate date) throws SQLException {
		List<Booking> bookings = new ArrayList<>();
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(SELECT_ACTIVE_BY_DATE)) {
			stm.setDate(1, Date.valueOf(date));
			try (ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					bookings.add(mapBooking(rs));
				}
			}
		}
		return bookings;
	}

	public Map<String, Integer> getAdminStats() throws SQLException {
		Map<String, Integer> stats = defaultStats();

		try (Connection conn = DBUtils.getConnection()) {
			try (PreparedStatement stm = conn.prepareStatement(ADMIN_STATUS_SUMMARY); ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					stats.put(rs.getString("status"), rs.getInt("total"));
				}
			}

			try (PreparedStatement stm = conn.prepareStatement(TODAY_TOTAL); ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					stats.put("today", rs.getInt("total"));
				}
			}
		}

		return stats;
	}

	public Map<String, Integer> getUserStats(int userId) throws SQLException {
		Map<String, Integer> stats = defaultStats();
		try (Connection conn = DBUtils.getConnection(); PreparedStatement stm = conn.prepareStatement(USER_STATUS_SUMMARY)) {
			stm.setInt(1, userId);
			try (ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					stats.put(rs.getString("status"), rs.getInt("total"));
				}
			}
		}
		return stats;
	}

	public Map<String, Integer> getSystemDailyStats() throws SQLException {
		Map<String, Integer> stats = defaultStats();

		try (Connection conn = DBUtils.getConnection()) {
			try (PreparedStatement stm = conn.prepareStatement(SYSTEM_DAILY_STATUS_SUMMARY); ResultSet rs = stm.executeQuery()) {
				while (rs.next()) {
					stats.put(rs.getString("status"), rs.getInt("total"));
				}
			}

			try (PreparedStatement stm = conn.prepareStatement(TODAY_TOTAL); ResultSet rs = stm.executeQuery()) {
				if (rs.next()) {
					stats.put("today", rs.getInt("total"));
				}
			}
		}

		return stats;
	}

	public Map<String, Integer> getSystemStatsByDate(LocalDate date) throws SQLException {
		Map<String, Integer> stats = defaultStats();

		String summarySql = "SELECT b.status, COUNT(1) AS total FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE b.booking_date = ? AND u.username NOT LIKE 'user_demo_%' GROUP BY b.status";
		String totalSql = "SELECT COUNT(1) AS total FROM Booking b JOIN [User] u ON b.user_id = u.id WHERE b.booking_date = ? AND u.username NOT LIKE 'user_demo_%'";

		try (Connection conn = DBUtils.getConnection()) {
			try (PreparedStatement stm = conn.prepareStatement(summarySql)) {
				stm.setDate(1, Date.valueOf(date));
				try (ResultSet rs = stm.executeQuery()) {
					while (rs.next()) {
						stats.put(rs.getString("status"), rs.getInt("total"));
					}
				}
			}

			try (PreparedStatement stm = conn.prepareStatement(totalSql)) {
				stm.setDate(1, Date.valueOf(date));
				try (ResultSet rs = stm.executeQuery()) {
					if (rs.next()) {
						stats.put("today", rs.getInt("total"));
					}
				}
			}
		}

		return stats;
	}

	public Map<String, Integer> getUserStatsByDate(int userId, LocalDate date) throws SQLException {
		Map<String, Integer> stats = defaultStats();

		String summarySql = "SELECT status, COUNT(1) AS total FROM Booking WHERE user_id = ? AND booking_date = ? GROUP BY status";
		String totalSql = "SELECT COUNT(1) AS total FROM Booking WHERE user_id = ? AND booking_date = ?";

		try (Connection conn = DBUtils.getConnection()) {
			try (PreparedStatement stm = conn.prepareStatement(summarySql)) {
				stm.setInt(1, userId);
				stm.setDate(2, Date.valueOf(date));
				try (ResultSet rs = stm.executeQuery()) {
					while (rs.next()) {
						stats.put(rs.getString("status"), rs.getInt("total"));
					}
				}
			}

			try (PreparedStatement stm = conn.prepareStatement(totalSql)) {
				stm.setInt(1, userId);
				stm.setDate(2, Date.valueOf(date));
				try (ResultSet rs = stm.executeQuery()) {
					if (rs.next()) {
						stats.put("today", rs.getInt("total"));
					}
				}
			}
		}

		return stats;
	}

	private Map<String, Integer> defaultStats() {
		Map<String, Integer> stats = new HashMap<>();
		stats.put("pending", 0);
		stats.put("approved", 0);
		stats.put("rejected", 0);
		stats.put("cancelled", 0);
		stats.put("today", 0);
		return stats;
	}

	private Booking mapBooking(ResultSet rs) throws SQLException {
		Booking booking = new Booking();
		booking.setId(rs.getInt("id"));
		booking.setUserId(rs.getInt("user_id"));
		booking.setBookingDate(rs.getDate("booking_date").toLocalDate());
		booking.setStartTime(rs.getTime("start_time").toLocalTime());
		booking.setEndTime(rs.getTime("end_time").toLocalTime());
		booking.setStatus(rs.getString("status"));
		return booking;
	}
}
