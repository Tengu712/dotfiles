use std::{
    env,
    fs::File,
    io::{self, BufRead, BufReader, Write},
    process,
};

fn main() {
    let mut args = env::args().skip(1);
    let Some(fname) = args.next() else {
        process::exit(1);
    };
    let Some(line) = args.next() else {
        process::exit(1);
    };
    let Ok(line) = line.parse::<i32>() else {
        process::exit(1);
    };
    if line <= 0 {
        process::exit(1);
    }

    let start = if line > 200 { line - 200 } else { 1 };
    let end = line + 200;

    let Ok(file) = File::open(&fname) else {
        process::exit(1);
    };
    let reader = BufReader::new(file);

    let stdout = io::stdout();
    let mut out = stdout.lock();

    let mut i: i32 = 0;
    for l in reader.lines() {
        i += 1;
        if i < start {
            continue;
        }
        if i > end {
            break;
        }
        let Ok(buf) = l else {
            break;
        };
        let mark = if i == line { '>' } else { ' ' };
        writeln!(out, "{mark}{i}: {buf}").unwrap();
    }
}
