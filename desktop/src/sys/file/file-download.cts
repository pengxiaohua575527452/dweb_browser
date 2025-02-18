// 下载
const fs = require('fs');
const path = require('path')
const request = require('request');
const progress = require('request-progress');
const tar = require('tar')
let allocId = 0;
/**
 * 
 * @param url 
 * @param progress_callback 进程过程中的回调 
 * @param target 文件保存的地址
 * @returns 
 */
export function download(url: string, progress_callback: $ProgressCallback): Promise<Boolean>{
    const tempPath = path.resolve(__dirname, `../../../temp/${Date.now()+allocId++}.gz`)
    console.log('tempPath: ', tempPath)
    return new Promise((resolve, reject)=> {
        progress(request(url), {})
        .on('progress', createOnProgress(progress_callback))
        .on('error', createErrorCallback(reject))
        .on('end',() => createEndCallback(resolve, reject)(tempPath))
        .pipe(fs.createWriteStream(tempPath, {flags: "wx"})) 
    })
}

/**
 * 创建 pregress 事件监听器
 * @param progress_callback 
 * @returns 
 */
function createOnProgress(progress_callback: $ProgressCallback){
    return (state:$State) => {
        progress_callback(state)
    }
}

/**
 * 创建 end 事件监听器
 * @param resolve 
 * @param reject 
 * @returns 
 */
function createEndCallback(resolve: $Resolve<boolean>, reject: $Reject<Error>){
    return async (tempPath: string) => {
        const target = `${path.resolve(__dirname, "../../../apps")}`
        tar.x({
            file:tempPath,
            C: target
        })
        .then(() => {
            console.log('解压完成-')
            resolve(true)
        })
        .catch((err: Error) => console.log('解压失败', err))
    }
}

/**
 * 创建 Error 事件监听器
 * @param reject 
 * @returns 
 */
function createErrorCallback(reject: $Reject<Error>){
    return (err:Error) => {
        reject(err)
    }
}

export interface $State{
    percent: number             // Overall percent (between 0 to 1)
    speed: number               // The download speed in bytes/sec
    size: {
        total: number           // The total payload size in bytes
        transferred: number     // The transferred payload size in bytes
    },
    time: {
        elapsed: number,        // The total elapsed seconds since the start (3 decimals)
        remaining: number       // The remaining seconds to finish (3 decimals)
    }
}

export interface $ProgressCallback{
    (state:$State) : void
}

export interface $Resolve<T>{
    (value: T): void
}

export interface $Reject<T>{
    (value: T): void
}

export interface $Minifest{

}

export interface $ApkInfo{
    versionName: string;
    package: string;
    fileName: string;
}

// manifest： Manifest {
//     xml: XmlElement {
//       attributes: {
//         versionCode: 1,
//         versionName: '1.1.400',
//         compileSdkVersion: 32,
//         compileSdkVersionCodename: '12',
//         package: 'info.bfmeta.cot',
//         platformBuildVersionCode: 32,
//         platformBuildVersionName: 12
//       },
//       children: {
//         'uses-sdk': [Array],
//         'uses-permission': [Array],
//         queries: [Array],
//         'uses-feature': [Array],
//         application: [Array]
//       },
//       tag: 'manifest'
//     }
//   }            
// console.log(`package = ${manifest.package}`);
// console.log(`versionCode = ${manifest.versionCode}`);
// console.log(`versionName = ${manifest.versionName}`);
// console.log('manifest：', manifest)
// for properties which haven't any existing accessors you can use the raw binary xml
// console.log(JSON.stringify(manifest.raw, null, 4));

 