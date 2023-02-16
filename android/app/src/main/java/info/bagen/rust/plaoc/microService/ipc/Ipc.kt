package info.bagen.rust.plaoc.microService.ipc

import info.bagen.rust.plaoc.microService.ipc.helper.*

var ipc_uid_acc = 0

abstract class Ipc {
    abstract val supportMessagePack: Boolean
    val uid = ipc_uid_acc++
    val remote:TMicroModule  get() { return  TMicroModule() }
    val role: IPC_ROLE get() { return IPC_ROLE.SERVER }

    val _messageSignal = createSignal<ipcSignal>()
    fun postMessage(message: IpcMessage) {
        if (this._closed) {
            return;
        }
        this._doPostMessage(message);
    }

    abstract fun _doPostMessage(data: IpcMessage): Void;
    private fun _getOnRequestListener(cb: OnIpcRequestMessage): Signal<ipcSignal> {
        val signal = createSignal<ipcSignal>()
        this._messageSignal.listen { args ->
            val request = args[0] as IpcRequest
            val ipc = args[1]  as Ipc
            if (IPC_DATA_TYPE.REQUEST == request.type) {
                signal.emit(request, ipc);
            }
        }
        return signal
    }

   fun onRequest(cb: OnIpcRequestMessage): Signal<ipcSignal> {
        return this._getOnRequestListener(cb);
    }
    abstract fun _doClose(): Void

    private var _closed = false
    fun close() {
        if (this._closed) {
            return;
        }
        this._closed = true;
        this._doClose();
        this._closeSignal.emit(null,null)
    }
    private val _closeSignal = createSignal<ipcSignal>();
    val onMessage = this._messageSignal
    val onClose =  this._closeSignal

    private val _reqresMap = mutableMapOf<Number, IpcResponse>();
    private var _req_id_acc = 0;
    fun allocReqId(): Int {
        return this._req_id_acc++;
    }

    private var _inited_req_res = false;
    private fun _initReqRes() {
        if (this._inited_req_res) {
            return;
        }
        this._inited_req_res = true;
//        this._messageSignal.listen(fun(message){
//            if (IPC_DATA_TYPE.RESPONSE.equals(message.type)) {
//                var response_po = this._reqresMap.get(message.req_id);
//                if (response_po) {
//                    this._reqresMap.delete(message.req_id);
//                    response_po.resolve(message);
//                } else {
//                    throw new Error(`no found response by req_id: ${message.req_id}`);
//                }
//            }
//        });
    }
}


