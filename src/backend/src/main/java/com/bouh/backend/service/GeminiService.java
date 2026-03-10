package com.bouh.backend.service;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * GeminiService — Internal service responsible for communicating with the
 * Google Gemini 1.5 Pro API.
 *
 * This service is a step in the drawing analysis pipeline. It receives a feeling string,
 * sends it to Gemini with a structured prompt, and returns the AI-generated
 * analysis as a plain string.
 *
 * Protocol: HTTP/2 (via OkHttp)
 * Model: gemini-1.5-pro —> chosen for its strong emotional reasoning capability.
 */
@Service
public class GeminiService {

    // Configuration 

    /**
     * Gemini API key injected from application.properties.
     * Key: gemini.api.key
     */
    @Value("${gemini.api.key}")
    private String apiKey;

    /**
     * Full Gemini endpoint URL injected from application.properties.
     * Key: gemini.api.url
     * Points to the generateContent endpoint for gemini-2.5-
     */
    @Value("${gemini.api.url}")
    private String apiUrl;

    // Gemini System Instructions.
    private static final String SYSTEM_INSTRUCTION =
            "أنتِ أخصائية في علم نفس الطفل، تتمتعين بخبرة في تفسير مشاعر الأطفال بطريقة دافئة وداعمة.\n"
                    + "مهمتك هي مساعدة مقدمي الرعاية (الوالدين أو المربين) على فهم مشاعر الطفل بناءً على تحليل رسوماته، وذلك بتقديم تفسير عاطفي لطيف يتبعه نصيحة عملية واحدة.\n"
                    + "التزمي بالقواعد التالية بصرامة:\n"
                    + "استخدمي لغة عربية فصحى مبسّطة، دافئة، ومطمئنة.\n"
                    + "لا تقدّمي أي تشخيص طبي أو نفسي أبدًا.\n"
                    + "لا تستخدمي مصطلحات تقنية أو أكاديمية معقدة.\n"
                    + "لا تُصدري أي أحكام على الطفل أو على مقدّم الرعاية.\n"
                    + "لا تذكري أنكِ ذكاء اصطناعي أو نموذج لغوي.\n"
                    + "قدّمي جميع التفسيرات العاطفية كاحتمالات وليس كحقائق مؤكدة. استخدمي صياغات مثل \"قد يكون الطفل يشعر بـ...\" أو \"ربما يعبّر عن...\" بدلاً من \"الطفل يشعر بـ...\".\n"
                    + "اكتبي الرد كفقرة واحدة متصلة بدون ترقيم أو عناوين فرعية.\n"
                    + "لا تقدمي نصائح إلا إذا كانت تستند إلى معرفة موثوقة ومقبولة على نطاق واسع في علم نفس الطفل، وتجنبي التوصيات غير الموثوقة أو غير المدعومة.\n"
                    + "اجعلي الرد قصيرًا: من ٣ إلى ٥ جمل كحد أقصى.";

    // Gemini user prompt template. Placeholder {emotion} is replaced with the detected emotion before sending.
    private static final String USER_PROMPT_TEMPLATE =
            "تم تحليل رسمة طفل باستخدام نموذج تعلّم آلي، وتم تصنيف المشاعر المُعبَّر عنها في الرسمة على أنها: {emotion}\n"
                    + "بناءً على هذه المشاعر المكتشفة، قدّمي لمقدّم الرعاية تفسيرًا عاطفيًا قصيرًا ولطيفًا لما قد يشعر به الطفل، متبوعًا بنصيحة عملية وداعمة واحدة للتعامل مع هذا الشعور.";

    // Gemini generation options.
    // Controls how creative the answer is (higher = more variety).
    private static final double TEMPERATURE = 0.6;
    // Controls sampling diversity using probability mass (top-p sampling).
    private static final double TOP_P = 0.9;
    // Controls how many tokens Gemini considers when sampling.
    private static final int TOP_K = 40;
    // Limits how long Gemini can reply.
    private static final int MAX_OUTPUT_TOKENS = 1024;

    // HTTP Client 

    /**
     * OkHttpClient configured to use HTTP/2 as the preferred protocol.
     *
     * Why OkHttp?
     * - Native HTTP/2 support 
     * - Spring's default RestTemplate does not support HTTP/2 natively
     *
     * Timeouts:
     * - connectTimeout: time to establish the TCP connection
     * - readTimeout: time to wait for Gemini to return a response (set higher because
     *   Gemini 1.5 Pro can take several seconds for deep analysis)
     * - writeTimeout: time to finish sending the request body
     */
    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .protocols(List.of(Protocol.HTTP_2, Protocol.HTTP_1_1)) // HTTP/2 but fallback to HTTP/1.1 if needed 
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    /**
     * Jackson ObjectMapper for:
     * 1. Serializing the request body (Map → JSON string)
     * 2. Deserializing the Gemini response (JSON string → JsonNode tree)
     *
     * Reused as a single instance for performance (ObjectMapper is thread-safe).
     */
    private final ObjectMapper objectMapper = new ObjectMapper();

    //Public API 

    /**
     * Analyzes a child's expressed feeling using Gemini 1.5 Pro.
     *
     * Flow:
     *   feeling (String)
     *     → prompt construction       [Later we will replace this with real prompt]
     *     → JSON request body built   [buildRequestBody()]
     *     → HTTP/2 POST to Gemini     [OkHttp]
     *     → raw JSON response
     *     → text extracted            [parseGeminiResponse()]
     *     → result (String)
     *
     * @param feeling The feeling string from our model
     *                Example: "happy", "sad", "angry"
     * @return The Gemini-generated analysis as a plain string.
     * @throws RuntimeException if the Gemini API returns a non-2xx status.
     * @throws IOException      if the request fails or response parsing fails.
     */
    public String analyzeFeeling(String feeling) throws IOException {

        // Build the user prompt by putting the detected emotion into the template
        String userPrompt = buildUserPrompt(feeling);

        // Serialize the prompt into the JSON structure Gemini expects
        String requestBodyJson = buildRequestBody(userPrompt);

        // Gemini authenticates via API key as a URL query parameter
        String fullUrl = apiUrl + "?key=" + apiKey;

        // Wrap the JSON string into an OkHttp RequestBody with the correct media type
        RequestBody body = RequestBody.create(
                requestBodyJson,
                MediaType.parse("application/json; charset=utf-8")
        );

        // Build the HTTP POST request
        Request request = new Request.Builder()
                .url(fullUrl)
                .post(body)
                .header("Content-Type", "application/json")
                .build();

        // Execute the request
        try (Response response = httpClient.newCall(request).execute()) {

            // If Gemini returns 4xx or 5xx, throw with the status code for easier debugging
            if (!response.isSuccessful()) {
                String errorBody = response.body() != null ? response.body().string() : "";
                throw new RuntimeException(
                        "Gemini API call failed. HTTP status: " + response.code() + (errorBody.isEmpty() ? "" : " — " + errorBody)
                );
            }

            // Read the full response body as a string
            String responseBody = response.body().string();

            // Navigate the JSON tree and extract just the generated text
            return parseGeminiResponse(responseBody);
        }
    }

    //Helpers

    /**
     * Builds the JSON request body required by the Gemini generateContent endpoint.
     *
     * Gemini expects this exact structure:
     * {
     *   "contents": [
     *     {
     *       "parts": [
     *         { "text": "your prompt here" }
     *       ]
     *     }
     *   ]
     * }
     *
     *
     * @param userPrompt The user prompt string to send to Gemini.
     * @return A valid JSON string ready to be used as the HTTP request body.
     * @throws JsonProcessingException if Jackson fails to serialize the map 
     */
    private String buildRequestBody(String userPrompt) throws JsonProcessingException {
        // System instruction message.
        Map<String, Object> systemInstructionPart = Map.of("text", SYSTEM_INSTRUCTION);
        Map<String, Object> systemInstructionMap = Map.of("parts", List.of(systemInstructionPart));

        // User prompt message.
        Map<String, Object> userTextPart = Map.of("text", userPrompt);
        Map<String, Object> userContent = Map.of(
                "role",
                "user",
                "parts",
                List.of(userTextPart)
        );

        // Gemini generation configuration.
        Map<String, Object> generationConfig = Map.of(
                "temperature",
                TEMPERATURE,
                "topP",
                TOP_P,
                "topK",
                TOP_K,
                "maxOutputTokens",
                MAX_OUTPUT_TOKENS
        );

        // contents = user prompt message, config = systemInstruction + generationConfig
        Map<String, Object> requestMap = Map.of(
                "systemInstruction",
                systemInstructionMap,
                "contents",
                List.of(userContent),
                "generationConfig",
                generationConfig
        );

        return objectMapper.writeValueAsString(requestMap);
    }

    /**
     * Builds the user prompt by injecting the emotion into the template.
     *
     * @param emotion The emotion detected from the drawing analysis model.
     * @return A ready-to-send user prompt.
     */
    private String buildUserPrompt(String emotion) {
        return USER_PROMPT_TEMPLATE.replace("{emotion}", emotion == null ? "" : emotion);
    }

    /**
     * Parses the Gemini API JSON response and extracts the generated text.
     *
     * Gemini response structure:
     * {
     *   "candidates": [
     *     {
     *       "content": {
     *         "parts": [
     *           { "text": "RESULT HERE" }   ← this is what we extract
     *         ]
     *       }
     *     }
     *   ]
     * }
     *
     * We always take candidates[0] (the first and primary candidate).
     * Gemini returns only one candidate by default unless explicitly configured otherwise.
     *
     * @param responseBody The raw JSON string returned by Gemini.
     * @return The extracted analysis text string.
     * @throws IOException if Jackson fails to parse the response JSON.
     */
    private String parseGeminiResponse(String responseBody) throws IOException {
        JsonNode root = objectMapper.readTree(responseBody);

        return root
                .path("candidates")  // top-level array of response candidates
                .get(0)              // take the first (and usually only) candidate
                .path("content")     // content object inside the candidate
                .path("parts")       // array of content parts
                .get(0)              // take the first part
                .path("text")        // the actual generated text
                .asText();           // return as plain Java String
    }
}
