package top.kariscode.karisreview.auth.api;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * 身份上下文对外门面（阶段二 M6 Identity 拆分准备 / 模块契约 WP-9）。
 *
 * <p>其他业务模块只允许通过本接口读取用户身份信息，<b>禁止</b>直接依赖
 * {@code auth.repository} / {@code auth.entity}（由 ArchUnit 强制）。
 * 未来 Identity 拆分为独立服务时，本接口可无缝替换为远程实现（防腐层）。
 */
public interface IdentityPort {

    /** 用户只读视图（不含密码哈希等敏感字段）。 */
    record UserView(UUID id, String email, LocalTime refreshTime) {}

    Optional<UserView> findById(UUID userId);

    Optional<UserView> findByEmail(String email);

    boolean existsByEmail(String email);

    /** 用户每日刷新时间（不存在时回退默认 04:00）。 */
    LocalTime refreshTimeOf(UUID userId);

    /** 全量用户 ID（后台批量任务使用）。 */
    List<UUID> findAllUserIds();
}
