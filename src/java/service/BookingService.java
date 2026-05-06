/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package service;

import dao.BookingDAO;
import dao.DoctorDutyDAO;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import model.Booking;
import model.DoctorDuty;
import validator.BookingValidator;

/**
 *
 * @author letha
 */
public class BookingService {

	public static final String STATUS_PENDING = "pending";
	public static final String STATUS_APPROVED = "approved";
	public static final String STATUS_REJECTED = "rejected";
	public static final String STATUS_CANCELLED = "cancelled";

	private static final LocalTime OPEN_TIME = LocalTime.of(8, 0);
	private static final LocalTime CLOSE_TIME = LocalTime.of(18, 0);
	private static final LocalTime LAST_BOOKABLE_START = LocalTime.of(17, 0);
	private static final int SLOT_STEP_MINUTES = 30;

	private final BookingDAO bookingDAO;
	private final DoctorDutyDAO doctorDutyDAO;
	private final BookingValidator bookingValidator;

	public BookingService() {
		this.bookingDAO = new BookingDAO();
		this.doctorDutyDAO = new DoctorDutyDAO();
		this.bookingValidator = new BookingValidator();
	}

	public Map<String, Object> createBooking(int userId, String dateText, String startTimeText, String durationText) throws SQLException {
		Map<String, Object> result = new HashMap<>();

		List<String> errors = bookingValidator.validateBookingInput(dateText, startTimeText, durationText);
		if (!errors.isEmpty()) {
			result.put("success", false);
			result.put("message", String.join(" ", errors));
			return result;
		}

		LocalDate bookingDate = LocalDate.parse(dateText);
		LocalTime startTime = LocalTime.parse(startTimeText);
		int durationMinutes = Integer.parseInt(durationText);
		LocalTime endTime = startTime.plusMinutes(durationMinutes);

		if (bookingDate.getDayOfWeek() == DayOfWeek.SATURDAY || bookingDate.getDayOfWeek() == DayOfWeek.SUNDAY) {
			result.put("success", false);
			result.put("message", "Ngày nghỉ (Thứ 7, Chủ nhật) không nhận đặt lịch.");
			return result;
		}

		if (bookingDate.isAfter(getMaxBookingDate())) {
			result.put("success", false);
			result.put("message", "Chỉ được đặt lịch đến hết tháng 4.");
			return result;
		}

		if (startTime.isBefore(OPEN_TIME) || endTime.isAfter(CLOSE_TIME) || !endTime.isAfter(startTime)) {
			result.put("success", false);
			result.put("message", "Khung giờ khám phải nằm trong khoảng 08:00 - 18:00 và giờ kết thúc phải sau giờ bắt đầu.");
			return result;
		}

		if (!generateSlots().contains(startTime.toString())) {
			result.put("success", false);
			result.put("message", "Khung giờ bắt đầu không hợp lệ. Vui lòng chọn giờ từ danh sách cho phép.");
			return result;
		}

		Booking booking = new Booking();
		booking.setUserId(userId);
		booking.setBookingDate(bookingDate);
		booking.setStartTime(startTime);
		booking.setEndTime(endTime);
		booking.setStatus(STATUS_PENDING);

		boolean created = bookingDAO.create(booking);
		result.put("success", created);
		result.put("message", created ? "Đặt lịch khám thành công. Trạng thái: chờ duyệt." : "Không thể tạo lịch khám.");
		return result;
	}

	public List<Booking> getBookingsByUser(int userId) throws SQLException {
		return bookingDAO.findByUser(userId);
	}

	public Map<String, Object> getUserBookings(int userId, int page, int pageSize) throws SQLException {
		List<Booking> allBookings = bookingDAO.findByUser(userId);
		int totalRecords = allBookings.size();
		int totalPages = (int) Math.ceil(totalRecords / (double) pageSize);
		int safeTotalPages = Math.max(totalPages, 1);
		int safePage = Math.max(1, Math.min(page, safeTotalPages));

		int fromIndex = (safePage - 1) * pageSize;
		int toIndex = Math.min(fromIndex + pageSize, totalRecords);
		List<Booking> pageData = fromIndex >= toIndex ? Collections.emptyList() : allBookings.subList(fromIndex, toIndex);

		Map<String, Object> result = new HashMap<>();
		result.put("bookings", pageData);
		result.put("currentPage", safePage);
		result.put("totalPages", safeTotalPages);
		result.put("totalRecords", totalRecords);
		return result;
	}

	public Map<String, Object> getAdminBookings(String dateFilter, String statusFilter, String sortBy, int page, int pageSize) throws SQLException {
		List<Booking> allBookings = bookingDAO.findAll(dateFilter, statusFilter, sortBy);
		int totalRecords = allBookings.size();
		int totalPages = (int) Math.ceil(totalRecords / (double) pageSize);
		int safeTotalPages = Math.max(totalPages, 1);
		int safePage = Math.max(1, Math.min(page, safeTotalPages));

		int fromIndex = (safePage - 1) * pageSize;
		int toIndex = Math.min(fromIndex + pageSize, totalRecords);
		List<Booking> pageData = fromIndex >= toIndex ? Collections.emptyList() : allBookings.subList(fromIndex, toIndex);

		Map<String, Object> result = new HashMap<>();
		result.put("bookings", pageData);
		result.put("currentPage", safePage);
		result.put("totalPages", safeTotalPages);
		result.put("totalRecords", totalRecords);
		return result;
	}

	public boolean updateStatus(int bookingId, String status) throws SQLException {
		if (!STATUS_APPROVED.equals(status) && !STATUS_REJECTED.equals(status)) {
			return false;
		}
		Booking booking = bookingDAO.findById(bookingId);
		if (booking == null || STATUS_CANCELLED.equals(booking.getStatus())) {
			return false;
		}
		return bookingDAO.updateStatus(bookingId, status);
	}

	public boolean cancelBooking(int bookingId, int userId) throws SQLException {
		Booking booking = bookingDAO.findById(bookingId);
		if (booking == null || booking.getUserId() != userId) {
			return false;
		}

		if (STATUS_CANCELLED.equals(booking.getStatus())
				|| STATUS_REJECTED.equals(booking.getStatus())
				|| STATUS_APPROVED.equals(booking.getStatus())) {
			return false;
		}

		LocalDate today = LocalDate.now();
		LocalTime now = LocalTime.now();
		if (booking.getBookingDate().isBefore(today)
				|| (booking.getBookingDate().isEqual(today) && !booking.getStartTime().isAfter(now))) {
			return false;
		}

		return bookingDAO.updateStatus(bookingId, STATUS_CANCELLED);
	}

	public List<String> generateSlots() {
		List<String> slots = new ArrayList<>();
		LocalTime pointer = OPEN_TIME;
		while (!pointer.isAfter(LAST_BOOKABLE_START)) {
			slots.add(pointer.toString());
			pointer = pointer.plusMinutes(SLOT_STEP_MINUTES);
		}
		return slots;
	}

	public List<String> getUnavailableSlots(String dateText, String durationText) throws SQLException {
		if (dateText == null || dateText.isBlank() || durationText == null || durationText.isBlank()) {
			return Collections.emptyList();
		}

		int duration;
		try {
			LocalDate.parse(dateText);
			duration = Integer.parseInt(durationText);
		} catch (DateTimeParseException | NumberFormatException ex) {
			return Collections.emptyList();
		}

		LocalDate date = LocalDate.parse(dateText);
		LocalDate today = LocalDate.now();
		if (date.isBefore(today)
				|| date.isAfter(getMaxBookingDate())
				|| date.getDayOfWeek() == DayOfWeek.SATURDAY
				|| date.getDayOfWeek() == DayOfWeek.SUNDAY) {
			return generateSlots();
		}

		List<String> blockedSlots = new ArrayList<>();
		for (String slot : generateSlots()) {
			LocalTime start = LocalTime.parse(slot);
			LocalTime end = start.plusMinutes(duration);
			if (end.isAfter(CLOSE_TIME)) {
				blockedSlots.add(slot);
			}
		}
		return blockedSlots;
	}

	private LocalDate getMaxBookingDate() {
		LocalDate today = LocalDate.now();
		return LocalDate.of(today.getYear(), 4, 30);
	}

	public Map<String, Integer> getAdminStats() throws SQLException {
		return bookingDAO.getAdminStats();
	}

	public Map<String, Integer> getUserStats(int userId) throws SQLException {
		return bookingDAO.getUserStats(userId);
	}

	public Map<String, Integer> getSystemDailyStats() throws SQLException {
		return bookingDAO.getSystemDailyStats();
	}

	public Map<String, Integer> getSystemStatsByDate(LocalDate date) throws SQLException {
		return bookingDAO.getSystemStatsByDate(date);
	}

	public Map<String, Integer> getUserStatsByDate(int userId, LocalDate date) throws SQLException {
		return bookingDAO.getUserStatsByDate(userId, date);
	}

	public List<DoctorDuty> getDoctorDutiesByDate(String dateText) throws SQLException {
		LocalDate date = parseDateOrToday(dateText);
		return doctorDutyDAO.findByDate(date);
	}

	public Map<LocalDate, List<DoctorDuty>> getDoctorDutiesByMonth(int year, int month) throws SQLException {
		return doctorDutyDAO.findByMonth(year, month);
	}

	public List<String> getAllDoctorNames() throws SQLException {
		return doctorDutyDAO.findAllDoctorNames();
	}

	public void ensureDemoDutyForMonth(int year, int month) throws SQLException {
		doctorDutyDAO.autoSeedDutyForMonth(year, month, 6);
	}

	public Map<String, Object> createDoctorDuty(String dutyDateText, String doctorName, String specialty, String shiftStartText, String shiftEndText) throws SQLException {
		Map<String, Object> result = new HashMap<>();

		if (doctorName == null || doctorName.isBlank()) {
			result.put("success", false);
			result.put("message", "Vui lòng nhập tên bác sĩ.");
			return result;
		}

		LocalDate dutyDate;
		LocalTime shiftStart;
		LocalTime shiftEnd;

		try {
			dutyDate = LocalDate.parse(dutyDateText);
			shiftStart = LocalTime.parse(shiftStartText);
			shiftEnd = LocalTime.parse(shiftEndText);
		} catch (Exception ex) {
			result.put("success", false);
			result.put("message", "Dữ liệu ngày hoặc giờ trực không hợp lệ.");
			return result;
		}

		if (!shiftEnd.isAfter(shiftStart)) {
			result.put("success", false);
			result.put("message", "Giờ kết thúc ca trực phải sau giờ bắt đầu.");
			return result;
		}

		if (dutyDate.getDayOfWeek() == DayOfWeek.SATURDAY || dutyDate.getDayOfWeek() == DayOfWeek.SUNDAY) {
			result.put("success", false);
			result.put("message", "Chỉ được tạo lịch trực từ thứ 2 đến thứ 6.");
			return result;
		}

		boolean created = doctorDutyDAO.createDuty(dutyDate, doctorName.trim(), specialty == null ? null : specialty.trim(), shiftStart, shiftEnd);
		result.put("success", created);
		result.put("message", created ? "Thêm lịch trực bác sĩ thành công." : "Ca trực này đã tồn tại, vui lòng kiểm tra lại.");
		return result;
	}

	public boolean deleteDoctorDuty(int dutyId) throws SQLException {
		return doctorDutyDAO.deleteDuty(dutyId);
	}

	private LocalDate parseDateOrToday(String dateText) {
		if (dateText == null || dateText.isBlank()) {
			return LocalDate.now();
		}
		try {
			return LocalDate.parse(dateText);
		} catch (DateTimeParseException ex) {
			return LocalDate.now();
		}
	}
}
