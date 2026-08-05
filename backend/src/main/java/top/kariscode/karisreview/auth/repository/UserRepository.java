package top.kariscode.karisreview.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import top.kariscode.karisreview.auth.entity.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    /** 全量用户 ID 列表（预聚合重算等后台任务使用，分批处理时可按 ID 排序分页）。 */
    @Query("SELECT u.id FROM User u ORDER BY u.createdAt ASC")
    List<UUID> findAllUserIds();
}