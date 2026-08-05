package top.kariscode.karisreview.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * 配置了 mail.smtp.host（非空）时启用的真实 SMTP 发送实现。
 */
@Component
@ConditionalOnExpression("!T(org.springframework.util.StringUtils).isEmpty('${mail.smtp.host:}')")
public class SmtpMailSender implements MailSender {

    private static final Logger log = LoggerFactory.getLogger(SmtpMailSender.class);

    private final JavaMailSender mailSender;
    private final String from;

    public SmtpMailSender(JavaMailSender mailSender,
                          @Value("${mail.from:noreply@kariscode.top}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void sendResetCode(String to, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject("Karis Review 找回密码验证码");
        message.setText("你的验证码是：" + code + "\n\n验证码 15 分钟内有效，请勿泄露给他人。\n如果不是你本人操作，请忽略本邮件。");
        mailSender.send(message);
        log.info("已发送找回密码验证码 to={}", to);
    }
}
