package validator;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

public class BookingValidator {

    public List<String> validateBookingInput(String dateText, String timeText, String durationText) {
        List<String> errors = new ArrayList<>();

        if (dateText == null || dateText.isBlank()) {
            errors.add("Vui lòng chọn ngày khám.");
            return errors;
        }
        if (timeText == null || timeText.isBlank()) {
            errors.add("Vui lòng chọn giờ bắt đầu.");
            return errors;
        }

        LocalDate bookingDate;
        LocalTime startTime;
        int durationMinutes;

        try {
            bookingDate = LocalDate.parse(dateText);
        } catch (DateTimeParseException ex) {
            errors.add("Định dạng ngày khám không hợp lệ.");
            return errors;
        }

        try {
            startTime = LocalTime.parse(timeText);
        } catch (DateTimeParseException ex) {
            errors.add("Định dạng giờ khám không hợp lệ.");
            return errors;
        }

        try {
            durationMinutes = Integer.parseInt(durationText);
        } catch (NumberFormatException ex) {
            errors.add("Thời lượng khám không hợp lệ.");
            return errors;
        }

        if (durationMinutes <= 0) {
            errors.add("Thời lượng khám phải lớn hơn 0 phút.");
        }

        LocalDate today = LocalDate.now();
        if (bookingDate.isBefore(today)) {
            errors.add("Ngày khám phải từ hôm nay trở đi.");
        }

        if (bookingDate.getDayOfWeek() == DayOfWeek.SATURDAY || bookingDate.getDayOfWeek() == DayOfWeek.SUNDAY) {
            errors.add("Ngày nghỉ (Thứ 7, Chủ nhật) không nhận đặt lịch.");
        }

        LocalDate maxBookingDate = LocalDate.of(today.getYear(), 4, 30);
        if (bookingDate.isAfter(maxBookingDate)) {
            errors.add("Chỉ được đặt lịch đến hết tháng 4.");
        }

        if (bookingDate.isEqual(today) && startTime.isBefore(LocalTime.now().withSecond(0).withNano(0))) {
            errors.add("Không thể đặt giờ khám trong quá khứ.");
        }

        return errors;
    }
}
