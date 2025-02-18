package info.bagen.rust.plaoc.microService.sys.plugin.fileSystem

import android.system.Os
import androidx.core.net.toUri
import info.bagen.rust.plaoc.microService.core.NativeMicroModule
import info.bagen.rust.plaoc.microService.helper.byteArrayInputStream
import info.bagen.rust.plaoc.microService.sys.file.FileSystemPlugin
import org.http4k.core.*
import org.http4k.format.Jackson.asJsonObject
import org.http4k.format.Jackson.auto
import org.http4k.lens.*
import org.http4k.routing.bind
import org.http4k.routing.routes
import org.json.JSONObject
import java.io.*


class FileSystemNMM : NativeMicroModule("file.sys.dweb") {

    val plugin = FileSystemPlugin()

    override suspend fun _bootstrap() {
        apiRouting = routes(
            "/checkPermissions" bind Method.GET to defineHandler { request ->
                val path = Query.string().required("path")(request)
                println("FileSystemNMM#apiRouting checkPermissions===>$mmid  ${request.uri.path} ")
                val check = checkPermissions(path)
                val body = """{"permissions":"$check"}""".trimIndent()
                Response(Status.OK).body(body)
            },
            "/requestPermissions" bind Method.GET to defineHandler { request ->
                println("FileSystemNMM#apiRouting requestPermissions===>$mmid  ${request.uri.path} ")
                val path = Query.string().required("path")(request)
                requestPermissions(path, 0)
                Response(Status.OK)
            },
            /** 不断返回buffer */
            "/readBuffer" bind Method.GET to defineHandler { request ->
                println("FileSystemNMM#apiRouting read===>$mmid  ${request.uri.path} ")
                val path = Query.string().required("path")(request)
                // 不断的往客户端发流数据
                plugin.readBuffer(path) { byteArray, index ->
                    var status = Status.CREATED
                    status = if (index != -1) {
                        Status.PARTIAL_CONTENT // 部分内容
                    } else {
                        Status.OK // 内容发完了
                    }
                    Response(status).body(byteArray.byteArrayInputStream())
                }
            },
            /** 不断返回string*/
            "/readString" bind Method.GET to defineHandler { request ->
                println("FileSystemNMM#apiRouting read===>$mmid  ${request.uri.path} ")
                val path = Query.string().required("path")(request)
                // 不断的往客户端发流数据
                plugin.readFile(path) { str, hasNextLine ->
                    var status = Status.CREATED
                    status = if (hasNextLine) {
                        Status.PARTIAL_CONTENT // 部分内容
                    } else {
                        Status.OK // 内容发完了
                    }
                    Response(status).body(str)
                }
            },
            /** 流写入*/
            "/writeSteam" bind Method.POST to defineHandler { request ->
                println("FileSystemNMM#apiRouting writeSteam===>$mmid  ${request.uri.path} ")
                val path = Query.string().required("path")(request)
                // 是否是追加内容 是否要自动创建文件
                val writeOption = Query.composite {
                    WriteOption(
                        boolean().defaulted("append", false)(it),
                        boolean().defaulted("autoCreate", true)(it),
                    )
                }
                val option = writeOption(request)
                // TODO 这里的流获取消息需要验证，是否是具体内容
                val result = plugin.writeByteArray(path, request.body.stream, option)
                Response(Status.OK).body(result)
            },
            /** 字符写入 可以不断调这个方法*/
            "/writeString" bind Method.POST to defineHandler { request ->
                println("FileSystemNMM#apiRouting writeString===>$mmid  ${request.uri.path} ")
                val payload = request.body.payload.asJsonObject()
                val path = payload.get("path").asText()
                val content = payload.get("content").asText()
                // TODO 如果此方法可行，那就可以省略上面的path和context获取规则，一起整合成一个data class
                val writeOptionLens = Body.auto<WriteOption>().toLens()
                // 从正文中提取消息
                val option  = writeOptionLens(request)
                val result = plugin.write(path, content, option)
                Response(Status.OK).body(result)
            },
            /** 删除*/
            "/delete" bind Method.DELETE to defineHandler { request ->
                println("FileSystemNMM#apiRouting write===>$mmid  ${request.uri.path} ")
                val path = Query.string().required("path")(request)
                val deepDelete = Query.boolean().optional("deepDelete")(request)
                val result = plugin.rm(path, deepDelete?:true)
                Response(Status.OK).body(result)
            },
            /** ls  */
            "/ls" bind Method.GET to defineHandler { request ->
                val path = Query.string().required("path")(request)
                // TODO 这里是不是应该改成POST请求让LsFilter用body传递呢？ Body.auto<Array<LsFilter>>().toLens()
                val lsFilter = Query.auto<Array<LsFilter>>().defaulted("lsFilter", arrayOf())
                val filter = lsFilter(request)
                println("FileSystemNMM#apiRouting ls===>$mmid  ${request.uri.path} filter=>$filter ")
                val recursive = Query.boolean().optional("recursive")(request)
                val result = plugin.ls(path,filter ,recursive?:false)
                Response(Status.OK).body(result)
            },
            "/list" bind Method.GET to defineHandler { request ->
                val path = Query.string().required("path")(request)
                println("FileSystemNMM#apiRouting list===>$mmid  path: $path ")
                val result = plugin.list(path)
                Response(Status.OK).body(result)
            },
            "/mkdir" bind Method.GET to defineHandler { request ->
                val path = Query.string().required("path")(request)
                val recursive = Query.boolean().optional("recursive")(request) ?: false
                println("FileSystemNMM#apiRouting mkdir===>$mmid  path: $path ")
                val result = plugin.mkdir(path,recursive)
                Response(Status.OK).body(result)
            },
            "/rename" bind Method.GET to defineHandler { request ->
                val path = Query.string().required("path")(request)
                val newFilePath = Query.string().required("newFilePath")(request)
                println("FileSystemNMM#apiRouting rename===>$mmid  path: $path newFilePath: $newFilePath ")
                val result = plugin.rename(path,newFilePath)
                Response(Status.OK).body(result)
            },
        )
    }


    fun stat(path: String): JSONObject {
        val file = plugin.getFileByPath(path)
        val statData = Os.stat(file.toString())
        val data = JSONObject()
        data.put("uri", File(path).toUri().toString()) // 文件路径
        data.put("type", if (file.isDirectory) "directory" else "file") // 是文件还是目录
        data.put("size", statData.st_size) // 文件大小
        data.put("mtime", statData.st_mtime) // 上次数据修改时间的秒部分
        data.put("ctime", statData.st_ctime) //上次状态更改的部分时间的秒数
        data.put("atime", statData.st_atime) // 上次访问时间的秒部分
        data.put("blksize", statData.st_blksize) // 此对象的特定于文件系统的首选 I/O 块大小。 对于某些文件系统类型，这可能因文件而异
        data.put("blocks", statData.st_blocks) // 为此对象分配的块数
        data.put("dev", statData.st_dev) // 包含文件的设备的设备 ID
        data.put("gid", statData.st_gid) // 文件的组id
        data.put("rdev", statData.st_rdev) // 设备 ID（如果文件是字符或块特殊）。
        data.put("mode", statData.st_mode) //文件的模式（权限）。
        data.put("ino", statData.st_ino) // 文件序列号（inode）
        data.put("uid", statData.st_uid) // 文件的用户ID
        data.put("nlink", statData.st_nlink) //文件的硬链接数。
        return data
    }

    private fun checkPermissions(path: String): Boolean {
        val file = plugin.getFileByPath(path)
        return plugin.checkoutPermission(file.absolutePath)
    }

    // TODO 申请文件权限
    private fun requestPermissions(path: String, state: Int) {
        val file = plugin.addPermission(path, state)
    }

    override suspend fun _shutdown() {
        TODO("Not yet implemented")
    }

}
