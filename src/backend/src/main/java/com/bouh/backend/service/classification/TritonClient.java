package com.bouh.backend.service.classification;

import io.grpc.ManagedChannel;
import lombok.extern.slf4j.Slf4j;
import inference.GRPCInferenceServiceGrpc;
import inference.GrpcService.ModelInferRequest;
import inference.GrpcService.ModelInferResponse;
import java.nio.ByteBuffer;
import inference.GrpcService;
import java.nio.ByteOrder;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Service;

/*
 * TritonClient
 *
 * Responsible for communicating with the Triton Inference Server
 * through gRPC. This class sends a preprocessed tensor to the model
 * and retrieves the predicted logits.
 */
@Slf4j
@Service
public class TritonClient {

        private final GRPCInferenceServiceGrpc.GRPCInferenceServiceBlockingStub stub;

        public TritonClient(ManagedChannel channel){
                // Create Triton stub
                this.stub = GRPCInferenceServiceGrpc.newBlockingStub(channel);
        }

        /*
         * Sends an image tensor to Triton and retrieves model predictions as logits.
         *
         * Input:
         * tensor -> float[150528] representing a preprocessed image
         * in CHW format (3x224x224)
         *
         * Output:
         * logits -> float[5] model raw outputs
         */
        public float[] predict(float[] tensor) {
                long startTime = System.currentTimeMillis();

                /*
                 * Step 1
                 * Convert the float tensor into raw bytes.
                 *
                 * Triton gRPC expects binary tensor data.
                 * Each float = 4 bytes.
                 *
                 * Optimized:
                 * - Uses direct buffer for faster native I/O
                 * - Avoids manual loop (much faster conversion)
                 */
                ByteBuffer buffer = ByteBuffer
                                .allocateDirect(tensor.length * 4)
                                .order(ByteOrder.LITTLE_ENDIAN);

                buffer.asFloatBuffer().put(tensor);

                /*
                 * Step 2
                 * Create the input tensor description.
                 *
                 * This must match the Triton model configuration:
                 *
                 * name: "image"
                 * datatype: FP32
                 * shape: [1,3,224,224]
                 */
                GrpcService.ModelInferRequest.InferInputTensor inputTensor =
                                GrpcService.ModelInferRequest.InferInputTensor
                                .newBuilder()
                                .setName("image")
                                .setDatatype("FP32")
                                .addShape(1)
                                .addShape(3)
                                .addShape(224)
                                .addShape(224)
                                .build();

                /*
                 * Step 3
                 * Define which output we want from the model.
                 *
                 * According to config.pbtxt:
                 *
                 * output name = "logits"
                 */
                ModelInferRequest.InferRequestedOutputTensor outputTensor =
                                ModelInferRequest.InferRequestedOutputTensor
                                .newBuilder()
                                .setName("logits")
                                .build();

                /*
                 * Step 4
                 * Build the full inference request.
                 *
                 * model_name must match the Triton model repository folder.
                 */
                ModelInferRequest request = ModelInferRequest.newBuilder()
                                .setModelName("bouh_classifier")
                                .addInputs(inputTensor)
                                .addOutputs(outputTensor)
                                .addRawInputContents(
                                                com.google.protobuf.ByteString.copyFrom(buffer))
                                .build();

                /*
                 * Step 5
                 * Send the request to Triton and wait for the response.
                 *
                 * Optimized:
                 * - Tightened deadline for faster failure handling
                 * - Compression removed (small tensors → compression overhead > benefit)
                 */
                long t_beforeGrpc = System.currentTimeMillis();

                ModelInferResponse response = stub
                                .withCompression("gzip")
                                .withDeadlineAfter(2, TimeUnit.SECONDS) //for effeciny deadline response of 2 sec
                                .modelInfer(request);
                                
                long t_afterGrpc = System.currentTimeMillis();
                log.info("--gRPC call took: " + (t_afterGrpc - t_beforeGrpc) + " ms");

                /*
                 * Step 6
                 * Extract the returned logits from the response.
                 *
                 * Output shape is [1,5] (batch=1, classes=5).
                 *
                 * Optimized:
                 * - Uses bulk float read instead of manual loop
                 */
                float[] logits = new float[5];

                ByteBuffer outputBuffer = response
                                .getRawOutputContents(0)
                                .asReadOnlyByteBuffer()
                                .order(ByteOrder.LITTLE_ENDIAN);

                outputBuffer.asFloatBuffer().get(logits);

                /*
                 * Step 7
                 * Return the model raw logits (not probability or labels yet).
                 */
                long endTime = System.currentTimeMillis();
                long duration = endTime - startTime;
                log.info("[[[. . Classifier took {{ "+duration+" }} ms to respond . .]]]");                              

                return logits;
        }
}