importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js')
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js')

firebase.initializeApp({
  apiKey: "AIzaSyCk77lSKIwwlhP4ix7-0XJoi6LgoCVrsFE",
  authDomain: "sos-besoin.firebaseapp.com",
  projectId: "sos-besoin",
  storageBucket: "sos-besoin.firebasestorage.app",
  messagingSenderId: "379256786062",
  appId: "1:379256786062:web:4243e2df5d9efe80310ddf",
})

const messaging = firebase.messaging()

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification || {}
  self.registration.showNotification(title || 'SOS-BESOIN', {
    body,
    icon: '/next.svg',
    data: payload.data,
  })
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  const requestId = event.notification.data?.request_id
  const url = requestId ? `/requests/${requestId}` : '/'
  event.waitUntil(clients.openWindow(url))
})
