package top.kariscode.karisreview.card.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.common.exception.BusinessException;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CardImportParserTest {

    private final CardImportParser parser = new CardImportParser(new ObjectMapper());

    @Test
    void parsesValidCardArrayAndReturnsCounts() {
        String json = """
                [
                  {"front": "正面一", "back": "反面一"},
                  {"front": "正面二", "back": "反面二"}
                ]
                """;

        CardImportPreviewResponse response = parser.parse(json);

        assertEquals(2, response.getTotal());
        assertEquals(2, response.getValidCount());
        assertEquals(0, response.getInvalidCount());
        assertEquals(2, response.getCards().size());
        assertEquals("正面一", response.getCards().get(0).getFront());
        assertEquals("反面二", response.getCards().get(1).getBack());
        assertTrue(response.getCards().get(0).isValid());
        assertNull(response.getCards().get(0).getMessage());
    }

    @Test
    void marksMissingBlankNonStringAndNonObjectRowsAsInvalid() {
        String json = """
                [
                  {"front": "", "back": "反面"},
                  {"back": "缺少正面"},
                  {"front": 123, "back": "非字符串"},
                  42,
                  null,
                  {"front": "有效", "back": "有效"}
                ]
                """;

        CardImportPreviewResponse response = parser.parse(json);

        assertEquals(6, response.getTotal());
        assertEquals(1, response.getValidCount());
        assertEquals(5, response.getInvalidCount());
        assertTrue(response.getCards().get(0).getMessage().contains("正面内容不能为空"));
        assertTrue(response.getCards().get(1).getMessage().contains("正面内容不能为空"));
        assertTrue(response.getCards().get(2).getMessage().contains("正面内容必须是字符串"));
        assertEquals("卡片必须是对象", response.getCards().get(3).getMessage());
        assertEquals("卡片必须是对象", response.getCards().get(4).getMessage());
        assertNull(response.getCards().get(5).getMessage());
    }

    @Test
    void ignoresUnknownFieldsAndTrimsContentForValidation() {
        String json = """
                [
                  {"front": "  正面  ", "back": "反面", "extra": "忽略", "tags": [1, 2]},
                  {"front": "   ", "back": "反面"}
                ]
                """;

        CardImportPreviewResponse response = parser.parse(json);

        assertEquals(2, response.getTotal());
        assertEquals(1, response.getValidCount());
        assertEquals("  正面  ", response.getCards().get(0).getFront());
        assertTrue(response.getCards().get(1).getMessage().contains("正面内容不能为空"));
    }

    @Test
    void rejectsTopLevelNonArray() {
        BusinessException exception = assertThrows(
                BusinessException.class, () -> parser.parse("{\"front\":\"a\",\"back\":\"b\"}"));

        assertEquals(400, exception.getCode());
        assertEquals("JSON 必须是数组", exception.getMessage());
    }

    @Test
    void rejectsBlankAndMalformedJson() {
        assertThrows(BusinessException.class, () -> parser.parse(null));
        assertThrows(BusinessException.class, () -> parser.parse("  "));
        assertThrows(BusinessException.class, () -> parser.parse("[{\"front\":"));
    }

    @Test
    void rejectsEmptyArray() {
        BusinessException exception = assertThrows(
                BusinessException.class, () -> parser.parse("[]"));

        assertEquals(400, exception.getCode());
        assertEquals("JSON 数组不能为空", exception.getMessage());
    }

    @Test
    void acceptsExactlyMaxCards() {
        String json = "[" + String.join(",", Collections.nCopies(
                CardImportParser.MAX_CARDS, "{}")) + "]";

        CardImportPreviewResponse response = parser.parse(json);

        assertEquals(CardImportParser.MAX_CARDS, response.getTotal());
        assertEquals(0, response.getValidCount());
    }

    @Test
    void rejectsMoreThanMaxCards() {
        String json = "[" + String.join(",", Collections.nCopies(
                CardImportParser.MAX_CARDS + 1, "{}")) + "]";

        BusinessException exception = assertThrows(
                BusinessException.class, () -> parser.parse(json));

        assertEquals(400, exception.getCode());
        assertTrue(exception.getMessage().contains("单次最多导入"));
    }

    @Test
    void rejectsOversizedContent() {
        String content = "[" + " ".repeat(CardImportParser.MAX_CONTENT_LENGTH) + "]";

        BusinessException exception = assertThrows(
                BusinessException.class, () -> parser.parse(content));

        assertEquals(400, exception.getCode());
        assertTrue(exception.getMessage().contains("2MB"));
    }
}
