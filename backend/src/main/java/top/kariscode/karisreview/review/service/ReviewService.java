package top.kariscode.karisreview.review.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.card.entity.Card;
import top.kariscode.karisreview.card.repository.CardRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.common.util.DateUtils;
import top.kariscode.karisreview.review.dto.RateRequest;
import top.kariscode.karisreview.review.dto.RateResponse;
import top.kariscode.karisreview.review.dto.ReviewCardResponse;
import top.kariscode.karisreview.review.entity.ReviewLog;
import top.kariscode.karisreview.review.repository.ReviewLogRepository;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class ReviewService {

    private final CardRepository cardRepository;
    private final ReviewLogRepository reviewLogRepository;
    private final UserRepository userRepository;
    private final SchedulingEngine schedulingEngine;

    public ReviewService(CardRepository cardRepository,
                         ReviewLogRepository reviewLogRepository,
                         UserRepository userRepository,
                         SchedulingEngine schedulingEngine) {
        this.cardRepository = cardRepository;
        this.reviewLogRepository = reviewLogRepository;
        this.userRepository = userRepository;
        this.schedulingEngine = schedulingEngine;
    }

    /**
     * Get today's due cards for review.
     * Includes both normal due cards and learning mode cards.
     */
    public List<ReviewCardResponse> getDueCards(UUID userId, UUID deckId) {
        LocalTime refreshTime = getRefreshTime(userId);
        var today = DateUtils.calculateToday(refreshTime);

        // Get normal due cards
        List<Card> dueCards = cardRepository.findDueCards(userId, today, deckId);

        // Get learning mode cards
        List<Card> learningCards = cardRepository.findLearningModeCards(userId, today, deckId);

        // Combine: learning mode cards interleaved based on 2^n spacing
        return interleaveLearningCards(dueCards, learningCards);
    }

    /**
     * Get new cards to learn (Stage 0, not in learning mode).
     */
    public List<ReviewCardResponse> getNewCards(UUID userId, UUID deckId, int limit) {
        List<Card> newCards = cardRepository.findNewCards(userId, deckId);
        if (newCards.size() > limit) {
            newCards = newCards.subList(0, limit);
        }
        return newCards.stream()
                .map(card -> new ReviewCardResponse(
                        card.getId(), card.getDeckId(),
                        card.getFront(), card.getBack(),
                        card.getStage(), card.isLearningMode(),
                        card.getConsecutiveFamiliar()))
                .toList();
    }

    /**
     * Rate a card and apply scheduling algorithm.
     */
    @Transactional
    public RateResponse rateCard(UUID userId, UUID cardId, RateRequest request) {
        Card card = cardRepository.findByIdAndUserId(cardId, userId)
                .orElseThrow(() -> new BusinessException(404, "卡片不存在"));

        LocalTime refreshTime = getRefreshTime(userId);
        String rating = request.getRating();

        SchedulingEngine.RatingResult result;
        switch (rating) {
            case "FORGET" -> result = schedulingEngine.rateForget(card, refreshTime);
            case "VAGUE" -> result = schedulingEngine.rateVague(card, refreshTime);
            case "FAMILIAR" -> result = schedulingEngine.rateFamiliar(card, refreshTime);
            default -> throw new BusinessException(400, "无效的评分");
        }

        card = cardRepository.save(card);

        // Create review log
        ReviewLog log = new ReviewLog();
        log.setCardId(cardId);
        log.setUserId(userId);
        log.setRating(rating);
        log.setStageBefore(result.getStageBefore());
        log.setStageAfter(result.getStageAfter());
        reviewLogRepository.save(log);

        return new RateResponse(
                cardId, rating,
                result.getStageBefore(),
                result.getStageAfter(),
                result.getNextReviewDate(),
                result.isLearningMode(),
                result.getConsecutiveFamiliar());
    }

    /**
     * Interleave learning mode cards into the due cards queue using 2^n spacing.
     *
     * Each learning card has a learning step n (0-based). It is inserted after
     * 2^n other cards in the running queue. Lower steps come earlier in the
     * review session so newly re-entered cards are seen sooner; cards that have
     * already been rated Familiar in this relearning cycle are placed farther
     * into the queue with doubled spacing, matching the requirement:
     *   第 1 次插入：隔 1 张卡（2^0）
     *   第 2 次插入：再隔 2 张卡（2^1）
     *   第 3 次插入：再隔 4 张卡（2^2）
     */
    private List<ReviewCardResponse> interleaveLearningCards(
            List<Card> dueCards, List<Card> learningCards) {

        List<ReviewCardResponse> queue = dueCards.stream()
                .map(c -> new ReviewCardResponse(
                        c.getId(), c.getDeckId(),
                        c.getFront(), c.getBack(),
                        c.getStage(), c.isLearningMode(),
                        c.getConsecutiveFamiliar()))
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);

        if (learningCards.isEmpty()) {
            return queue;
        }

        List<Card> sortedLearning = learningCards.stream()
                .sorted(Comparator.comparingInt(Card::getLearningStep)
                        .thenComparing(Card::getCreatedAt))
                .toList();

        for (Card card : sortedLearning) {
            int offset = 1 << card.getLearningStep();
            int position = Math.min(offset, queue.size());
            queue.add(position, new ReviewCardResponse(
                    card.getId(), card.getDeckId(),
                    card.getFront(), card.getBack(),
                    card.getStage(), card.isLearningMode(),
                    card.getConsecutiveFamiliar()));
        }

        return queue;
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}