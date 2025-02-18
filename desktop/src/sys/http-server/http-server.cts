import crypto from "node:crypto";
import { ReadableStreamIpc } from "../../core/ipc-web/ReadableStreamIpc.cjs";
import { IPC_ROLE } from "../../core/ipc/const.cjs";
import type { IpcRequest } from "../../core/ipc/IpcRequest.cjs";
import { NativeMicroModule } from "../../core/micro-module.native.cjs";
import type { $ReqMatcher } from "../../helper/$ReqMatcher.cjs";
import { defaultErrorResponse } from "./defaultErrorResponse.cjs";
import type { $GetHostOptions } from "./net/createNetServer.cjs";
import { Http1Server } from "./net/Http1Server.cjs";
import { PortListener } from "./portListener.cjs";

interface $Gateway {
  listener: PortListener;
  host: string;
  token: string;
}
/**
 * 类似 https.createServer
 * 差别在于服务只在本地运作
 */
export class HttpServerNMM extends NativeMicroModule {
  mmid = `http.sys.dweb` as const;
  private _http1_server = new Http1Server();

  private _tokenMap = new Map</* token */ string, $Gateway>();
  private _gatewayMap = new Map</* host */ string, $Gateway>();

  protected async _bootstrap() {
    const info = await this._http1_server.create();
    info.server.on("request", (req, res) => {
      // console.log('[http-server.cts 接受到了 http 请求：]', req)

      /// 获取 host
      /** 如果有需要，可以内部实现这个 key 为 "*" 的 listener 来提供默认服务 */
      let host = "*";
      if (req.headers.host) {
        host = req.headers.host;
        /// 如果没有端口，补全端口
        if (host.includes(":") === false) {
          host += ":" + info.protocol.port;
        }
      }

      /// 在网关中寻址能够处理该 host 的监听者
      const gateway = this._gatewayMap.get(host);
      if (gateway == undefined) {
        return defaultErrorResponse(
          req,
          res,
          502,
          "Bad Gateway",
          "作为网关或者代理工作的服务器尝试执行请求时，从远程服务器接收到了一个无效的响应"
        );
      }
      // gateway.listener.ipc.request("/on-connect")

      // const gateway_timeout = setTimeout(() => {
      //   if (res.writableLength === 0) {
      //   }
      //   res.write;
      //   res.hasHeader;
      // }, 3e4 /* 30s 没有任何 body 写入的话，认为网关超时 */);
      void gateway.listener.hookHttpRequest(req, res);
    });

    /// 监听 IPC 请求
    this.registerCommonIpcOnMessageHandler({
      pathname: "/start",
      matchMode: "full",
      input: { port: "number?", subdomain: "string?" },
      output: { origin: "string", token: "string" },
      handler: async (args, ipc) => {
        return await this.start({ ipc, ...args });
      },
    });
    this.registerCommonIpcOnMessageHandler({
      pathname: "/close",
      matchMode: "full",
      input: { port: "number?", subdomain: "string?" },
      output: "boolean",
      handler: async (args, ipc) => {
        return await this.close({ ipc, ...args });
      },
    });
    this.registerCommonIpcOnMessageHandler({
      method: "POST",
      pathname: "/listen",
      matchMode: "full",
      input: { token: "string", routes: "object" },
      output: "object",
      handler: async (args, ipc, message) => {
        console.log("收到处理请求的双工通道");
        return this.listen(
          args.token,
          message,
          args.routes as $ReqMatcher[]
        );
      },
    });
  }
  protected _shutdown() {
    this._http1_server.destroy();
  }

  /** 申请监听，获得一个连接地址 */
  private async start(hostOptions: $GetHostOptions) {
    const { ipc } = hostOptions;
    const { host, origin } = this._http1_server.getHost(hostOptions);
    if (this._gatewayMap.has(host)) {
      throw new Error(`already in listen: ${origin}`);
    }
    const listener = new PortListener(ipc, origin, origin);
    /// ipc 在关闭的时候，自动释放所有的绑定
    listener.onDestroy(
      ipc.onClose(() => {
        this.close(hostOptions);
      })
    );

    const token = Buffer.from(
      crypto.getRandomValues(new Uint8Array(64))
    ).toString("base64url");
    const gateway: $Gateway = { listener, host, token };
    this._tokenMap.set(token, gateway);
    this._gatewayMap.set(host, gateway);
    return { token, origin: listener.origin };
  }

  /** 远端监听请求，将提供一个 ReadableStreamIpc 流 */
  private async listen(
    token: string,
    message: IpcRequest,
    routes: $ReqMatcher[]
  ) {
    const gateway = this._tokenMap.get(token);
    if (gateway === undefined) {
      throw new Error(`no gateway with token: ${token}`);
    }
 
    const streamIpc = new ReadableStreamIpc(
      gateway.listener.ipc.remote,
      IPC_ROLE.CLIENT
    );
    void streamIpc.bindIncomeStream(message.stream());

    streamIpc.onClose(
      gateway.listener.addRouter({
        routes,
        streamIpc,
      })
    );
    return new Response(streamIpc.stream, { status: 200 });
  }
  /**
   * 释放监听
   */
  private close(hostOptions: $GetHostOptions) {
    const { host } = this._http1_server.getHost(hostOptions);

    const gateway = this._gatewayMap.get(host);
    if (gateway === undefined) {
      return false;
    }
    this._tokenMap.delete(gateway.token);
    this._gatewayMap.delete(gateway.host);
    /// 执行销毁
    gateway.listener.destroy();

    return true;
  }
}
