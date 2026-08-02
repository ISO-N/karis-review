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

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
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

    public List<ReviewCardResponse> getDueCards(UUID userId, UUID deckId) {
        LocalTime refreshTime = getRefreshTime(userId);
        LocalDate today = DateUtils.calculateToday(refreshTime);

        List<Card> dueCards = cardRepository.findDueCards(userId, today, deckId);
        List<Card> learningCards = cardRepository.findLearningModeCards(userId, today, deckId);
        return interleaveLearningCards(dueCards, learningCards);
    }

    public List<ReviewCardResponse> getNewCards(UUID userId, UUID deckId, int limit) {
        List<Card> newCards = cardRepository.findNewCards(userId, deckId);
        if (newCards.size() > limit) {
            newCards = newCards.subList(0, limit);
        }
        return newCards.stream()
                .map(this::toReviewCardResponse)
                .toList();
    }

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

        ReviewLog log = new ReviewLog();
        log.setCardId(cardId);
        log.setUserId(userId);
        log.setRating(rating);
        log.setStageBefore(result.getStageBefore());
        log.setStageAfter(result.getStageAfter());
        reviewLogRepository.save(log);

        LocalDate today = DateUtils.calculateToday(refreshTime);
        int nextIntervalDays = result.getNextReviewDate() == null
                ? 0
                : (int) ChronoUnit.DAYS.between(today, result.getNextReviewDate());
        return new RateResponse(
                cardId, rating,
                result.getStageBefore(),
                result.getStageAfter(),
                result.getNextReviewDate(),
                result.isLearningMode(),
                result.getConsecutiveFamiliar(),
                nextIntervalDays);
    }

    private List<ReviewCardResponse> interleaveLearningCards(
            List<Card> dueCards, List<Card> learningCards) {

        List<ReviewCardResponse> queue = dueCards.stream()
                .map(this::toReviewCardResponse)
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
            queue.add(position, toReviewCardResponse(card));
        }

        return queue;
    }

    private ReviewCardResponse toReviewCardResponse(Card card) {
        return new ReviewCardResponse(
                card.getId(), card.getDeckId(),
                card.getFront(), card.getBack(),
                card.getStage(), card.isLearningMode(),
                card.getConsecutiveFamiliar(),
                SchedulingEngine.getRelearningThreshold(card),
                card.getReentryStage(),
                card.getNextReviewDate(),
                SchedulingEngine.getStageInterval(card.getStage()),
                SchedulingEngine.getFamiliarIntervalAfterRating(card),
                SchedulingEngine.getVagueIntervalAfterRating(card));
    }

    private LocalTime getRefreshTime(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }
}
