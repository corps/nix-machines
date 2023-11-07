import contextlib
import sys
import subprocess
import os.path

root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

def fail(message):
    print(message)
    sys.stderr.write(message + "\n")
    sys.stderr.flush()
    sys.exit(1)

class RunContext:
    def __init__(self, *commands):
        self.commands = commands

    def as_cmds(self, **kwds):
        result = []
        for k, v in kwds.items():
            if len(k) > 1:
                k = "--" + k.replace("_", "-")
            else:
                k = "-" + k
            if v is True:
                result.extend([k])
            elif v is False:
                continue
            else:
                result.extend([k, v])
        return result

    def __call__(self, *commands, required=True, silent=False, capture_output=False, with_tty=False, env=None, **kwargs):
        command = [*self.commands, *self.as_cmds(**kwargs), *commands]
        sub_env = os.environ.copy()
        sub_env.update(env or {})

        fds = dict()
        if not silent:
            print("> " + (" ".join(command)))
        else:
            fds['stdout'] = subprocess.DEVNULL
            fds['stderr'] = subprocess.DEVNULL
        if capture_output:
            fds['stdout'] = subprocess.PIPE
            fds['stderr'] = subprocess.PIPE
        with contextlib.ExitStack() as stack:
            p = stack.enter_context(subprocess.Popen(command, env=sub_env, **fds))
            if capture_output:
                out, err = p.communicate()
                if not silent:
                    if out:
                        print(out.decode('utf8'))
                    if err:
                        sys.stderr.write(err.decode('utf8'))
                        sys.stderr.flush()
            result = p.wait()

        if result != 0 and required:
            fail(f"Execution failed with code {result}")

        if capture_output:
            return out.decode('utf8')

        return result == 0

    def subcommand(self, *commands, **kwargs):
        return RunContext(*self.commands, *self.as_cmds(**kwargs), *commands)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        return

run = RunContext()

def count_leading_spaces(string):
    count = 0
    for char in string:
        if char.isspace():
            count += 1
        else:
            break
    return count

def parse_yaml_keys(lines, i=0, indention_level=0):
    agg = {}
    last_key = None

    line: str
    while i < len(lines):
        line = lines[i]
        line = line.expandtabs(2)
        indention = count_leading_spaces(line)
        stripped = line.strip()
        parts = stripped.split()
        if not parts or not parts[0].endswith(':'):
            i += 1
            continue
        if indention < indention_level:
            break

        key = parts[0][:-1]
        if indention > indention_level:
            if last_key is None:
                fail(f"Badly formatted yaml, found indention {indention} at top level!")
            agg[last_key], i = parse_yaml_keys(lines, i, indention)
        else:
            agg[key] = {}
            i += 1
            last_key = key
    return agg, i
