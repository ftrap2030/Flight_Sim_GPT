/* Serve the engine compressed without depending on host-specific gzip headers.
 * The scoped fetch adapter intercepts only this game's exact WASM URL.
 * It is removed after the engine has initialized. */
(function (root) {
  'use strict';
  root.MiamiWasmLoader = {
    install(wasmPath) {
      const original = root.fetch;
      const target = new URL(wasmPath, root.location.href);
      root.fetch = async function (input, options) {
        const requested = new URL(typeof input === 'string' || input instanceof URL ? input : input.url, root.location.href);
        if (requested.href !== target.href) return original.call(root, input, options);
        const compressed = await original.call(root, target.href + '.gz', options);
        if (!compressed.ok) throw new Error('The scene download failed (' + compressed.status + ').');
        if (!compressed.body) throw new Error('The scene download was empty.');
        return new Response(compressed.body.pipeThrough(new DecompressionStream('gzip')), {
          headers: {'Content-Type': 'application/wasm'}
        });
      };
      return () => { root.fetch = original; };
    }
  };
})(globalThis);
