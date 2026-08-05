package top.kariscode.karisreview.auth.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import top.kariscode.karisreview.common.outbox.DomainEvent;
import top.kariscode.karisreview.common.outbox.DomainEventHandler;
import top.kariscode.karisreview.common.outbox.OutboxEventTypes;

import java.util.Map;

/**
 * 邮件 Outbox 处理器：消费 MAIL_RESET_CODE 事件，经 {@link MailSender} 异步投递。
 * 发信失败时由 OutboxRelay 指数退避重试（验证码邮件场景下最多 10 次），
 * 不再阻塞注册/找回密码接口。
 */
@Component
public class MailOutboxHandler implements DomainEventHandler {

    private static final Logger log = LoggerFactory.getLogger(MailOutboxHandler.class);

    private final MailSender mailSender;
    private final ObjectMapper objectMapper;

    public MailOutboxHandler(MailSender mailSender, ObjectMapper objectMapper) {
        this.mailSender = mailSender;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(String eventType) {
        return OutboxEventTypes.MAIL_RESET_CODE.equals(eventType);
    }

    @Override
    public void handle(DomainEvent event) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, String> payload = objectMapper.readValue(event.payload(), Map.class);
            String to = payload.get("to");
            String code = payload.get("code");
            if (to == null || code == null) {
                throw new IllegalArgumentException("Mail event payload missing to/code");
            }
            mailSender.sendResetCode(to, code);
            log.debug("Mail sent to {} via outbox", to);
        } catch (Exception e) {
            log.warn("Mail delivery failed for event {}: {}", event.eventType(), e.getMessage());
            throw new RuntimeException(e);
        }
    }
}
