{{flutter_js}}
{{flutter_build_config}}

const renderer = new URLSearchParams(location.search).get('renderer');
const config = {canvasKitBaseUrl: 'canvaskit/'};
if (renderer === 'skwasm' || renderer === 'canvaskit') {
  config.renderer = renderer;
}
_flutter.loader.load({config});
