import json
import subprocess
import sys

import pexpect
from jupyter_client.kernel_runner import KernelRunner
from pexpect import EOF, replwrap


class IncrementalOutputWrapper(replwrap.REPLWrapper):
    def _expect_prompt(self, timeout=-1):
        if timeout == None:
            while True:
                pos = self.child.expect_exact(
                    [self.prompt, self.continuation_prompt, "\r\n"], timeout=None
                )
                if pos == 2:
                    self.line_output_callback(self.child.before + "\n")
                else:
                    if len(self.child.before) != 0:
                        self.line_output_callback(self.child.before)
                    break
        else:
            pos = replwrap.REPLWrapper._expect_prompt(self, timeout=timeout)

        return pos


class VineKernel(KernelRunner):
    implementation = "vine_kernel"
    implementation_version = "0.1"
    language = "vine"
    language_version = "0.1"
    language_info = {"name": "vine", "mimetype": "text/x-vine", "file_extension": ".vi"}

    banner = "Vine experimental kernel"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.repl_process = subprocess.Popen(
            ["vine", "repl"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def do_execute(
        self, code, silent, store_history=True, user_expressions=None, allow_stdin=False
    ):
        self.repl_process.stdin.write(code + "\n")
        self.repl_process.stdin.flush()
        output = self.repl_process.stdout.readline()
        if not silent:
            stream_content = {"name": "stdout", "text": output}
            self.send_response(self.iopub_socket, "stream", stream_content)

        return {
            "status": "ok",
            "execution_count": self.execution_count,
            "payload": [],
            "user_expressions": {},
        }


def main():
    from ipykernel.kernelapp import IPKernelApp

    IPKernelApp.launch_instance(kernel_class=VineKernel)


if __name__ == "__main__":
    main()
