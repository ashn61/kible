{{flutter_js}}
{{flutter_build_config}}

// Flutter'ı tam sayfa yerine güvenli alana (safe area) oturtulmuş #app
// kutusunda çalıştır. iOS'ta ana ekrana eklenen uygulamada (standalone)
// durum çubuğu / ana ekran çizgisi ile dokunuş koordinatları kaymaz ve alt
// menü ana ekran çizgisinin üstünde kalır.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.getElementById("app"),
    });
    await appRunner.runApp();
  },
});
