package dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import model.DoctorDuty;
import utils.DBUtils;

public class DoctorDutyDAO {

    private static final String FIND_DOCTOR_BY_NAME = "SELECT id FROM Doctor WHERE full_name = ?";
    private static final String INSERT_DOCTOR = "INSERT INTO Doctor (full_name, specialty, is_active) VALUES (?, ?, 1)";

    private static final String INSERT_DUTY = "INSERT INTO DoctorDuty (doctor_id, duty_date, shift_start, shift_end) VALUES (?, ?, ?, ?)";
    private static final String DELETE_DUTY = "DELETE FROM DoctorDuty WHERE id = ?";

    private static final String SELECT_DUTIES_BY_DATE =
            "SELECT dd.id, dd.doctor_id, d.full_name, dd.duty_date, dd.shift_start, dd.shift_end "
            + "FROM DoctorDuty dd JOIN Doctor d ON dd.doctor_id = d.id "
            + "WHERE dd.duty_date = ? "
            + "ORDER BY dd.shift_start ASC, d.full_name ASC";

    private static final String SELECT_DUTIES_BY_MONTH =
            "SELECT dd.id, dd.doctor_id, d.full_name, dd.duty_date, dd.shift_start, dd.shift_end "
            + "FROM DoctorDuty dd JOIN Doctor d ON dd.doctor_id = d.id "
            + "WHERE dd.duty_date >= ? AND dd.duty_date < ? "
            + "ORDER BY dd.duty_date ASC, dd.shift_start ASC, d.full_name ASC";

        private static final String SELECT_ALL_DOCTOR_NAMES =
            "SELECT full_name FROM Doctor WHERE is_active = 1 ORDER BY full_name ASC";

            private static final String COUNT_DUTY_BY_MONTH =
                "SELECT COUNT(1) AS total FROM DoctorDuty WHERE duty_date >= ? AND duty_date < ?";

            private static final String BULK_SEED_DUTY_BY_MONTH =
                "WITH DatePool AS ("
                + "    SELECT ? AS duty_date "
                + "    UNION ALL "
                + "    SELECT DATEADD(DAY, 1, duty_date) FROM DatePool WHERE duty_date < ?"
                + "), WorkDays AS ("
                + "    SELECT duty_date FROM DatePool "
                + "    WHERE ((DATEDIFF(DAY, '19000101', duty_date) + 1) % 7) NOT IN (0, 6)"
                + "), TopDoctors AS ("
                + "    SELECT TOP (?) d.id, ROW_NUMBER() OVER (ORDER BY d.id) AS rn "
                + "    FROM Doctor d WHERE d.is_active = 1 ORDER BY d.id"
                + "), ShiftTemplate AS ("
                + "    SELECT 1 AS shift_no, CAST('07:30' AS TIME(0)) AS shift_start, CAST('11:30' AS TIME(0)) AS shift_end "
                + "    UNION ALL SELECT 2, CAST('09:00' AS TIME(0)), CAST('12:00' AS TIME(0)) "
                + "    UNION ALL SELECT 3, CAST('13:00' AS TIME(0)), CAST('17:00' AS TIME(0)) "
                + "    UNION ALL SELECT 4, CAST('17:30' AS TIME(0)), CAST('20:00' AS TIME(0))"
                + "), DutyRows AS ("
                + "    SELECT w.duty_date, t.shift_start, t.shift_end, td.id AS doctor_id, "
                + "           ROW_NUMBER() OVER (PARTITION BY w.duty_date, t.shift_no ORDER BY td.rn) AS doctor_pick "
                + "    FROM WorkDays w "
                + "    CROSS JOIN ShiftTemplate t "
                + "    JOIN TopDoctors td ON td.rn BETWEEN ((DATEPART(DAY, w.duty_date) + t.shift_no - 2) % 20) + 1 "
                + "                                AND ((DATEPART(DAY, w.duty_date) + t.shift_no - 2) % 20) + 8"
                + ") "
                + "INSERT INTO DoctorDuty (doctor_id, duty_date, shift_start, shift_end) "
                + "SELECT dr.doctor_id, dr.duty_date, dr.shift_start, dr.shift_end "
                + "FROM DutyRows dr "
                + "WHERE dr.doctor_pick <= ? "
                + "  AND NOT EXISTS ("
                + "      SELECT 1 FROM DoctorDuty dd "
                + "      WHERE dd.doctor_id = dr.doctor_id "
                + "        AND dd.duty_date = dr.duty_date "
                + "        AND dd.shift_start = dr.shift_start "
                + "        AND dd.shift_end = dr.shift_end"
                + "  ) "
                + "OPTION (MAXRECURSION 1000)";

    private static final String COUNT_DUPLICATED_DUTY =
            "SELECT COUNT(1) AS total FROM DoctorDuty WHERE doctor_id = ? AND duty_date = ? AND shift_start = ? AND shift_end = ?";

    public List<DoctorDuty> findByDate(LocalDate date) throws SQLException {
        List<DoctorDuty> duties = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(SELECT_DUTIES_BY_DATE)) {
            stm.setDate(1, Date.valueOf(date));
            try (ResultSet rs = stm.executeQuery()) {
                while (rs.next()) {
                    duties.add(mapDuty(rs));
                }
            }
        }
        return duties;
    }

    public Map<LocalDate, List<DoctorDuty>> findByMonth(int year, int month) throws SQLException {
        Map<LocalDate, List<DoctorDuty>> result = new HashMap<>();
        YearMonth ym = YearMonth.of(year, month);
        LocalDate from = ym.atDay(1);
        LocalDate to = ym.plusMonths(1).atDay(1);

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(SELECT_DUTIES_BY_MONTH)) {
            stm.setDate(1, Date.valueOf(from));
            stm.setDate(2, Date.valueOf(to));
            try (ResultSet rs = stm.executeQuery()) {
                while (rs.next()) {
                    DoctorDuty duty = mapDuty(rs);
                    result.computeIfAbsent(duty.getDutyDate(), key -> new ArrayList<>()).add(duty);
                }
            }
        }
        return result;
    }

    public List<String> findAllDoctorNames() throws SQLException {
        List<String> names = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(SELECT_ALL_DOCTOR_NAMES);
             ResultSet rs = stm.executeQuery()) {
            while (rs.next()) {
                names.add(rs.getString("full_name"));
            }
        }
        return names;
    }

    public boolean createDuty(LocalDate dutyDate, String doctorName, String specialty, java.time.LocalTime shiftStart, java.time.LocalTime shiftEnd) throws SQLException {
        int doctorId = ensureDoctor(doctorName, specialty);
        if (isDuplicatedDuty(doctorId, dutyDate, shiftStart, shiftEnd)) {
            return false;
        }

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(INSERT_DUTY)) {
            stm.setInt(1, doctorId);
            stm.setDate(2, Date.valueOf(dutyDate));
            stm.setTime(3, Time.valueOf(shiftStart));
            stm.setTime(4, Time.valueOf(shiftEnd));
            return stm.executeUpdate() > 0;
        }
    }

    public boolean deleteDuty(int dutyId) throws SQLException {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(DELETE_DUTY)) {
            stm.setInt(1, dutyId);
            return stm.executeUpdate() > 0;
        }
    }

    public int countDutiesByMonth(int year, int month) throws SQLException {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate from = ym.atDay(1);
        LocalDate to = ym.plusMonths(1).atDay(1);

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(COUNT_DUTY_BY_MONTH)) {
            stm.setDate(1, Date.valueOf(from));
            stm.setDate(2, Date.valueOf(to));
            try (ResultSet rs = stm.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }
        return 0;
    }

    public void autoSeedDutyForMonth(int year, int month, int doctorsPerShift) throws SQLException {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate from = ym.atDay(1);
        LocalDate to = ym.atEndOfMonth();

        int safeDoctorsPerShift = Math.max(2, Math.min(doctorsPerShift, 8));

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(BULK_SEED_DUTY_BY_MONTH)) {
            stm.setDate(1, Date.valueOf(from));
            stm.setDate(2, Date.valueOf(to));
            stm.setInt(3, 40);
            stm.setInt(4, safeDoctorsPerShift);
            stm.executeUpdate();
        }
    }

    private int ensureDoctor(String doctorName, String specialty) throws SQLException {
        try (Connection conn = DBUtils.getConnection()) {
            try (PreparedStatement findStm = conn.prepareStatement(FIND_DOCTOR_BY_NAME)) {
                findStm.setString(1, doctorName);
                try (ResultSet rs = findStm.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("id");
                    }
                }
            }

            try (PreparedStatement insertStm = conn.prepareStatement(INSERT_DOCTOR, Statement.RETURN_GENERATED_KEYS)) {
                insertStm.setString(1, doctorName);
                insertStm.setString(2, specialty);
                insertStm.executeUpdate();
                try (ResultSet keys = insertStm.getGeneratedKeys()) {
                    if (keys.next()) {
                        return keys.getInt(1);
                    }
                }
            }
        }
        throw new SQLException("Không thể tạo bác sĩ mới.");
    }

    private boolean isDuplicatedDuty(int doctorId, LocalDate date, java.time.LocalTime shiftStart, java.time.LocalTime shiftEnd) throws SQLException {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement stm = conn.prepareStatement(COUNT_DUPLICATED_DUTY)) {
            stm.setInt(1, doctorId);
            stm.setDate(2, Date.valueOf(date));
            stm.setTime(3, Time.valueOf(shiftStart));
            stm.setTime(4, Time.valueOf(shiftEnd));
            try (ResultSet rs = stm.executeQuery()) {
                return rs.next() && rs.getInt("total") > 0;
            }
        }
    }

    private DoctorDuty mapDuty(ResultSet rs) throws SQLException {
        DoctorDuty duty = new DoctorDuty();
        duty.setId(rs.getInt("id"));
        duty.setDoctorId(rs.getInt("doctor_id"));
        duty.setDoctorName(rs.getString("full_name"));
        duty.setDutyDate(rs.getDate("duty_date").toLocalDate());
        duty.setShiftStart(rs.getTime("shift_start").toLocalTime());
        duty.setShiftEnd(rs.getTime("shift_end").toLocalTime());
        return duty;
    }
}
