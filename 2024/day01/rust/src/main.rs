use std::collections::HashMap;
use std::fs;

fn read_input(path: &str) -> String {
    fs::read_to_string(path)
        .expect("Failed to read input file")
        .trim()
        .to_string()
}

fn parse(data: &str) -> (Vec<i64>, Vec<i64>) {
    let mut left = vec![];
    let mut right = vec![];

    for line in data.lines() {
        if line.is_empty() {
            continue;
        }
        let mut parts = line.split_whitespace();
        let a: i64 = parts.next().unwrap().parse().unwrap();
        let b: i64 = parts.next().unwrap().parse().unwrap();
        left.push(a);
        right.push(b);
    }

    (left, right)
}

fn part1(data: &str) -> i64 {
    let (mut left, mut right) = parse(data);
    left.sort();
    right.sort();

    left.iter()
        .zip(right.iter())
        .map(|(l, r)| (l - r).abs())
        .sum()
}

fn part2(data: &str) -> i64 {
    let (left, right) = parse(data);

    let mut counts: HashMap<i64, i64> = HashMap::new();
    for num in &right {
        *counts.entry(*num).or_insert(0) += 1;
    }

    left.iter()
        .map(|num| num * counts.get(num).unwrap_or(&0))
        .sum()
}

fn main() {
    let data = read_input("../input.txt");
    println!("Part 1: {}", part1(&data));
    println!("Part 2: {}", part2(&data));
}
