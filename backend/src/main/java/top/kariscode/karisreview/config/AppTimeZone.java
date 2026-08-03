package top.kariscode.karisreview.config;

import java.time.ZoneId;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public final class AppTimeZone {

    private static volatile ZoneId zone = ZoneId.of("Asia/Shanghai");

    public AppTimeZone(@Value("${app.timezone:Asia/Shanghai}") String timezone) {
        zone = ZoneId.of(timezone);
    }

    public static ZoneId get() {
        return zone;
    }
}
