package info.bagen.rust.plaoc.microService.helper

typealias Callback<Args> = suspend (args: Args) -> Any?
typealias SimpleCallback = Callback<Unit>
typealias OffListener = (Unit) -> Boolean

/** 控制器 */
enum class SIGNAL_CTOR {
    /**
     * 返回该值，会解除监听
     */
    OFF,

    /**
     * 返回该值，会让接下来的其它监听函数不再触发
     */
    BREAK,
    ;
}

open class Signal<Args> {
    private val listenerSet = mutableSetOf<Callback<Args>>();
    fun listen(cb: Callback<Args>): OffListener {
        // TODO emit 时的cbs 应该要同步进行修改？
        listenerSet.add(cb)
        return { off(cb) }
    }

    private fun off(cb: Callback<Args>): Boolean {
        return listenerSet.remove(cb)
    }


    suspend fun emit(args: Args) {
        // toList 是为了拷贝一份，避免中通对其读写的时候出问题
        val cbs = listenerSet.toList()
        for (cb in cbs) {
            try {
                /// 因为 cbs 和 listenerSet 已经不是同一个列表了，所以至少说执行之前要检查一下是否还在
                if (!listenerSet.contains(cb)) {
                    continue
                }
                when (cb(args)) {
                    SIGNAL_CTOR.OFF -> listenerSet.remove(cb)
                    SIGNAL_CTOR.BREAK -> break
                }
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }
}


class SimpleSignal : Signal<Unit>() {
    suspend fun emit() {
        emit(Unit)
    }
};
