package top.kariscode.karisreview.stats.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.stats.dto.TrendStatsResponse;
import top.kariscode.karisreview.stats.entity.DailyReviewStats;
import top.kariscode.karisreview.stats.repository.DailyReviewStatsRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * 每日复习统计预聚合服务（阶段一 WP-5 / 阶段二 Analytics 事件驱动基础）。
 *
 * <p>职责：
 * <ul>
 *   <li><b>增量</b>：消费 {@code REVIEW_LOGGED} Outbox 事件，对 (user × 业务日 × deck) 计数 +1；</li>
 *   <li><b>全量兜底</b>：每日 04:30 从 review_logs 重算最近 N 天（幂等，修复增量漂移）；</li>
 *   <li><b>查询</b>：趋势数据从预聚合表读取，与 review_logs 数据量解耦。</li>
 * </ul>
 *
 * <p>口径与实时查询一致：reviewed = 非新卡评分；learned = 新卡 FAMILIAR；
 * 业务日按用户 refresh_time 计算（{@link DateUtils#calculateToday(LocalTime, LocalDateTime)}）。
 */
@Service
public class DailyReviewStatsService {

    private static final Logger log = LoggerFactory.getLogger(DailyReviewStatsService.class);

    /** 全量重算回溯天数：覆盖最长间隔（Stage 8 = 180 天）再加余量。 */
    private static final int REBUILD_LOOKBACK_DAYS = 400;

    private final DailyReviewStatsRepository statsRepository;
    private final IdentityPort identityPort;

    public DailyReviewStatsService(DailyReviewStatsRepository statsRepository,
                                   IdentityPort identityPort) {
        this.statsRepository = statsRepository;
        this.identityPort = identityPort;
    }

    /**
     * 事件驱动增量更新：由 REVIEW_LOGGED 事件处理器调用。
     */
    @Transactional
    public void incrementFromEvent(UUID userId, UUID deckId, LocalDateTime reviewedAt,
                                   boolean newCard, String rating) {
        LocalTime refreshTime = refreshTimeOf(userId);
        LocalDate statDate = DateUtils.calculateToday(refreshTime, reviewedAt);

        int reviewedInc = newCard ? 0 : 1;
        int learnedInc = (newCard && "FAMILIAR".equals(rating)) ? 1 : 0;
        int uniqueInc = 1;

        if (deckId != null) {
            statsRepository.upsertIncrement(userId, statDate, deckId, reviewedInc, learnedInc, uniqueInc);
        }
        statsRepository.upsertIncrementAll(userId, statDate, reviewedInc, learnedInc, uniqueInc);
    }

    /**
     * 按用户重算最近 {@link #REBUILD_LOOKBACK_DAYS} 个业务日（幂等）。
     */
    @Transactional
    public int rebuildUser(UUID userId) {
        LocalTime refreshTime = refreshTimeOf(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);
        int rebuilt = 0;
        for (int i = REBUILD_LOOKBACK_DAYS - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            LocalDateTime start = date.atTime(refreshTime);
            LocalDateTime end = date.plusDays(1).atTime(refreshTime);
            statsRepository.deleteForDay(userId, date, null);
            statsRepository.rebuildFromLogs(userId, date, start, end);
            statsRepository.rebuildAllFromLogs(userId, date, start, end);
            rebuilt++;
        }
        return rebuilt;
    }

    /**
     * 每日全量重算任务：为所有用户重算（04:30，与备份 04:10 错开）。
     * 数据量大时可拆分为按用户分批（分页游标），当前规模直接全量。
     */
    @Scheduled(cron = "0 30 4 * * *")
    public void rebuildAllDaily() {
        List<UUID> userIds = identityPort.findAllUserIds();
        log.info("Daily review stats rebuild started for {} users", userIds.size());
        int rebuilt = 0;
        for (UUID userId : userIds) {
            try {
                rebuilt += rebuildUser(userId);
            } catch (Exception e) {
                log.error("Daily stats rebuild failed for user {}", userId, e);
            }
        }
        log.info("Daily review stats rebuild finished ({} user-days)", rebuilt);
    }

    /**
     * 趋势查询：读取预聚合表，补齐缺失日期为 0。
     * 若该用户完全没有预聚合数据（如刚部署未触发重算），返回空列表由调用方回退实时查询。
     */
    @Transactional(readOnly = true)
    public List<TrendStatsResponse> getTrend(UUID userId, LocalTime refreshTime, int days) {
        LocalDate today = DateUtils.calculateToday(refreshTime);
        LocalDate startDate = today.minusDays(days - 1L);

        List<DailyReviewStats> rows =
                statsRepository.findByUserIdAndStatDateBetweenOrderByStatDateAsc(userId, startDate, today);

        Map<LocalDate, TrendStatsResponse> map = new LinkedHashMap<>();
        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            map.put(date, new TrendStatsResponse(date, 0, 0));
        }
        boolean hasAllRow = false;
        for (DailyReviewStats row : rows) {
            if (row.getDeckId() == null) {
                hasAllRow = true;
                TrendStatsResponse t = map.get(row.getStatDate());
                if (t != null) {
                    t.setReviewed(t.getReviewed() + row.getReviewedCount());
                    t.setLearned(t.getLearned() + row.getLearnedCount());
                }
            }
        }
        if (!hasAllRow) {
            // 无预聚合数据（含只有卡组行、无全量行的情况，理论上不会发生）：回退信号
            return List.of();
        }
        return new ArrayList<>(map.values());
    }

    /** 今日概览：从预聚合读今日 reviewed/learned（避免实时扫描 review_logs）。 */
    @Transactional(readOnly = true)
    public Optional<int[]> getTodayCounts(UUID userId, LocalTime refreshTime) {
        LocalDate today = DateUtils.calculateToday(refreshTime);
        Optional<DailyReviewStats> allRow = statsRepository.findByUserIdAndStatDateAndDeckIdIsNull(userId, today);
        if (allRow.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(new int[]{allRow.get().getReviewedCount(), allRow.get().getLearnedCount()});
    }

    private LocalTime refreshTimeOf(UUID userId) {
        return identityPort.refreshTimeOf(userId);
    }
}
