"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === 'object' || typeof from === 'function') {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, '__esModule', { value: true }), mod);
var __accessCheck = (obj, member, msg) => {
  if (!member.has(obj))
    throw TypeError('Cannot ' + msg);
};
var __privateGet = (obj, member, getter) => {
  __accessCheck(obj, member, 'read from private field');
  return getter ? getter.call(obj) : member.get(obj);
};
var __privateAdd = (obj, member, value) => {
  if (member.has(obj))
    throw TypeError('Cannot add the same private member more than once');
  member instanceof WeakSet ? member.add(obj) : member.set(obj, value);
};
var __privateSet = (obj, member, value, setter) => {
  __accessCheck(obj, member, 'write to private field');
  setter ? setter.call(obj, value) : member.set(obj, value);
  return value;
};

// src/sys/js-process.worker.cts
var js_process_worker_exports = {};
__export(js_process_worker_exports, {
  installEnv: () => installEnv
});
module.exports = __toCommonJS(js_process_worker_exports);

// src/core/ipc.cts
var _parsed_url;
var IpcRequest = class {
  constructor(req_id, method, url, body, headers) {
    this.req_id = req_id;
    this.method = method;
    this.url = url;
    this.body = body;
    this.headers = headers;
    this.type = 0 /* REQUEST */;
    __privateAdd(this, _parsed_url, void 0);
  }
  get parsed_url() {
    return __privateGet(this, _parsed_url) ?? __privateSet(this, _parsed_url, new URL(this.url));
  }
};
_parsed_url = new WeakMap();
var IpcResponse = class {
  constructor(req_id, statusCode, body, headers) {
    this.req_id = req_id;
    this.statusCode = statusCode;
    this.body = body;
    this.headers = headers;
    this.type = 1 /* RESPONSE */;
  }
};
var ipc_uid_acc = 0;
var Ipc = class {
  constructor() {
    this.uid = ipc_uid_acc++;
  }
};

// src/core/helper.cts
var PromiseOut = class {
  constructor() {
    this.promise = new Promise((resolve, reject) => {
      this.resolve = resolve;
      this.reject = reject;
    });
  }
};
var readRequestAsIpcRequest = async (request_init) => {
  let body = '';
  const method = request_init.method ?? 'GET';
  if (method === 'POST' || method === 'PUT') {
    let buffer;
    if (request_init.body instanceof ReadableStream) {
      const reader = request_init.body.getReader();
      const chunks = [];
      while (true) {
        const item = await reader.read();
        if (item.done) {
          break;
        }
        chunks.push(item.value);
      }
      buffer = Buffer.concat(chunks);
    } else if (request_init.body instanceof Blob) {
      buffer = Buffer.from(await request_init.body.arrayBuffer());
    } else if (ArrayBuffer.isView(request_init.body)) {
      buffer = Buffer.from(
        request_init.body.buffer,
        request_init.body.byteOffset,
        request_init.body.byteLength
      );
    } else if (request_init.body instanceof ArrayBuffer) {
      buffer = Buffer.from(request_init.body);
    } else if (typeof request_init.body === 'string') {
      body = request_init.body;
    } else if (request_init.body) {
      throw new Error(
        'unsupport body type: ' + request_init.body.constructor.name
      );
    }
    if (buffer !== void 0) {
      body = buffer.toString('base64');
    }
  }
  let headers = /* @__PURE__ */ Object.create(null);
  if (request_init.headers) {
    let req_headers;
    if (request_init.headers instanceof Array) {
      req_headers = new Headers(request_init.headers);
    } else if (request_init.headers instanceof Headers) {
      req_headers = request_init.headers;
    } else {
      headers = request_init.headers;
    }
    if (req_headers !== void 0) {
      req_headers.forEach((value, key) => {
        headers[key] = value;
      });
    }
  }
  return { method, body, headers };
};
var normalizeFetchArgs = (url, init) => {
  let _parsed_url2;
  let _request_init = init;
  if (typeof url === 'string') {
    _parsed_url2 = new URL(url);
  } else if (url instanceof Request) {
    _parsed_url2 = new URL(url.url);
    _request_init = url;
  } else if (url instanceof URL) {
    _parsed_url2 = url;
  }
  if (_parsed_url2 === void 0) {
    throw new Error('no found url for fetch');
  }
  const parsed_url = _parsed_url2;
  const request_init = _request_init ?? {};
  return {
    parsed_url,
    request_init
  };
};

// src/core/ipc.native.cts
var $messageToIpcMessage = (data) => {
  let message;
  if (data === 'close') {
    message = data;
  } else if (data.type === 0 /* REQUEST */) {
    message = new IpcRequest(
      data.req_id,
      data.method,
      data.url,
      data.body,
      data.headers
    );
  } else if (data.type === 1 /* RESPONSE */) {
    message = new IpcResponse(
      data.req_id,
      data.statusCode,
      data.body,
      data.headers
    );
  }
  return message;
};

// src/sys/js-process.worker.cts
var installEnv = async () => {
  const reqresMap = /* @__PURE__ */ new Map();
  let req_id = 0;
  const allocReqId = () => req_id++;
  const native_fetch = globalThis.fetch;
  globalThis.fetch = function fetch(url, init) {
    const args = normalizeFetchArgs(url, init);
    const { parsed_url } = args;
    if (parsed_url.protocol === 'file:' && parsed_url.hostname.endsWith('.dweb')) {
      return (async () => {
        const { body, method, headers } = await readRequestAsIpcRequest(
          args.request_init
        );
        const req_id2 = allocReqId();
        const response_po = new PromiseOut();
        reqresMap.set(req_id2, response_po);
      self.addEventListener('message', (event) => {
        if (Array.isArray(event.data) && event.data[0] === 'ipc-response') {
    //      self.dispatchEvent(new MessageEvent('connect', { data: ipc }));
          const message = event.data[1];
            if (message.type === 1 /* RESPONSE */) {
            const res_po = reqresMap.get(message.req_id);
            if (res_po !== void 0) {
               reqresMap.delete(message.req_id);
               res_po.resolve(message);
            }
          }
        }
      });
        self.postMessage(
          new IpcRequest(req_id2, method, parsed_url.href, body, headers)
        );
        const ipc_response = await response_po.promise;
        return new Response(ipc_response.body, {
          headers: ipc_response.headers,
          status: ipc_response.statusCode
        });
      })();
    } else if(parsed_url.protocol === 'http:' && parsed_url.hostname.startsWith('http.sys.dweb')) {
        url = url.replace('http.sys.dweb', 'localhost:22605/http.sys.dweb') + '&mmid=js.sys.dweb';
    }
      
    return native_fetch(url, init);
  };
};
