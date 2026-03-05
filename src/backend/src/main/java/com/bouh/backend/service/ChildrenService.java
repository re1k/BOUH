package com.bouh.backend.service;

import com.bouh.backend.model.Dto.childDto;
import com.bouh.backend.model.Dto.ChildRequestDto;
import com.bouh.backend.model.repository.childrenRepo;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChildrenService {

    private final childrenRepo childrenRepo;

    public ChildrenService(childrenRepo childrenRepo) {
        this.childrenRepo = childrenRepo;
    }

    public List<childDto> getChildren(String caregiverId) throws Exception {
        return childrenRepo.getChildren(caregiverId);
    }

    // max 5 children
    public childDto addChild(String caregiverId, ChildRequestDto request) throws Exception {
        validateAddRequest(request);

        int count = childrenRepo.countChildren(caregiverId);
        if (count >= 5) {
            throw new IllegalStateException("You can only add up to 5 children.");
        }

        String gender = normalizeGender(request.getGender());
        return childrenRepo.addChild(
                caregiverId,
                request.getName().trim(),
                request.getDateOfBirth(),
                gender
        );
    }

    // edit child
    public childDto updateChild(String caregiverId, String childId, ChildRequestDto request) throws Exception {
        Map<String, Object> updates = new HashMap<>();

        if (request.getName() != null) {
            if (request.getName().trim().isEmpty()) throw new IllegalArgumentException("name cannot be empty");
            updates.put("name", request.getName().trim());
        }

        if (request.getDateOfBirth() != null) {
            validateIsoDate(request.getDateOfBirth());
            updates.put("dateOfBirth", request.getDateOfBirth());
        }

        if (request.getGender() != null) {
            String g = normalizeGender(request.getGender());
            if (g == null) throw new IllegalArgumentException("gender must be male/female");
            updates.put("gender", g);
        }

        if (updates.isEmpty()) {
            throw new IllegalArgumentException("No fields to update.");
        }

        childDto updated = childrenRepo.updateChild(caregiverId, childId, updates);
        if (updated == null) throw new IllegalStateException("Child not found.");
        return updated;
    }

    //delete only if > 1 child
    public void deleteChild(String caregiverId, String childId) throws Exception {
        int count = childrenRepo.countChildren(caregiverId);
        if (count <= 1) {
            throw new IllegalStateException("Cannot delete the only child in the account.");
        }

        boolean deleted = childrenRepo.deleteChild(caregiverId, childId);
        if (!deleted) throw new IllegalStateException("Child not found.");
    }

    // ---------------- Helpers ----------------

    private void validateAddRequest(ChildRequestDto request) {
        if (request == null) throw new IllegalArgumentException("Request body is required.");
        if (isBlank(request.getName())) throw new IllegalArgumentException("name is required");
        if (isBlank(request.getDateOfBirth())) throw new IllegalArgumentException("dateOfBirth is required");
        if (isBlank(request.getGender())) throw new IllegalArgumentException("gender is required");

        validateIsoDate(request.getDateOfBirth());

        String g = normalizeGender(request.getGender());
        if (g == null) throw new IllegalArgumentException("gender must be male/female");
    }

    private void validateIsoDate(String iso) {
        try {
            LocalDate.parse(iso);
        } catch (Exception e) {
            throw new IllegalArgumentException("dateOfBirth must be YYYY-MM-DD and valid date.");
        }
    }

    private String normalizeGender(String g) {
        if (g == null) return null;
        String s = g.trim().toLowerCase();
        if (s.equals("male") || s.equals("m") || s.equals("ذكر")) return "male";
        if (s.equals("female") || s.equals("f") || s.equals("أنثى") || s.equals("انثى")) return "female";
        return null;
    }

    private boolean isBlank(String v) {
        return v == null || v.trim().isEmpty();
    }
}