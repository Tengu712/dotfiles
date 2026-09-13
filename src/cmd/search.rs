use std::{
    env,
    fs::File,
    io::{self, Write},
    process::{self, Command, Stdio},
};

macro_rules! cat {
    ($($item:expr,)+) => {
        concat!($($item),+)
    };
}

macro_rules! list {
    ($($item:expr,)+) => {
        [$($item),+]
    };
}

macro_rules! with_tail_comma {
    ($item:expr) => {
        concat!($item, ",")
    };
}

macro_rules! as_glob_flag {
    ($item:expr) => {
        concat!("--glob=!", $item, "/**")
    };
}

macro_rules! ignore_list {
    ($around:ident, $filter:ident) => {
        $around!(
            $filter!(".git"),
            $filter!("_build"),
            $filter!("build"),
            $filter!("target"),
            $filter!("dist"),
            $filter!("node_modules"),
            $filter!(".opam"),
            $filter!("_opam"),
        )
    };
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: search (af|ag) [tmp-filepath]");
        process::exit(1);
    }

    match args[1].as_str() {
        "af" => af(args.get(2)),
        "ag" => ag(args.get(2)),
        v => {
            eprintln!("invalid argument: {v}");
            process::exit(1);
        }
    }
}

fn af(tmpfile: Option<&String>) {
    const ARGS: &[&str] = &[
        "--walker-skip",
        ignore_list!(cat, with_tail_comma),
        "--preview",
        #[cfg(target_os = "macos")]
        "cat {}",
        #[cfg(target_os = "windows")]
        "type {}",
    ];

    let output = Command::new("fzf")
        .args(ARGS)
        .stdin(Stdio::inherit())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .output()
        .unwrap();
    out(&output.stdout, tmpfile);
}

fn ag(tmpfile: Option<&String>) {
    const RG_ARGS: &[&str] = &[
        "--hidden",
        "--line-number",
        "--no-heading",
        "--no-messages",
        "--color=never",
    ];
    const FZF_ARGS: &[&str] = &[
        "--delimiter=:",
        "--with-nth=3..",
        "--preview",
        "rg-preview {1} {2}",
        "--preview-label",
        " ",
        "--preview-window",
        "right,border,+{2}/2",
        "--bind",
        "focus:transform-preview-label:echo {1}",
    ];

    let output = Command::new("rg")
        .args(RG_ARGS)
        .args(ignore_list!(list, as_glob_flag))
        .arg("")
        .stdin(Stdio::inherit())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    let output = Command::new("fzf")
        .args(FZF_ARGS)
        .stdin(Stdio::from(output.stdout.unwrap()))
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .output()
        .unwrap();
    out(&output.stdout, tmpfile);
}

fn out(stdout: &[u8], tmpfile: Option<&String>) {
    if let Some(tmpfile) = tmpfile {
        let Ok(mut tmpfile) = File::create(&tmpfile) else {
            eprintln!("{} not exist or something is wrong", tmpfile);
            process::exit(1);
        };
        tmpfile.write_all(stdout).unwrap();
    } else {
        io::stdout().write_all(stdout).unwrap();
    }
}
