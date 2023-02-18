/// <reference path="../../sys/js-process/js-process.worker.d.ts"/>

import { IpcHeaders } from "../../core/ipc/IpcHeaders.cjs";
import { IpcResponse } from "../../core/ipc/IpcResponse.cjs";
import { createHttpDwebServer } from "../../sys/http-server/$listenHelper.cjs";
import { CODE as CODE_desktop_web_mjs } from "./assets/browser.web.cjs";
import { CODE as CODE_index_html } from "./assets/index.html.js";

/**
 * 服务器
 */
export const main = async () => {
  debugger;
  /// 申请端口监听，不同的端口会给出不同的域名和控制句柄，控制句柄不要泄露给任何人KWKW
  const { origin, start } = await createHttpDwebServer(jsProcess, {});
  (await start()).onRequest(async (request, httpServerIpc) => {
    if (
      request.parsed_url.pathname === "/" ||
      request.parsed_url.pathname === "/index.html"
    ) {
      /// 收到请求
      httpServerIpc.postMessage(
        IpcResponse.fromText(
          request.req_id,
          200,
          // code_index_html 是第三方的 内容 如何增加状态栏？？
          await CODE_index_html(request),
          new IpcHeaders({
            "Content-Type": "text/html",
          })
        )
      );
    } else if (request.parsed_url.pathname === "/browser.web.mjs") {
      httpServerIpc.postMessage(
        IpcResponse.fromText(
          request.req_id,
          200,
          await CODE_desktop_web_mjs(request),
          new IpcHeaders({
            "Content-Type": "application/javascript",
          })
        )
      );
    } else {
      httpServerIpc.postMessage(
        IpcResponse.fromText(request.req_id, 404, "No Found")
      );
    }
  });

  console.log("http 服务创建成功");
  console.log("打开浏览器页面", origin);
  {
    const view_id = await jsProcess
      .fetch(`file://mwebview.sys.dweb/open?url=${encodeURIComponent(origin)}`)
      .text();
  }
};
main().catch(console.error);
