package top.kariscode.karisreview.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.auth.entity.PasswordResetCode;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, UUID> {

    Optional<PasswordResetCode> findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
            String email, String purpose);

    @Modifying
    @Query("DELETE FROM PasswordResetCode c WHERE c.expiresAt < :now")
    void deleteExpired(@Param("now") LocalDateTime now);

    /**
     * 定期保留策略：删除已过期超过 cutoff 的记录（保留宽限期内的记录以便审计排查）。
     */
    @Modifying
    @Query("DELETE FROM PasswordResetCode c WHERE c.expiresAt < :cutoff")
    int deleteExpiredBefore(@Param("cutoff") LocalDateTime cutoff);
}
