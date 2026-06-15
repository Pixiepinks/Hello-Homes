window._flutter = window._flutter || {
  loader: {
    load: function (options) {
      var onEntrypointLoaded = options && options.onEntrypointLoaded;
      var script = document.createElement('script');
      script.src = 'main.dart.js';
      script.defer = true;
      if (typeof onEntrypointLoaded === 'function') {
        script.onload = function () {
          onEntrypointLoaded({ initializeEngine: function () { return Promise.resolve({ runApp: function () {} }); } });
        };
      }
      document.body.appendChild(script);
    }
  }
};
