#!/usr/bin/python3
import collections
import ctypes
import re
import sys


class Mixin:
    """Mixin for allowing addition, subtraction, and hashing.

    ctypes.c_* has add/sub, but only via <type>.value. To make switching
    between builtin int and ctypes easy, we add it to the object itself.
    They are also not hashable, which is needed for
    collections.defaultdict().
    """
    def __add__(self, other):
        return self.value + other

    def __radd__(self, other):
        return self.value + other

    def __iadd__(self, other):
        self.value += other
        return self

    def __sub__(self, other):
        return self.value - other

    def __rsub__(self, other):
        return self.value - other

    def __isub__(self, other):
        self.value -= other
        return self

    def __eq__(self, other):
        return self.value == other

    def __hash__(self):
        return hash(self.value)


class Byte(Mixin, ctypes.c_byte):
    pass


class UByte(Mixin, ctypes.c_ubyte):
    pass


# Make int callable, syntax-wise works like initializing the ctypes.
Int = lambda x: x


# Set to Byte, UByte, or int.
TYPE = Int


class State:
    # Slots increase performance with the drawback of not being able to
    # add attributes later, which we do not.
    __slots__ = ('cells', 'data_pointer', 'instruction_pointer')

    def __init__(self):
        # Cells default to 0.
        self.cells = collections.defaultdict(lambda: TYPE(0), {})
        self.data_pointer = TYPE(0)
        self.instruction_pointer = 0


class Token:
    def __init__(self, instruction_num, state):
        self.instruction_num = instruction_num
        self.state = state

    def exec(self):
        raise NotImplementedError

    def __str__(self):
        return f"{self.instruction_num}: {self.__class__.__name__}"


class IncDataPointer(Token):
    def exec(self):
        self.state.data_pointer += 1


class DecDataPointer(Token):
    def exec(self):
        self.state.data_pointer -= 1


class IncCell(Token):
    def exec(self):
        self.state.cells[self.state.data_pointer] += 1


class DecCell(Token):
    def exec(self):
        self.state.cells[self.state.data_pointer] -= 1


class PrintCell(Token):
    # Could make Int a real class and add a .value, but I like this hack.
    if TYPE is Int:
        def exec(self):
            print(chr(self.state.cells[self.state.data_pointer]), end='')
    else:
        def exec(self):
            print(chr(self.state.cells[self.state.data_pointer].value), end='')


class SetCell(Token):
    def exec(self):
        self.state.cells[self.state.data_pointer] = ord(input('=> '))


class Loop(Token):
    def __init__(self, *args, **kwargs):
        self.other = None
        super().__init__(*args, **kwargs)

    def __str__(self):
        return f"{self.instruction_num}: {self.__class__.__name__}, other: {self.other.instruction_num}"


class LoopStart(Loop):
    def exec(self):
        if self.state.cells[self.state.data_pointer] == 0:
            self.state.instruction_pointer = self.other.instruction_num


class LoopEnd(Loop):
    def exec(self):
        if self.state.cells[self.state.data_pointer] != 0:
            self.state.instruction_pointer = self.other.instruction_num


def parse(program, state):
    token_map = {
            '>': IncDataPointer,
            '<': DecDataPointer,
            '+': IncCell,
            '-': DecCell,
            '.': PrintCell,
            ',': SetCell,
            '[': LoopStart,
            ']': LoopEnd
            }

    token_list = []
    loops = []

    for instruction_num, char in enumerate(program):
        token = token_map[char](instruction_num, state)
        token_list.append(token)

        if char == '[':
            loops.append(token)

        elif char == ']':
            loop_start = loops.pop()
            loop_start.other = token
            token.other = loop_start

    return token_list


def run(state, token_list):
    while state.instruction_pointer < len(token_list):
        token_list[state.instruction_pointer].exec()
        state.instruction_pointer += 1


if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            data = f.read()
    else:
        data = sys.stdin.read()

    program = re.findall(f"[{re.escape('<>+-.,[]')}]", data)

    state = State()
    token_list = parse(program, state)

    run(state, token_list)

    print("\nExiting...")
