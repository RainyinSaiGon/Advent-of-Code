import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Main {
    static String readInput(String path) throws IOException {
        return Files.readString(Path.of(path)).strip();
    }

    static String part1(String data) {
        return "unimplemented";
    }

    static String part2(String data) {
        return "unimplemented";
    }

    public static void main(String[] args) throws IOException {
        String data = readInput("../input.txt");
        System.out.println("Part 1: " + part1(data));
        System.out.println("Part 2: " + part2(data));
    }
}
