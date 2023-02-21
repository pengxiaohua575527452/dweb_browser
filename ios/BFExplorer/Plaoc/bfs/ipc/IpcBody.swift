//
//  IpcBody.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation
import Vapor

//enum EBody: Codable {
//    case string(String)
//    case data(Data)
//    case stream(InputStream)
//}

class IpcBody{
    var rawBody: RawData
    let ipc: Ipc
    var body: Any

    private var _body_u8a: Data?
    private var _body_stream: InputStream?
    private var _body_text: String?

    init(rawBody: RawData, ipc: Ipc) {
        self.rawBody = rawBody
        self.ipc = ipc
        self.body = rawDataToBody(rawBody: rawBody, ipc: ipc)

        switch body {
        case let data as String:
            self._body_text = data
        case let data as Data:
            self._body_u8a = data
        case let data as InputStream:
            self._body_stream = data
        default:
            fatalError("Invalid body type")
        }
    }

    private lazy var _u8a: Data = {
        if let u8a = self._body_u8a {
            return u8a
        } else if let stream = self._body_stream {
            return Data(reading: stream)
        } else if let text = self._body_text {
            return text.to_b64_data()!
        } else {
            fatalError("invalid body type")
        }
    }()

    func u8a() -> Data {
        return _u8a
    }

    private lazy var _stream: InputStream = {
        if let stream = self._body_stream {
            return stream
        } else if let u8a = self._body_u8a {
            return InputStream(data: u8a)
        } else {
            fatalError("invalid body type")
        }
    }()

    func stream() -> InputStream {
        return _stream
    }

    private lazy var _text: String = {
        if let text = self._body_text {
            return text
        } else if let u8a = self._body_u8a {
            return String(data: u8a, encoding: .utf8)!
        } else {
            fatalError("invalid body type")
        }
    }()

    func text() -> String {
        return _text
    }
}


