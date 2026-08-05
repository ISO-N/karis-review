package top.kariscode.karisreview.auth.service;

import org.springframework.stereotype.Service;
import top.kariscode.karisreview.auth.api.IdentityPort;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * {@link IdentityPort} 单体实现：直接访问用户表。
 * Identity 拆分为独立服务后，替换为远程实现即可，业务模块无感。
 */
@Service
public class IdentityPortImpl implements IdentityPort {

    private final UserRepository userRepository;

    public IdentityPortImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public Optional<UserView> findById(UUID userId) {
        return userRepository.findById(userId).map(this::toView);
    }

    @Override
    public Optional<UserView> findByEmail(String email) {
        return userRepository.findByEmail(email).map(this::toView);
    }

    @Override
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    @Override
    public LocalTime refreshTimeOf(UUID userId) {
        return userRepository.findById(userId)
                .map(User::getRefreshTime)
                .orElse(LocalTime.of(4, 0));
    }

    @Override
    public List<UUID> findAllUserIds() {
        return userRepository.findAllUserIds();
    }

    private UserView toView(User user) {
        return new UserView(user.getId(), user.getEmail(), user.getRefreshTime());
    }
}
