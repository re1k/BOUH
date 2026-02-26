package com.bouh.backend.model.Dto;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;
import java.util.List;

@Data //setters,getters and constructors
public class caregiverDto {
    @DocumentId
    private String caregiverId;

    private String name;
    private String email;
    private String fcmToken;
    private List<childDto> children;
}
