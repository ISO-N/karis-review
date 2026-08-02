package top.kariscode.karisreview.card.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.card.dto.CardImportItem;
import top.kariscode.karisreview.card.dto.CardImportRequest;
import top.kariscode.karisreview.card.dto.CardImportResult;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CardImportServiceTest {

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private CardRepository cardRepository;

    @Mock
    private CardImportParser cardImportParser;

    private CardImportService service;

    @BeforeEach
    void setUp() {
        service = new CardImportService(deckRepository, cardRepository, cardImportParser);
    }

    @Test
    void importsCardsAsNewCardsForOwnedDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));

        CardImportRequest request = new CardImportRequest();
        request.setCards(List.of(item("正面一", "反面一"), item("正面二", "反面二")));

        CardImportResult result = service.importCards(userId, deckId, request);

        assertEquals(2, result.getImportedCards());
        ArgumentCaptor<List<Card>> captor = ArgumentCaptor.forClass(List.class);
        verify(cardRepository).saveAll(captor.capture());
        assertEquals(2, captor.getValue().size());
        Card card = captor.getValue().get(0);
        assertEquals(deckId, card.getDeckId());
        assertEquals(userId, card.getUserId());
        assertEquals("正面一", card.getFront());
        assertEquals("反面一", card.getBack());
        assertEquals(0, card.getStage());
        assertFalse(card.isLearningMode());
        assertNull(card.getNextReviewDate());
    }

    @Test
    void rejectsBlankCardBeforeSaving() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId))
                .thenReturn(Optional.of(new Deck()));

        CardImportRequest request = new CardImportRequest();
        request.setCards(List.of(item("正面", "  ")));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.importCards(userId, deckId, request));

        assertEquals(400, exception.getCode());
        assertEquals("反面内容不能为空", exception.getMessage());
        verify(cardRepository, never()).saveAll(any());
    }

    @Test
    void rejectsDeckNotOwnedByUser() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());

        CardImportRequest request = new CardImportRequest();
        request.setCards(List.of(item("正面", "反面")));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.importCards(userId, deckId, request));

        assertEquals(404, exception.getCode());
        assertEquals("牌组不存在", exception.getMessage());
        verify(cardRepository, never()).saveAll(any());
    }

    private CardImportItem item(String front, String back) {
        CardImportItem item = new CardImportItem();
        item.setFront(front);
        item.setBack(back);
        return item;
    }
}
