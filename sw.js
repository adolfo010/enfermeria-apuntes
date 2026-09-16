// Service Worker mínimo: solo existe para poder recibir lo que WhatsApp
// (u otra app) comparte con "Enfermería Roxy" a través del menú nativo de Android.

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  if (event.request.method === "POST" && url.pathname === "/share-target/") {
    event.respondWith(handleShare(event.request));
    return;
  }
  // Todo lo demás pasa directo a la red, sin cachear (la app necesita datos en vivo).
});

async function handleShare(request) {
  try {
    const formData = await request.formData();
    const files = formData.getAll("file");
    const cache = await caches.open("share-cache-v1");

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      await cache.put(
        "/__shared-file-" + i,
        new Response(file, {
          headers: {
            "Content-Type": file.type || "application/octet-stream",
            "X-File-Name": encodeURIComponent(file.name || "archivo"),
          },
        })
      );
    }
    await cache.put("/__shared-file-count", new Response(String(files.length)));
  } catch (e) {
    // si algo falla, igual redirigimos; la página mostrará que no llegó nada
  }
  return Response.redirect("/?share=1", 303);
}
