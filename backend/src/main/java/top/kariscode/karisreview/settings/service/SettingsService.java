package top.kariscode.karisreview.settings.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import top.kariscode.karisreview.auth.entity.User;
import top.kariscode.karisreview.auth.repository.UserRepository;
import top.kariscode.karisreview.common.exception.BusinessException;
import top.kariscode.karisreview.settings.dto.UpdateSettingsRequest;
import top.kariscode.karisreview.settings.dto.UserSettingsResponse;

import java.time.LocalTime;
import java.util.UUID;

@Service
public class SettingsService {

    private final UserRepository userRepository;

    public SettingsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public UserSettingsResponse getSettings(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));
        return new UserSettingsResponse(user.getEmail(), user.getRefreshTime());
    }

    @Transactional
    public UserSettingsResponse updateSettings(UUID userId, UpdateSettingsRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));
        user.setRefreshTime(LocalTime.parse(request.getRefreshTime()));
        user = userRepository.save(user);
        return new UserSettingsResponse(user.getEmail(), user.getRefreshTime());
    }
}