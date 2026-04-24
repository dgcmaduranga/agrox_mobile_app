importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyA0XVoRrFzFP_3qWFrpDA42J1DSGjPkoYI",
  appId: "1:970280305330:web:6346500485803c13b1025c",
  messagingSenderId: "970280305330",
  projectId: "agrox-08068",
  authDomain: "agrox-08068.firebaseapp.com",
  storageBucket: "agrox-08068.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log("Background message received:", payload);

  const title = payload.notification?.title || "AgroX Risk Alert";
  const options = {
    body: payload.notification?.body || "New crop disease risk detected.",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png"
  };

  self.registration.showNotification(title, options);
});