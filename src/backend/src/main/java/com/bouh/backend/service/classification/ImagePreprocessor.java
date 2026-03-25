package com.bouh.backend.service.classification;
import org.springframework.stereotype.Service;
import com.bouh.backend.service.GcsImageService;
import lombok.extern.slf4j.Slf4j;
import java.awt.image.BufferedImage;
import java.awt.Graphics2D;
import java.awt.Image;

/**
 * ImagePreprocessor
 *
 * Responsible for preparing images for the ConvNeXt model.
 * Applies the same transformations used during model training upon the
 * validation set
 */

@Slf4j
@Service
public class ImagePreprocessor {

    // Model input size
    private static final int IMG_SIZE = 224;

    // Resize before center crop (224 * 1.14 ≈ 255)
    private static final int RESIZE = (int) (IMG_SIZE * 1.14);

    // Normalization values from ImageNet used by the ConvNeXt model
    private static final float[] MEAN = { 0.485f, 0.456f, 0.406f };
    private static final float[] STD = { 0.229f, 0.224f, 0.225f };

   private final GcsImageService gcsImageService;

public ImagePreprocessor(GcsImageService gcsImageService) {
    this.gcsImageService = gcsImageService;
}

    /**
     * Step 1: Download image from Google Cloud Storage
     */
    public BufferedImage downloadDrawing(String imagePath) throws Exception {
        return gcsImageService.downloadImage(imagePath);
    }

    /**
     * Step 2: Preprocess image into model tensor
     * (Resize → CenterCrop → Normalize → CHW tensor)
     */
    public float[] preprocess(BufferedImage image) {

        // Resize
        Image tmp = image.getScaledInstance(RESIZE, RESIZE, Image.SCALE_SMOOTH);
        BufferedImage resized = new BufferedImage(RESIZE, RESIZE, BufferedImage.TYPE_INT_RGB);

        Graphics2D g2d = resized.createGraphics();
        g2d.drawImage(tmp, 0, 0, null);
        g2d.dispose();

        // CenterCrop
        int startX = (RESIZE - IMG_SIZE) / 2;
        int startY = (RESIZE - IMG_SIZE) / 2;

        BufferedImage cropped = resized.getSubimage(startX, startY, IMG_SIZE, IMG_SIZE);

        // Create tensor in CHW format
        float[] tensor = new float[3 * IMG_SIZE * IMG_SIZE];

        int rIndex = 0;
        int gIndex = IMG_SIZE * IMG_SIZE;
        int bIndex = 2 * IMG_SIZE * IMG_SIZE;

        for (int y = 0; y < IMG_SIZE; y++) {
            for (int x = 0; x < IMG_SIZE; x++) {

                int rgb = cropped.getRGB(x, y);

                float r = ((rgb >> 16) & 0xFF) / 255f;
                float g = ((rgb >> 8) & 0xFF) / 255f;
                float b = (rgb & 0xFF) / 255f;

                tensor[rIndex++] = (r - MEAN[0]) / STD[0];
                tensor[gIndex++] = (g - MEAN[1]) / STD[1];
                tensor[bIndex++] = (b - MEAN[2]) / STD[2];
            }
        }
        float min = Float.MAX_VALUE;
        float max = Float.MIN_VALUE;

        for (float v : tensor) {
            min = Math.min(min, v);
            max = Math.max(max, v);
        }

        log.info("[[.. tensor size: " + tensor.length + " ..]]");

        return tensor;
    }
}