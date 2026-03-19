package com.bouh.backend.service.classification;
import org.springframework.stereotype.Service;

@Service
public class PredictionMapper {

    // Emotion labels, matching training class order
    private static final String[] CLASSES = {
            "تفاؤل",
            "حزن",
            "غضب",
            "خوف",
            "توتر وقلق"
    };

    /**
     * Convert logits -> probabilities using softmax
     */
    public static float[] softmax(float[] logits) {

        float max = Float.NEGATIVE_INFINITY;

        // Step 1: numerical stability
        for (float v : logits) {
            if (v > max)
                max = v;
        }

        float sum = 0f;
        float[] exp = new float[logits.length];

        // Step 2: exponentiate
        for (int i = 0; i < logits.length; i++) {
            exp[i] = (float) Math.exp(logits[i] - max);
            sum += exp[i];
        }

        // Step 3: normalize
        for (int i = 0; i < exp.length; i++) {
            exp[i] = exp[i] / sum;
        }

        return exp;
    }

    /**
     * Convert logits -> label
     */
    public static String getPrediction(float[] logits) {

        float[] probabilities = softmax(logits);

        int bestIndex = 0;
        float bestValue = probabilities[0];

        for (int i = 1; i < probabilities.length; i++) {
            if (probabilities[i] > bestValue) {
                bestValue = probabilities[i];
                bestIndex = i;
            }
        }

        return CLASSES[bestIndex];
    }
}