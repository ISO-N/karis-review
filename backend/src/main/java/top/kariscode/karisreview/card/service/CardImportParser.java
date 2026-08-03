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
            throw new BusinessException(400, "card.import.json.empty");
        }
        if (content.length() > MAX_CONTENT_LENGTH) {
            throw new BusinessException(400, "card.import.json.too.large");
        }

        JsonNode root;
        try {
            root = objectMapper.readTree(content);
        } catch (JsonProcessingException e) {
            throw new BusinessException(400, "card.import.json.invalid");
        }

        if (!root.isArray()) {
            throw new BusinessException(400, "card.import.json.must.be.array");
        }
        if (root.isEmpty()) {
            throw new BusinessException(400, "card.import.json.array.empty");
        }
        if (root.size() > MAX_CARDS) {
            throw new BusinessException(400, "card.import.too.many", MAX_CARDS);
        }

        List<CardImportPreviewItem> items = new ArrayList<>(root.size());
        int validCount = 0;
        for (int i = 0; i < root.size(); i++) {
            JsonNode node = root.get(i);
            if (!node.isObject()) {
                items.add(new CardImportPreviewItem(i, null, null, false, "card.import.must.be.object"));
                continue;
            }

            List<String> errors = new ArrayList<>(2);
            String front = readRequiredText(node, "front", "card.import.front", errors);
            String back = readRequiredText(node, "back", "card.import.back", errors);
            boolean valid = errors.isEmpty();
            if (valid) {
                validCount++;
            }
            items.add(new CardImportPreviewItem(
                    i, front, back, valid, errors.isEmpty() ? null : String.join(", ", errors)));
        }

        return new CardImportPreviewResponse(
                root.size(), validCount, root.size() - validCount, items);
    }

    private String readRequiredText(JsonNode node, String field, String keyPrefix,
                                    List<String> errors) {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            errors.add(keyPrefix + ".empty");
            return "";
        }
        if (!value.isTextual()) {
            errors.add(keyPrefix + ".must.be.string");
            return "";
        }
        String text = value.asText();
        if (text.trim().isEmpty()) {
            errors.add(keyPrefix + ".empty");
            return "";
        }
        return text;
    }
}
