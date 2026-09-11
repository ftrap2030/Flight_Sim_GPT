import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {gunzipSync} from 'node:zlib';
const dir=process.argv[2];
const html=fs.readFileSync(path.join(dir,'index.html'),'utf8');
assert(!html.includes('$GODOT_'),'Unexpanded export placeholders');
for(const match of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)) if(match[1].trim()) new vm.Script(match[1]);
for(const match of html.matchAll(/<script src="([^"]+)"/g)) {
 const file=path.join(dir,match[1]); assert(fs.existsSync(file));new vm.Script(fs.readFileSync(file,'utf8'));
}
const compressed=fs.readFileSync(path.join(dir,'index.wasm.gz'));
const requests=[];
globalThis.location={href:'https://miami.example/index.html'};
const fetchStub=async(input)=>{requests.push(String(input));return new Response(compressed);};
globalThis.fetch=fetchStub;
vm.runInThisContext(fs.readFileSync(path.join(dir,'wasm-loader.js'),'utf8'));
const restore=MiamiWasmLoader.install('index.wasm');
const response=await fetch('index.wasm');
assert.equal(response.headers.get('content-type'),'application/wasm');
const bytes=Buffer.from(await response.arrayBuffer());
assert.deepEqual(bytes,gunzipSync(compressed));
await WebAssembly.compile(bytes);
assert.equal(requests[0],'https://miami.example/index.wasm.gz');
await fetch('index.pck');assert.equal(requests[1],'index.pck');
restore();assert.equal(globalThis.fetch,fetchStub);
assert(fs.statSync(path.join(dir,'index.pck')).size>1000);
console.log('Web export passed: HTML/JS syntax, files, gzip streaming loader, WASM compilation, fetch restoration.');
