#!/usr/bin/python3
import collections
import ctypes
import re
import sys


class Mixin:
    def __add__(self, other):
        return self.value + other

    def __sub__(self, other):
        return self.value - other

    def __radd__(self, other):
        return self.value + other

    def __rsub__(self, other):
        return self.value - other

    def __iadd__(self, other):
        self.value += other
        return self

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

Int = lambda x: x

TYPE = Int


class Machine:
    def __init__(self, program):
        self.program = program
        cells = {}
        self.cells = collections.defaultdict(lambda: TYPE(0), cells)
        self.data_pointer = TYPE(0)
        self.instruction_pointer = 0

        self.command_map = {
                '>': self.increment_data_pointer,
                '<': self.decrement_data_pointer,
                '+': self.increment_cell,
                '-': self.decrement_cell,
                '.': self.print_cell,
                ',': self.set_cell,
                '[': self.loop_start,
                ']': self.loop_end
                }

    def increment_data_pointer(self):
        self.data_pointer += 1

    def decrement_data_pointer(self):
        self.data_pointer -= 1

    def increment_cell(self):
        self.cells[self.data_pointer] += 1

    def decrement_cell(self):
        self.cells[self.data_pointer] -= 1

    def print_cell(self):
        print(chr(self.cells[self.data_pointer]), end='')

    def set_cell(self):
        self.cells[self.data_pointer] = TYPE(ord(input('=> ')))

    def loop_start(self):
        if self.cells[self.data_pointer] == 0:
            loop_starts = 0
            self.instruction_pointer += 1
            instruction = self.program[self.instruction_pointer]
            while loop_starts > 0 or instruction != ']':
                if instruction == '[':
                    loop_starts += 1
                if instruction == ']':
                    loop_starts -= 1
                self.instruction_pointer += 1
                instruction = self.program[self.instruction_pointer]

    def loop_end(self):
        if self.cells[self.data_pointer] != 0:
            loop_ends = 0
            self.instruction_pointer -= 1
            instruction = self.program[self.instruction_pointer]
            while loop_ends > 0 or instruction != '[':
                if instruction == ']':
                    loop_ends += 1
                if instruction == '[':
                    loop_ends -= 1
                self.instruction_pointer -= 1
                instruction = self.program[self.instruction_pointer]

    def run(self):
        while self.instruction_pointer < len(self.program):
            self.command_map[self.program[self.instruction_pointer]]()
            self.instruction_pointer += 1


if __name__ == "__main__":
    with open(sys.argv[1], 'r') as f:
        program = re.findall(f"[{re.escape('<>+-.,[]')}]", f.read())

    machine = Machine(program)
    machine.run()
    print("\nExiting...")
