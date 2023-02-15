console.log("ookkkk", "i'm in desktop worker");

const main = async function() {
    self.postMessage("test");
    let origin = await fetch('http://http.sys.dweb/listen?port=22280&subdomain=internal').then(res => {
//    let origin = await fetch('http://localhost:22605/http.sys.dweb/listen?port=80&subdomain=internal&mmid=js.sys.dweb').then(res => {
//        postMessage(res.text())
        return res.text();
    }).catch(err => {
        postMessage(err.message);
    });
  

  self.postMessage("http 服务创建成功");
  self.postMessage("打开浏览器页面" + origin);
  {
      fetch(`file://mwebview.sys.dweb/open?url=${encodeURIComponent(origin)}`)
  }
};
main();

