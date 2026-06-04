importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
   apiKey: 'AIzaSyDRirfv947dPnfZeJg2zsvx86lfD41aM8I',
   authDomain: 'everywhere-9278c.firebaseapp.com',          // e.g. your-project.firebaseapp.com
   databaseURL: 'https://everywhere-9278c-default-rtdb.europe-west1.firebasedatabase.app',
   projectId: 'everywhere-9278c',
   storageBucket: 'everywhere-9278c.firebasestorage.app',    // e.g. your-project.appspot.com
   messagingSenderId: '1030362853538',
   appId: '1:1030362853538:web:a8c970f3ede1edd273e7fb',                // the web appId: 1:...:web:...
   measurementId: 'G-77MH21E76P',

});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload
  );

  const notificationTitle =
      payload.notification?.title ?? "New Notification";

  const notificationOptions = {
    body: payload.notification?.body ?? "",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});