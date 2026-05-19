importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Gunakan konfigurasi web dari firebase_options.dart Anda
firebase.initializeApp({
  apiKey: "AIzaSyBq-GNn9kd8BUMFsXnxLcoVbmHV6fOOOAc",
  authDomain: "notes-f5ed5.firebaseapp.com",
  projectId: "notes-f5ed5",
  storageBucket: "notes-f5ed5.firebasestorage.app",
  messagingSenderId: "745751160367",
  appId: "1:745751160367:web:8018393a492dd07d3a88da",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png",
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
