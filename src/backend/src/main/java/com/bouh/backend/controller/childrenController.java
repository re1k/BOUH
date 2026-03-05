package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.childDto;
import com.bouh.backend.model.Dto.ChildRequestDto;
import com.bouh.backend.service.ChildrenService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class childrenController {

    private final ChildrenService childrenService;

    public childrenController(ChildrenService childrenService) {
        this.childrenService = childrenService;
    }

    /**
     * Caregiver - get all children in account
     * GET /api/caregiver/{caregiverId}/children
     */
    @GetMapping(value = "/caregiver/{caregiverId}/children", produces = "application/json")
    public ResponseEntity<List<childDto>> getChildren(@PathVariable String caregiverId) throws Exception {
        return ResponseEntity.ok(childrenService.getChildren(caregiverId));
    }

    /**
     * Caregiver - add child (max 5)
     * POST /api/caregiver/{caregiverId}/children
     */
    @PostMapping(value = "/caregiver/{caregiverId}/children", produces = "application/json")
    public ResponseEntity<childDto> addChild(
            @PathVariable String caregiverId,
            @RequestBody ChildRequestDto request
    ) throws Exception {
        return ResponseEntity.status(201).body(childrenService.addChild(caregiverId, request));
    }

    /**
     * Caregiver - edit child profile
     * PUT /api/caregiver/{caregiverId}/children/{childId}
     */
    @PutMapping(value = "/caregiver/{caregiverId}/children/{childId}", produces = "application/json")
    public ResponseEntity<childDto> updateChild(
            @PathVariable String caregiverId,
            @PathVariable String childId,
            @RequestBody ChildRequestDto request
    ) throws Exception {
        return ResponseEntity.ok(childrenService.updateChild(caregiverId, childId, request));
    }

    /**
     * Caregiver - delete child only if more than 1 child exists
     * DELETE /api/caregiver/{caregiverId}/children/{childId}
     */
    @DeleteMapping(value = "/caregiver/{caregiverId}/children/{childId}", produces = "application/json")
    public ResponseEntity<String> deleteChild(
            @PathVariable String caregiverId,
            @PathVariable String childId
    ) throws Exception {
        childrenService.deleteChild(caregiverId, childId);
        return ResponseEntity.ok("Child deleted");
    }
}