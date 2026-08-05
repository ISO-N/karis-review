package top.kariscode.karisreview.common.outbox;

/**
 * Outbox 事件类型与聚合类型常量（集中定义，避免字符串散落各处）。
 */
public final class OutboxEventTypes {

    private OutboxEventTypes() {}

    // ---- 聚合类型 ----
    public static final String AGG_MAIL = "mail";
    public static final String AGG_REVIEW_LOG = "review_log";
    public static final String AGG_USER = "user";
    public static final String AGG_CARD = "card";
    public static final String AGG_DECK = "deck";

    // ---- 邮件事件 ----
    /** 验证码/重置邮件（payload: {"to": "...", "code": "..."}） */
    public static final String MAIL_RESET_CODE = "MAIL_RESET_CODE";

    // ---- 复习事件 ----
    /** 复习评分已落库（payload: {"userId","deckId","rating","isNewCard","reviewedAt"}） */
    public static final String REVIEW_LOGGED = "REVIEW_LOGGED";

    // ---- 用户事件 ----
    public static final String USER_REGISTERED = "USER_REGISTERED";

    // ---- 内容事件 ----
    public static final String CARD_CREATED = "CARD_CREATED";
    public static final String CARD_UPDATED = "CARD_UPDATED";
    public static final String CARD_DELETED = "CARD_DELETED";
    public static final String DECK_CREATED = "DECK_CREATED";
    public static final String DECK_UPDATED = "DECK_UPDATED";
    public static final String DECK_DELETED = "DECK_DELETED";
}
