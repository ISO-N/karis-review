package top.kariscode.karisreview.auth.service;

/**
 * 邮件发送抽象。未配置 SMTP 时使用 {@link NoopMailSender}（仅记日志），
 * 配置 mail.smtp.host 后自动切换 {@link SmtpMailSender}。
 */
public interface MailSender {

    void sendResetCode(String to, String code);
}
