package com.bouh.backend.service.classification;

import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;
import java.awt.image.BufferedImage;

@Slf4j
@Service
public class ClassificationService {

    private final TritonClient tritonClient; // responsable for the communication gRPC based with the model server
    private final ImagePreprocessor imagePreprocessor; // image preperation before sending to the model

    public ClassificationService(TritonClient tritonClient,
            ImagePreprocessor imagePreprocessor) {
        this.tritonClient = tritonClient;
        this.imagePreprocessor = imagePreprocessor;
    }

    /**
     * Main classification pipeline
     *
     * Steps:
     * 1. download image from google storage
     * 2. Preprocess image into model tensor
     * 3. Send tensor to Triton inference server
     * 4. Receive logits from the model
     * 5. Convert logits to label using PredictionMapper
     */
    public String classify(String imagePath) {

        try {
            // Download image
            long downStart = System.currentTimeMillis();
            BufferedImage image = imagePreprocessor.downloadDrawing(imagePath);
            log.info("[[. . image downloaded . .]]");

            long downEnd = System.currentTimeMillis();
            long duration = downEnd - downStart;
            log.info("[[[. . Image Download took {} ms . .]]]", duration);  

            long TensorStart = System.currentTimeMillis();
            // convert image -> tensor (3x224x224 normalized)
            float[] tensor = imagePreprocessor.preprocess(image);
            // first tensor for validation of correct matching with ConvneXt
            log.info("[[...image is now tensor... " + tensor[1] + " .. ]]");

            long TensorEnd = System.currentTimeMillis();
            duration = TensorEnd - TensorStart;
            log.info("[[[. . Tensor took {} ms . .]]]", duration);  
            
            long startClassify = System.currentTimeMillis();
            // send tensor to Triton server via gRPC
            float[] logits = tritonClient.predict(tensor);
            log.info("[[...returning logits...]]");

            long endClassify = System.currentTimeMillis();
            long total = endClassify - startClassify;
            log.info("[[[. . . gRPC total took {} ms ]]]", total);  

            // map the logits to predication labels
            String label = PredictionMapper.getPrediction(logits);
            log.info("[[...label is... " + label + " ]]");

            return label;
        } catch (Exception e) {
            return "classifier error: "+e;
        }
    }
}