package top.kariscode.karisreview.auth.util;

import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalTime;
import java.util.UUID;

/**
 * 用户刷新点解析（架构评审候选 4，2026-08）。
 *
 * 兜底 04:00 此前在 DeckService/StatsService/ReviewService/CardService
 * 复制 4 份，统一收口到此处。"今天"的定义（DateUtils.calculateToday）
 * 依赖此刷新点，勿各自兜底。
 */
public final class UserRefreshTime {

    /** 默认刷新点：04:00（无配置用户）。 */
    public static final LocalTime DEFAULT_REFRESH_TIME = LocalTime.of(4, 0);

    private UserRefreshTime() {
    }

    public static LocalTime resolve(UserRepository userRepository, UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(DEFAULT_REFRESH_TIME);
    }
}
