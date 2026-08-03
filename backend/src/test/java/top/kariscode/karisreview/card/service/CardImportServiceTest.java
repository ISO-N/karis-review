package top.kariscode.karisreview.card.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.card.dto.CardImportItem;
import top.kariscode.karisreview.card.dto.CardImportPreviewResponse;
import top.kariscode.karisreview.card.dto.CardImportRequest;
import top.kariscode.karisreview.card.dto.CardImportResult;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;
import top.kariscode.karisreview.log.service.UserLogService;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CardImportServiceTest {

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private CardRepository cardRepository;

    @Mock
    private CardImportParser cardImportParser;

    private CardImportService service;
    @Mock
    private UserLogService userLogService;


    @BeforeEach
    void setUp() {
        service = new CardImportService(deckRepository, cardRepository, cardImportParser, userLogService);
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
        when(cardRepository.saveAll(any())).thenAnswer(invocation -> {
            List<Card> cards = invocation.getArgument(0);
            for (int i = 0; i < cards.size(); i++) {
                cards.get(i).setId(UUID.randomUUID());
            }
            return cards;
        });

        CardImportResult result = service.importCards(userId, deckId, request);

        assertEquals(2, result.getImportedCards());
        assertNotNull(result.getImportedCardIds());
        assertEquals(2, result.getImportedCardIds().size());
        assertNotNull(result.getImportedCardIds().get(0));
        ArgumentCaptor<List<Card>> captor = ArgumentCaptor.forClass(List.class);
        verify(cardRepository).saveAll(captor.capture());
        assertEquals(2, captor.getValue().size());
        Card card = captor.getValue().get(0);
        assertEquals(deckId, card.getDeckId());
        assertEquals(userId, card.getUserId());
        assertEquals("正面一", card.getFront());
        assertEquals(0, card.getStage());
        assertNull(card.getNextReviewDate());
    }

    @Test
    void previewRequiresOwnedDeckBeforeParsing() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.preview(userId, deckId, "[]"));

        assertEquals(404, exception.getCode());
        verify(cardImportParser, never()).parse(any());
    }

    @Test
    void previewDelegatesToParserForOwnedDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        CardImportPreviewResponse preview = new CardImportPreviewResponse(1, 1, 0, List.of());
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));
        when(cardImportParser.parse("content")).thenReturn(preview);

        assertEquals(preview, service.preview(userId, deckId, "content"));
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
        assertEquals("card.import.back.empty", exception.getMessage());
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
        assertEquals("deck.notfound", exception.getMessage());
        verify(cardRepository, never()).saveAll(any());
    }

    @Test
    void rejectsEmptyCardList() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId))
                .thenReturn(Optional.of(new Deck()));

        CardImportRequest request = new CardImportRequest();
        request.setCards(List.of());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.importCards(userId, deckId, request));

        assertEquals(400, exception.getCode());
        assertEquals("card.import.list.empty", exception.getMessage());
        verify(cardRepository, never()).saveAll(any());
    }

    @Test
    void rejectsMoreThanMaxCards() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId))
                .thenReturn(Optional.of(new Deck()));

        CardImportRequest request = new CardImportRequest();
        request.setCards(new ArrayList<>());
        request.getCards().clear();
        for (int i = 0; i < CardImportParser.MAX_CARDS + 1; i++) {
            request.getCards().add(item("正面" + i, "反面" + i));
        }

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.importCards(userId, deckId, request));

        assertEquals(400, exception.getCode());
        verify(cardRepository, never()).saveAll(any());
    }

    @Test
    void rejectsNullRowAndRejectsWholeImport() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId))
                .thenReturn(Optional.of(new Deck()));

        CardImportRequest request = new CardImportRequest();
        List<CardImportItem> cards = new ArrayList<>();
        cards.add(item("正面", "反面"));
        cards.add(null);
        request.setCards(cards);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.importCards(userId, deckId, request));

        assertEquals(400, exception.getCode());
        assertEquals("card.import.data.empty", exception.getMessage());
        verify(cardRepository, never()).saveAll(any());
    }

    private CardImportItem item(String front, String back) {
        CardImportItem item = new CardImportItem();
        item.setFront(front);
        item.setBack(back);
        return item;
    }
}