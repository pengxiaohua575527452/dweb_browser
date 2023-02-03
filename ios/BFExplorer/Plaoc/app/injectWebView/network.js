function BFSInstallApp (path) {
    window.webkit.messageHandlers.InstallBFS.postMessage({path:path});
}

function BFSGetConnectChannel(url) {
    console.log("swift#getConnectChannel:",url)
    window.webkit.messageHandlers.getConnectChannel.postMessage({param:url});
}

function BFSPostConnectChannel(url, cmd, buffer) {
    console.log("swift#postConnectChannel: ", url, " cmd: ", cmd, " buffer: ", buffer)
    window.webkit.messageHandlers.postConnectChannel.postMessage({strPath:url, cmd:cmd, buffer:buffer})
}

//const BFSOriginFetch = fetch;
//
//globalThis.fetch = (origin, option) => {
//    let url = new URL(origin)
//
//    if (origin.startsWith("file://") && url.hostname && url.hostname.endsWith(".dweb")) {
//        return BFSGetConnectChannel(origin)
//    }
//
////    if (origin.startsWith("file://")) {
////        return BFSGetConnectChannel(origin)
////    }
//    return BFSOriginFetch(origin, option)
//}
