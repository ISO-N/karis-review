package top.kariscode.karisreview.deck.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.deck.dto.DeckCreateRequest;
import top.kariscode.karisreview.deck.dto.DeckResponse;
import top.kariscode.karisreview.deck.dto.DeckUpdateRequest;
import top.kariscode.karisreview.deck.entity.Deck;
import top.kariscode.karisreview.deck.repository.DeckRepository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeckServiceTest {

    @Mock
    private DeckRepository deckRepository;

    @Mock
    private CardRepository cardRepository;

    @Mock
    private IdentityPort identityPort;

    private DeckService service;

    @BeforeEach
    void setUp() {
        service = new DeckService(deckRepository, cardRepository, identityPort);
    }

    @Test
    void getUserDecksBuildsCountsAndDistributions() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = deck(deckId, "日语 N5", userId);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(deckRepository.findByUserIdOrderByCreatedAtAsc(userId)).thenReturn(List.of(deck));
        when(cardRepository.countByDeckId(deckId)).thenReturn(3L);
        when(cardRepository.countDueByDeckId(deckId, DateUtils.calculateToday(LocalTime.of(4, 0))))
                .thenReturn(1);
        when(cardRepository.countByDeckIdAndStageAndLearningModeFalse(deckId, 0)).thenReturn(2L);
        when(cardRepository.countByDeckIdAndStageGreaterThanEqual(deckId, 5)).thenReturn(1L);
        when(cardRepository.countByStageGroupedByDeck(deckId)).thenReturn(
                List.<Object[]>of(new Object[]{3, 2L}, new Object[]{5, 1L}));
        when(cardRepository.countDueByStageGroupedByDeck(deckId, DateUtils.calculateToday(LocalTime.of(4, 0))))
                .thenReturn(List.<Object[]>of(new Object[]{0, 1L}));

        List<DeckResponse> decks = service.getUserDecks(userId);

        assertEquals(1, decks.size());
        DeckResponse response = decks.get(0);
        assertEquals(deckId, response.getId());
        assertEquals("日语 N5", response.getName());
        assertEquals(3, response.getCardCount());
        assertEquals(1, response.getDueCount());
        assertEquals(2, response.getNewCount());
        assertEquals(1, response.getMasteredCount());
        assertEquals(2L, response.getStageDistribution().get(3));
        assertEquals(1L, response.getDueStageDistribution().get(0));
    }

    @Test
    void createDeckPersistsAndReturnsResponse() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        DeckCreateRequest request = new DeckCreateRequest();
        request.setName("新牌组");
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(deckRepository.save(any(Deck.class))).thenAnswer(invocation -> {
            Deck deck = invocation.getArgument(0);
            deck.setId(deckId);
            return deck;
        });

        DeckResponse response = service.createDeck(userId, request);

        assertEquals(deckId, response.getId());
        assertEquals("新牌组", response.getName());
        assertEquals(0, response.getCardCount());
        verify(deckRepository).save(any(Deck.class));
    }

    @Test
    void updateDeckRenamesOwnedDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = deck(deckId, "旧名", userId);
        when(identityPort.refreshTimeOf(userId)).thenReturn(LocalTime.of(4, 0));
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));
        when(deckRepository.save(deck)).thenReturn(deck);
        DeckUpdateRequest request = new DeckUpdateRequest();
        request.setName("新名");

        DeckResponse response = service.updateDeck(userId, deckId, request);

        assertEquals("新名", response.getName());
    }

    @Test
    void updateDeckRejectsMissingDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());
        DeckUpdateRequest request = new DeckUpdateRequest();
        request.setName("新名");

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.updateDeck(userId, deckId, request));

        assertEquals(404, exception.getCode());
        assertEquals("deck.notfound", exception.getMessage());
        verify(deckRepository, never()).save(any());
    }

    @Test
    void deleteDeckDeletesOwnedDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        Deck deck = deck(deckId, "牌组", userId);
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.of(deck));

        service.deleteDeck(userId, deckId);

        verify(deckRepository).delete(deck);
    }

    @Test
    void deleteDeckRejectsMissingDeck() {
        UUID userId = UUID.randomUUID();
        UUID deckId = UUID.randomUUID();
        when(deckRepository.findByIdAndUserId(deckId, userId)).thenReturn(Optional.empty());

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> service.deleteDeck(userId, deckId));

        assertEquals(404, exception.getCode());
        assertNotNull(exception.getMessage());
    }


    private Deck deck(UUID id, String name, UUID userId) {
        Deck deck = new Deck();
        deck.setId(id);
        deck.setName(name);
        deck.setUserId(userId);
        return deck;
    }
}
