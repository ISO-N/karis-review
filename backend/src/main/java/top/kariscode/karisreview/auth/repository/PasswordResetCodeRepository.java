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
}
