package com.bouh.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration //read by SB before running the tomcat server
public class FirebaseConfig {

    @Bean //Firebase Application Instance to use any service by FB
    public FirebaseApp firebaseApp() throws IOException {

        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance(); //only create if not exist
        }

        //Load .env
        Dotenv dotenv = Dotenv.configure()
                .directory("./")
                .ignoreIfMissing() //to prevent the server from crashing if not exist
                .load();

        String credentialsPath = dotenv.get("FIREBASE_SERVICE_ACCOUNT_PATH");
        System.out.println(" Firebase credentials path = " + credentialsPath);

        if (credentialsPath == null) {
            throw new RuntimeException("FIREBASE_SERVICE_ACCOUNT_PATH not found in .env"); //stop the exec if not exist, prevent app running with no database setted
        }

        FileInputStream serviceAccount = new FileInputStream(credentialsPath);

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build(); //create the service account and trust it

        return FirebaseApp.initializeApp(options); //run the instance
    }

    @Bean
    public Firestore firestore(FirebaseApp app) {
        return FirestoreClient.getFirestore(app);
    } //making an instance available for the Dev env

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}