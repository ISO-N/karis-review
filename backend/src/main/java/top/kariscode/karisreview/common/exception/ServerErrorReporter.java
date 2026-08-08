package top.kariscode.karisreview.common.exception;

import java.util.Map;
import java.util.UUID;

/**
 * 服务端错误上报接口（2026-08-08 架构评审 B1）。
 *
 * <p>common 包必须是零业务依赖的底座：GlobalExceptionHandler 通过本接口上报
 * 500 错误日志，具体实现由 log 模块提供（UserLogService），依赖方向为
 * common ← log（实现接口），编译期无环。</p>
 *
 * <p>这是「一个适配器 = 假设的接缝」的刻意用例：当前仅 log 一个实现，
 * 接口存在的意义是切断 common→log 的编译期依赖，而非为未来多实现预留。</p>
 */
public interface ServerErrorReporter {

    /**
     * 上报一条服务端错误日志。
     *
     * @param userId 当前用户（可能为 null，表示匿名上下文）
     * @param messageKey 日志消息键
     * @param detail 结构化详情
     */
    void report(UUID userId, String messageKey, Map<String, Object> detail);
}
