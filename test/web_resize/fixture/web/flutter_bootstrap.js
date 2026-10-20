{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
    renderer: new URLSearchParams(location.search).get('renderer') || 'skwasm',
  },
});
