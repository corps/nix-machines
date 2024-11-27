from IPython import get_ipython
from IPython.core.magic import magics_class, Magics, cell_magic


@magics_class
class KaihatsuMagics(Magics):
    @cell_magic
    def convo(self, line: str, cell: str):
        i = get_ipython()
        args = line.split()
        if not args:
            return

        return eval(args[0], i.user_global_ns, i.user_ns)(cell, *args[1:])
