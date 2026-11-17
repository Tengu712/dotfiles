use std::{env, fs, io::ErrorKind, path::Path};

type Data = Vec<(String, String)>;

fn main() {
    let path = env::home_dir().unwrap().join(".cdd");
    let data = load_data(&path);

    let args = env::args().skip(1).collect::<Vec<String>>();

    match args.as_slice() {
        [] => show(data),
        [target] => cd(data, target),
        [id, to] => save_data(&path, register(data, id, to)),
        _ => panic!("too many arguments"),
    }
}

fn load_data(path: &Path) -> Data {
    let raw = match fs::read_to_string(path) {
        Ok(raw) => raw,
        Err(err) if err.kind() == ErrorKind::NotFound => return vec![],
        Err(err) => panic!("failed to read {}: {}", path.display(), err),
    };

    raw.lines()
        .map(|v| v.split_once('\0').unwrap())
        .map(|(id, to)| (id.to_owned(), to.to_owned()))
        .collect()
}

fn save_data(path: &Path, data: Data) {
    let s = data
        .into_iter()
        .map(|(id, to)| format!("{id}\0{to}"))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(path, s).unwrap();
}

fn show(data: Data) {
    for (id, path) in data {
        println!("{id} -> {path}");
    }
}

fn cd(data: Data, target: &str) {
    for (id, to) in data {
        if id != target {
            continue;
        }
        println!("{}", fs::canonicalize(to).unwrap().display());
        return;
    }
    panic!("{} is not registered", target);
}

fn register(mut data: Data, id: &str, to: &str) -> Data {
    if id.contains(['\r', '\n']) || to.contains(['\r', '\n']) {
        panic!("id and path must not contain line breaks");
    }
    if data.iter().any(|(i, _)| i.as_str() == id) {
        panic!("{} is already registered", id);
    }

    let to = fs::canonicalize(to).expect("path is invalid");
    if !to.is_dir() {
        panic!("{} is not a directory", to.display());
    }

    let to = to.to_str().expect("path is not valid UTF-8");
    if to.contains(['\r', '\n']) {
        panic!("path must not contain line breaks");
    }

    data.push((id.to_owned(), to.to_owned()));
    data.sort_by(|a, b| a.0.cmp(&b.0));
    data
}
