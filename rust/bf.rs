use std::env;
use std::io;
use std::io::Read;
use std::fs::File;

struct Tape {
    pointer: usize,
    tape: [u8; 30000],
}

impl Tape {
    fn get_data(&mut self) -> u8 {
        self.tape[self.pointer]
    }

    fn increment_pointer(&mut self) {
        self.pointer += 1;
    }

    fn decrement_pointer(&mut self) {
        self.pointer -= 1;
    }

    fn increment_cell(&mut self) {
        self.tape[self.pointer] += 1;
    }

    fn decrement_cell(&mut self) {
        self.tape[self.pointer] -= 1;
    }

    fn print_cell(&mut self) {
        print!("{}", self.get_data() as u8 as char);
    }

    fn input_to_cell(&mut self) {
        self.tape[self.pointer] = io::stdin()
            .bytes()
            .next()
            .and_then(|result| result.ok())
            .map(|byte| byte as u8)
            .expect("Failed to read byte");
    }
}

#[derive(Clone, Copy, Debug)]
enum Token {
    IncrementPointer,
    DecrementPointer,
    IncrementCell,
    DecrementCell,
    PrintCell,
    Input,
    LoopStart,
    LoopEnd,
}

#[derive(Clone, Debug)]
enum Command {
    Do(Token),
    Loop(Vec<Command>),
}

fn tokenize(data: Vec<u8>) -> Vec<Token> {
    let mut tokens = Vec::new();

    for u8_char in data {
        tokens.push(match u8_char as char {
            '>' => Token::IncrementPointer,
            '<' => Token::DecrementPointer,
            '+' => Token::IncrementCell,
            '-' => Token::DecrementCell,
            '.' => Token::PrintCell,
            ',' => Token::Input,
            '[' => Token::LoopStart,
            ']' => Token::LoopEnd,
            _  => continue,
        })
    }
    tokens
}

fn parse(start: usize, tokens: &Vec<Token>) -> (Vec<Command>, usize) {
    let mut program = Vec::new();
    let mut index = start;
    while index < tokens.len() {
        match tokens[index] {
            Token::LoopStart => {
                let res = parse(index+1, &tokens);
                program.push(Command::Loop(res.0));
                index = res.1;
            }
            Token::LoopEnd => { return (program, index); }
            _ => program.push(Command::Do(tokens[index])),
        }
        index += 1;
    }
    (program, index)
}

fn run(program: &Vec<Command>, tape: &mut Tape) {
    for command in program {
        match *command {
            Command::Do(Token::IncrementPointer) => tape.increment_pointer(),
            Command::Do(Token::DecrementPointer) => tape.decrement_pointer(),
            Command::Do(Token::IncrementCell) => tape.increment_cell(),
            Command::Do(Token::DecrementCell) => tape.decrement_cell(),
            Command::Do(Token::PrintCell) => tape.print_cell(),
            Command::Do(Token::Input) => tape.input_to_cell(),
            Command::Loop(ref vec) => {
                while tape.get_data() != 0 {
                    run(vec, tape);
                }
            },
            _ => continue,
        }
    }
}

fn read_file(name: String) -> Vec<u8> {
    let mut f = File::open(name).expect("Couldn't open file");
    let mut contents = Vec::new();
    f.read_to_end(&mut contents).expect("Couldn't read file");
    contents
}

fn main() {
    let f = read_file(env::args().nth(1).expect("Need a file name"));
    let tokens = tokenize(f);
    let program = parse(0, &tokens).0;
    let mut tape = Tape { pointer: 0, tape: [0; 30000] };
    run(&program, &mut tape);
}
