package top.kariscode.karisreview.common.exception;

public class BusinessException extends RuntimeException {

    private final int code;
    private final String messageKey;
    private final Object[] args;

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
        this.messageKey = null;
        this.args = null;
    }

    public BusinessException(String message) {
        super(message);
        this.code = 400;
        this.messageKey = null;
        this.args = null;
    }

    public BusinessException(int code, String messageKey, Object... args) {
        super(messageKey);
        this.code = code;
        this.messageKey = messageKey;
        this.args = args;
    }

    public int getCode() { return code; }
    public String getMessageKey() { return messageKey; }
    public Object[] getArgs() { return args; }
}