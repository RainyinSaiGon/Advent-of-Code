import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Main {
    static String readInput(String path) throws IOException {
        return Files.readString(Path.of(path)).strip();
    }

    static int[][] parse(String data) {
        String[] lines = data.split("\n");
        int[] left = new int[lines.length];
        int[] right = new int[lines.length];
        for (int i = 0; i < lines.length; i++) {
            String[] parts = lines[i].trim().split("\\s+");
            left[i] = Integer.parseInt(parts[0]);
            right[i] = Integer.parseInt(parts[1]);
        }
        return new int[][] { left, right };
    }

    static long part1(String data) {
        int[][] parsed = parse(data);
        int[] left = parsed[0];
        int[] right = parsed[1];

        java.util.Arrays.sort(left);
        java.util.Arrays.sort(right);

        long total = 0;
        for (int i = 0; i < left.length; i++) {
            total += Math.abs(left[i] - right[i]);
        }
        return total;
    }

    static long part2(String data) {
        int[][] parsed = parse(data);
        int[] left = parsed[0];
        int[] right = parsed[1];

        Map<Integer, Integer> counts = new HashMap<>();
        for (int num : right) {
            counts.put(num, counts.getOrDefault(num, 0) + 1);
        }

        long total = 0;
        for (int num : left) {
            total += (long) num * counts.getOrDefault(num, 0);
        }
        return total;
    }

    public static void main(String[] args) throws IOException {
        String data = readInput("../input.txt");
        System.out.println("Part 1: " + part1(data));
        System.out.println("Part 2: " + part2(data));
    }
}
