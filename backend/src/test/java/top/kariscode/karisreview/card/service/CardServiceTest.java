package top.kariscode.karisreview.card.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.card.dto.CardCreateRequest;
import top.kariscode.karisreview.card.dto.CardResponse;
import top.kariscode.karisreview.card.dto.CardUpdateRequest;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CardServiceTest {

    @Mock
    private CardRepository cardRepository;

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private IdentityPort identityPort;

    private CardService service;

    @BeforeEach
    void setUp() {
        service = new CardService(cardRepository, deckRepository, identityPort);
    }

    @Test
    void getDeckCardsReturnsAllFilteredByPage() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId, PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "all");

        assertEquals(1, page.getContent().size());
        assertEquals(deckId, page.getContent().get(0).getDeckId());
    }

    @Test
    void getDeckCardsUsesDueFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        LocalDate today = DateUtils.calculateToday(LocalTime.of(4, 0));
        Card card = card(deckId, userId);
        card.setNextReviewDate(today);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                deckId, today, PageRequest.of(0, 20))).thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "due");

        assertTrue(page.getContent().get(0).isDue());
    }

    @Test
    void getDeckCardsUsesLearningFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        card.setLearningMode(true);
        card.setReentryStage(4);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(deckId, PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "learning");

        assertTrue(page.getContent().get(0).isLearningMode());
    }

    @Test
    void getDeckCardsUsesNewFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findNewByDeckIdOrderByCreatedAtDesc(deckId, PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "new");

        assertEquals(1, page.getContent().size());
        assertFalse(page.getContent().get(0).isLearningMode());
    }

    @Test
    void getDeckCardsRejectsDeckNotOwned() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(false);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getDeckCards(userId, deckId, 0, 20, "all"));

        assertEquals(404, exception.getCode());
        assertEquals("deck.notfound", exception.getMessage());
    }

    @Test
    void blankSearchQueryUsesOriginalAllQuery() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.findByDeckIdOrderByCreatedAtAsc(deckId, PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "all", "  ");

        assertEquals(1, page.getContent().size());
        verify(cardRepository).findByDeckIdOrderByCreatedAtAsc(deckId, PageRequest.of(0, 20));
    }

    @Test
    void searchUsesFrontAndBackPattern() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.searchByDeckIdOrderByCreatedAtAsc(deckId, "%词%", PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(userId, deckId, 0, 20, "all", "词");

        assertEquals(1, page.getContent().size());
        verify(cardRepository).searchByDeckIdOrderByCreatedAtAsc(
                eq(deckId), eq("%词%"), any(PageRequest.class));
    }

    @Test
    void searchCombinesDueFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        LocalDate today = DateUtils.calculateToday(LocalTime.of(4, 0));
        Card card = card(deckId, userId);
        card.setNextReviewDate(today);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.searchByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                deckId, today, "%到期%", PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(
                userId, deckId, 0, 20, "due", "到期");

        assertTrue(page.getContent().get(0).isDue());
        verify(cardRepository).searchByDeckIdAndNextReviewDateNotNullAndNextReviewDateLessThanEqualOrderByNextReviewDateAsc(
                eq(deckId), eq(today), eq("%到期%"), any(PageRequest.class));
    }

    @Test
    void searchCombinesLearningFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        card.setLearningMode(true);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.searchByDeckIdAndLearningModeTrueOrderByCreatedAtAsc(
                deckId, "%重学%", PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(
                userId, deckId, 0, 20, "learning", "重学");

        assertTrue(page.getContent().get(0).isLearningMode());
    }

    @Test
    void searchCombinesNewFilter() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.searchNewByDeckIdOrderByCreatedAtDesc(
                deckId, "%新卡%", PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(card)));

        Page<CardResponse> page = service.getDeckCards(
                userId, deckId, 0, 20, "new", "新卡");

        assertEquals(1, page.getContent().size());
        assertFalse(page.getContent().get(0).isLearningMode());
    }

    @Test
    void searchEscapesLikeWildcards() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.searchByDeckIdOrderByCreatedAtAsc(
                eq(deckId), any(String.class), any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(card)));

        service.getDeckCards(userId, deckId, 0, 20, "all", "100%_");

        verify(cardRepository).searchByDeckIdOrderByCreatedAtAsc(
                eq(deckId), eq("%100\\%\\_%"), any(PageRequest.class));
    }

    @Test
    void searchRejectsQueryLongerThan100Characters() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.existsByIdAndUserId(deckId, userId)).thenReturn(true);

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.getDeckCards(
                        userId, deckId, 0, 20, "all", "a".repeat(101)));

        assertEquals(400, exception.getCode());
        assertEquals("card.search.too.long", exception.getMessage());
    }

    @Test
    void createCardPersistsAndReturnsResponse() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Deck deck = new Deck();
        deck.setId(deckId);
        deck.setUserId(userId);
        CardCreateRequest request = new CardCreateRequest();
        request.setFront("正面");
        request.setBack("反面");
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.save(any(Card.class))).thenAnswer(invocation -> {
            Card card = invocation.getArgument(0);
            card.setId(cardId);
            return card;
        });

        CardResponse response = service.createCard(userId, deckId, request);

        assertEquals(cardId, response.getId());
        assertEquals("正面", response.getFront());
        assertEquals(0, response.getStage());
        assertNull(response.getNextReviewDate());
        assertFalse(response.isDue());
    }

    @Test
    void createCardRejectsMissingDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        CardCreateRequest request = new CardCreateRequest();
        request.setFront("正面");
        request.setBack("反面");
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.createCard(userId, deckId, request));

        assertEquals(404, exception.getCode());
        verify(cardRepository, never()).save(any());
    }

    @Test
    void updateCardChangesContentOnly() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        Card card = card(deckId, userId);
        card.setId(cardId);
        card.setStage(3);
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(cardRepository.save(card)).thenReturn(card);
        CardUpdateRequest request = new CardUpdateRequest();
        request.setFront("新正面");
        request.setBack("新反面");

        CardResponse response = service.updateCard(userId, cardId, request);

        assertEquals("新正面", response.getFront());
        assertEquals(3, response.getStage());
    }

    @Test
    void updateCardRejectsCardNotOwned() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.empty());
        CardUpdateRequest request = new CardUpdateRequest();
        request.setFront("正面");
        request.setBack("反面");

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.updateCard(userId, cardId, request));

        assertEquals(404, exception.getCode());
        assertEquals("card.notfound", exception.getMessage());
    }

    @Test
    void getCardMarksDueWhenNextReviewDateIsToday() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        LocalDate today = DateUtils.calculateToday(LocalTime.of(4, 0));
        Card card = card(deckId, userId);
        card.setId(cardId);
        card.setNextReviewDate(today);
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.of(card));
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));

        CardResponse response = service.getCard(userId, cardId);

        assertTrue(response.isDue());
    }

    @Test
    void deleteCardDeletesOwnedCard() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card card = card(deckId, userId);
        when(cardRepository.findByIdAndUserId(card.getId(), userId)).thenReturn(Optional.of(card));

        service.deleteCard(userId, card.getId());

        verify(cardRepository).delete(card);
    }

    @Test
    void deleteCardsDeletesOnlyOwnedCardsAndIgnoresMissingIds() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Card ownedCard = card(deckId, userId);
        UUID missingId = UUID.randomUUID();
        when(cardRepository.findByIdInAndUserId(List.of(ownedCard.getId(), missingId), userId))
                .thenReturn(List.of(ownedCard));

        int deleted = service.deleteCards(userId, List.of(ownedCard.getId(), missingId));

        assertEquals(1, deleted);
        verify(cardRepository).deleteAll(List.of(ownedCard));
    }

    @Test
    void deleteCardsRejectsEmptyIds() {
        UUID userId = UUID.randomUUID();

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.deleteCards(userId, List.of()));

        assertEquals(400, exception.getCode());
        assertEquals("card.id.list.empty", exception.getMessage());
        verify(cardRepository, never()).deleteAll(any());
    }

    @Test
    void deleteCardRejectsMissingCard() {
        UUID userId = UUID.randomUUID();
        UUID cardId = UUID.randomUUID();
        when(cardRepository.findByIdAndUserId(cardId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.deleteCard(userId, cardId));

        assertEquals(404, exception.getCode());
    }


    private Card card(UUID deckId, UUID userId) {
        Card card = new Card();
        card.setId(UUID.randomUUID());
        card.setDeckId(deckId);
        card.setUserId(userId);
        card.setFront("正面");
        card.setBack("反面");
        return card;
    }
}