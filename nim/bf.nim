import os, strutils

type
  Tape = ref object
    cells: array[30_000, uint8]
    head: int

  Token = enum
    IncrementHead, DecrementHead
    IncrementCell, DecrementCell
    Print, Read
    LoopStart, LoopEnd

  CommandKind = enum
    Do, Loop

  Command = object
    case kind: CommandKind
    of Do:
      tk: Token
    of Loop:
      cs: seq[Command]

proc incrementHead(t: Tape) =
  t.head = t.head + 1

proc decrementHead(t: Tape) =
  t.head = t.head - 1

proc incrementCell(t: Tape) =
  t.cells[t.head] = t.cells[t.head] + 1

proc decrementCell(t: Tape) =
  t.cells[t.head] = t.cells[t.head] - 1

proc print(t: Tape) =
  stdout.write(chr(t.cells[t.head]))

proc read(t: Tape) =
  stdout.write("Enter a char: ")
  t.cells[t.head] = uint8(parseInt(stdin.readLine()))

func getData(t: Tape): uint8 =
  return t.cells[t.head]

proc tokenize(data: string): seq[Token] =
  var tokens: seq[Token]
  for c in data:
    case c:
      of '>': tokens.add(IncrementHead)
      of '<': tokens.add(DecrementHead)
      of '+': tokens.add(IncrementCell)
      of '-': tokens.add(DecrementCell)
      of '.': tokens.add(Print)
      of ',': tokens.add(Read)
      of '[': tokens.add(LoopStart)
      of ']': tokens.add(LoopEnd)
      else:   continue
  return tokens

proc parse(tokens: seq[Token], index: int): (seq[Command], int) =
  var commands: seq[Command]
  var index = index
  while index < tokens.len:
    case tokens[index]:
      of LoopStart:
        let res = parse(tokens, index+1)
        index = res[1]
        let loop = Command(kind: Loop, cs: res[0])
        commands.add(loop)
      of LoopEnd:
        return (commands, index)
      else:
        let command = Command(kind: Do, tk: tokens[index])
        commands.add(command)
    index.inc
  return (commands, index)

proc run(program: seq[Command], tape: Tape) =
  for command in program:
    case command.kind:
      of Do:
        case command.tk:
          of IncrementHead: tape.incrementHead()
          of DecrementHead: tape.decrementHead()
          of IncrementCell: tape.incrementCell()
          of DecrementCell: tape.decrementCell()
          of Print:         tape.print()
          of Read:          tape.read()
          else:             discard
      of Loop:
        while tape.getData() != 0:
          run(command.cs, tape)

when isMainModule:
  let brainfuck = paramStr(1).readFile()
  let program = tokenize(brainfuck).parse(0)[0]
  let tape = Tape()
  run(program, tape)
