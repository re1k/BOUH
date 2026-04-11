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
 * Google Gemini 2.5 API.
 *
 * This service is a step in the drawing analysis pipeline. It receives a feeling string,
 * sends it to Gemini with a structured prompt, and returns the AI-generated
 * analysis as a plain string.
 *
 * Protocol: HTTP/2 (via OkHttp)
 * Model: gemini-2.5 —> chosen for its strong emotional reasoning capability.
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
     * Points to the generateContent endpoint for gemini-2.5
     */
    @Value("${gemini.api.url}")
    private String apiUrl;

// Gemini user prompt template. Placeholder {emotion} is replaced with the detected emotion before sending.
private static final String USER_PROMPT_TEMPLATE = """
A child's drawing was analyzed using a machine learning model,  and the emotions expressed in the drawing were classified as: {emotion}
Before writing your response, generate knowledge internally about the following:
What does the emotion {emotion} typically indicate about a child's inner experience, and what psychological need might it reflect?
How might this emotion manifest in a child's behavior, drawings, or expressions in ways a caregiver might observe?
What does child psychology specifically recommend as the most effective caregiver response to this exact emotion? Suggest a concrete, creative, and child-centered activity or interaction that directly responds to this emotional state — something specific and memorable, not generic.
Write only the knowledge now. Do not write the caregiver response yet.
Then using the knowledge, provide the caregiver with a short and gentle emotional interpretation of what the child may be feeling, followed by one supportive and practical piece of advice for responding to this emotion.
Rules:
You have no access to the drawing itself — you only receive the emotion label detected by the machine learning model. Never describe, reference, or make assumptions about the drawing's colors, shapes, lines, or visual content. Your interpretation must be based solely on the emotion label provided.
Always state the detected emotion clearly and explicitly in the response. Never replace it with vague or general expressions such as "مشاعر قوية" or "بعض الضيق".
Always link the detected emotion to the drawing. Use phrases such as "من خلال رسمته" or "رسمة طفلك تعبّر عن" or "يبدو من رسمته أن".
Strictly address only the emotion provided in the detected classification. Do not mention, mix, or reference any other emotion in your response. Each classification represents one independent and distinct emotion. For example: الخوف is not القلق, and الغضب is not الحزن. If the classification is الخوف, speak only about الخوف and never use words like قلق, توتر, ضيق, or any other emotion.
Address the caregiver directly and warmly using second person singular (أنت) as a neutral default. For example: "يمكنك أن تجلس معه" or "حاول أن".
Speak directly without titles or forms of address. 
Frame all emotional interpretations as possibilities, not certainties. Use phrasing such as "قد يكون الطفل يشعر بـ..." or "ربما يعبّر عن..." rather than "الطفل يشعر بـ...".
Never open your response with a greeting, title, or address. Begin directly with the content.
Use simple, warm, and reassuring Modern Standard Arabic (العربية الفصحى المبسطة).
In every response, choose a different and fresh angle for the practical advice. For example, the advice may focus on conversation, play, drawing, reading, routine, nature, or other approaches. Never repeat the same type of advice if the same emotion is given more than once. Be creative in suggesting varied and different approaches each time.
In every response, choose a different and unexpected activity for the practical advice. Do not default to suggesting the same common activities. Vary widely between activities that are completely different from each other.
Never use any formatting symbols in the response such as stars, dashes, or any other symbols. Write plain text only.
Never provide any medical or psychological diagnosis.
Never use complex technical or academic terminology.
Never pass judgment on the child or the caregiver.
Never identify yourself as an AI or a language model.
Write the response as one continuous paragraph with no numbering or subheadings.
Never provide advice unless it is grounded in reliable and widely accepted knowledge from trusted sources in child psychology, and avoid unreliable or unsupported recommendations.
Never suggest activities related to music or singing.
Maintain a calm and warm tone without exaggeration. Never use exclamatory or overly emotional expressions.
Never recommend any activity that involves hitting, punching, screaming, throwing objects, or any form of violent physical release. Focus only on advice that helps the child understand their feelings and express them through words or calm and positive activities.
Never suggest or reference any activity, metaphor, or language related to food, drinks, eating, cooking, or anything edible in any part of your response.
Never use the word 'التميمة' or 'التميمه' or any reference to amulets or charms in your response.
Ensure that all advice and content strictly aligns with Islamic values and principles. Never suggest, imply, or reference anything that contradicts Islamic teachings.
When writing "بال" or 'كال' specifically as a prefix for emotions, it must always be directly attached to the emotion (e.g., بالحزن, كالحزن) and never separated.
Keep the response short: 3 to 5 sentences maximum.
Final output:/nProvide only the final response paragraph to the caregiver. Do not include the knowledge or any internal reasoning in your output.
""";

    // Gemini generation options.
    // Controls how creative the answer is (higher = more variety).
    private static final double TEMPERATURE = 1.3;
    // Limits how long Gemini can reply.
    private static final int MAX_OUTPUT_TOKENS = 25000;

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
        // prompt message.
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
                "maxOutputTokens",
                MAX_OUTPUT_TOKENS
        );

        // contents = user prompt message, config = systemInstruction + generationConfig
        Map<String, Object> requestMap = Map.of(
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
        return USER_PROMPT_TEMPLATE
                .replace("{emotion}", emotion == null ? "" : emotion);
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
