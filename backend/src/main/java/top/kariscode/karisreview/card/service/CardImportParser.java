package top.kariscode.karisreview.card.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import top.kariscode.karisreview.card.dto.CardImportPreviewItem;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.common.exception.BusinessException;

import java.util.ArrayList;
import java.util.List;

@Component
public class CardImportParser {

    public static final int MAX_CARDS = 1000;
    public static final int MAX_CONTENT_LENGTH = 2_000_000;

    private final ObjectMapper objectMapper;

    public CardImportParser(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public CardImportPreviewResponse parse(String content) {
        if (content == null || content.isBlank()) {
            throw new BusinessException(400, "JSON 内容不能为空");
        }
        if (content.length() > MAX_CONTENT_LENGTH) {
            throw new BusinessException(400, "JSON 内容过大，最多支持 2MB");
        }

        JsonNode root;
        try {
            root = objectMapper.readTree(content);
        } catch (JsonProcessingException e) {
            throw new BusinessException(400, "JSON 格式不正确");
        }

        if (!root.isArray()) {
            throw new BusinessException(400, "JSON 必须是数组");
        }
        if (root.isEmpty()) {
            throw new BusinessException(400, "JSON 数组不能为空");
        }
        if (root.size() > MAX_CARDS) {
            throw new BusinessException(400, "单次最多导入 " + MAX_CARDS + " 张卡片");
        }

        List<CardImportPreviewItem> items = new ArrayList<>(root.size());
        int validCount = 0;
        for (int i = 0; i < root.size(); i++) {
            JsonNode node = root.get(i);
            if (!node.isObject()) {
                items.add(new CardImportPreviewItem(i, null, null, false, "卡片必须是对象"));
                continue;
            }

            List<String> errors = new ArrayList<>(2);
            String front = readRequiredText(node, "front", "正面", errors);
            String back = readRequiredText(node, "back", "反面", errors);
            boolean valid = errors.isEmpty();
            if (valid) {
                validCount++;
            }
            items.add(new CardImportPreviewItem(
                    i, front, back, valid, errors.isEmpty() ? null : String.join("，", errors)));
        }

        return new CardImportPreviewResponse(
                root.size(), validCount, root.size() - validCount, items);
    }

    private String readRequiredText(JsonNode node, String field, String label,
                                    List<String> errors) {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            errors.add(label + "内容不能为空");
            return "";
        }
        if (!value.isTextual()) {
            errors.add(label + "内容必须是字符串");
            return "";
        }
        String text = value.asText();
        if (text.trim().isEmpty()) {
            errors.add(label + "内容不能为空");
            return "";
        }
        return text;
    }
}
