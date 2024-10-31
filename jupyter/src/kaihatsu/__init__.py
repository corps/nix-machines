from src.kaihatsu.magic import KaihatsuMagics


def load_ipython_extension(ipython):
    ipython.register_magics(KaihatsuMagics)
