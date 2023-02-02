"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dns = void 0;
const boot_cjs_1 = require("./sys/boot.cjs");
const dns_cjs_1 = require("./sys/dns.cjs");
const js_process_cjs_1 = require("./sys/js-process.cjs");
const localhost_cjs_1 = require("./sys/localhost.cjs");
const multi_webview_mobile_cjs_1 = require("./sys/multi-webview.mobile.cjs");
exports.dns = new dns_cjs_1.DnsNMM();
exports.dns.install(new boot_cjs_1.BootNMM());
exports.dns.install(new multi_webview_mobile_cjs_1.MultiWebviewNMM());
exports.dns.install(new js_process_cjs_1.JsProcessNMM());
exports.dns.install(new localhost_cjs_1.LocalhostNMM());
const desktop_main_cjs_1 = require("./user/desktop/desktop.main.cjs");
exports.dns.install(desktop_main_cjs_1.desktopJmm);
Object.assign(globalThis, { dns: exports.dns });
console.log("location.href", location.href);
