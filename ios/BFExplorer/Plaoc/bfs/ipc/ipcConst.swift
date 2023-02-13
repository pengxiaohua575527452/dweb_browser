//
//  ipcConst.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

//enum IPC_DATA_TYPE: Int {
//    /** 类型：请求 */
//    case request = 0
//    /** 类型：响应 */
//    case response = 1
//    /** 类型：流数据，发送方 */
//    case stream_data = 2
//    /** 类型：流拉取，请求方 */
//    case stream_pull = 3
//    /** 类型：流关闭，发送方
//     *  可能是发送完成了，也可能是中断了
//     */
//    case stream_end = 4
//    /** 类型：流中断，请求方 */
//    case stream_abort = 5
//}
//
//// 位移枚举
//struct IPC_RAW_BODY_TYPE: OptionSet {
//    let rawValue: Int
//    /** 文本 json html 等 */
//    static let text = IPC_RAW_BODY_TYPE(rawValue: 2)
//    /** 使用文本表示的二进制 */
//    static let base64 = IPC_RAW_BODY_TYPE(rawValue: 4)
//    /** 二进制 */
//    static let binary = IPC_RAW_BODY_TYPE(rawValue: 8)
//    /** 流 */
//    static let stream_id = IPC_RAW_BODY_TYPE(rawValue: 16)
//    /** 文本流 */
//    static let text_stream_id = IPC_RAW_BODY_TYPE(rawValue: 18)
//    /** 文本二进制流 */
//    static let base64_stream_id = IPC_RAW_BODY_TYPE(rawValue: 20)
//    /** 二进制流 */
//    static let binary_stream_id = IPC_RAW_BODY_TYPE(rawValue: 24)
//}
//
//enum IPC_ROLE: String {
//    case server = "server"
//    case client = "client"
//}
//
///** Ipc消息通用协议 */
//protocol IpcMessage {}
//
///** message: 只会有两种类型的数据 */
//typealias OnIpcMessage = (_ message: IpcMessage, _ ipc: Ipc) -> Any
