package top.kariscode.karisreview.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Component;

/**
 * 未配置 SMTP 时的默认实现：只把验证码打到日志，方便本地开发调试。
 */
@Component
@ConditionalOnMissingBean(SmtpMailSender.class)
public class NoopMailSender implements MailSender {

    private static final Logger log = LoggerFactory.getLogger(NoopMailSender.class);

    @Override
    public void sendResetCode(String to, String code) {
        log.info("[NoopMailSender] 模拟发送找回密码验证码 to={} code={}", to, code);
    }
}
