use std::fs;

fn read_input(path: &str) -> String {
    fs::read_to_string(path)
        .expect("Failed to read input file")
        .trim()
        .to_string()
}

fn part1(data: &str) -> String {
    let _ = data;
    String::from("unimplemented")
}

fn part2(data: &str) -> String {
    let _ = data;
    String::from("unimplemented")
}

fn main() {
    let data = read_input("../input.txt");
    println!("Part 1: {}", part1(&data));
    println!("Part 2: {}", part2(&data));
}
