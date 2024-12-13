// Format:
//
// byte 0: game mode
// 1 - Standard rules.
// 2 - No shovel mode (can't dig, only summon ghosts).
// 3 - Shy ghosts (some lanes don't mark how many ghosts).
// 4 - Time attack (2 bytes for second given).
//
// byte 1: game mode reserved byte
// Shy ghost mode: 0000 0000
//                    |    *- horizontal lane to hide.
//                    *------ horizontal lane to hide.
//
// Both set to 1111 means no lane hidden in this direction.
//
// Time attack: number of minutes given.
//
// byte 2: game mode reserved byte
// Shy ghost mode: 0000 0000
//                    |    *- vertical lane to hide.
//                    *------ vertical lane to hide.
//
// Both set to 1111 means no lane hidden in this direction.
//
// Time attack: number of seconds given.
//
// byte 3: 0000 0000
//            |    *- puzzle height (0 - 15).
//            *------ puzzle width  (0 - 15).
//
//
//       index 0  1  2  3  ... n
// tile bytes: 00 10 01 00
//              |  |  |  *- empty tile.
//              |  |  *---- ghost tile.
//              |  *------- grave tile.
//              *---------- each byte contains 4 tiles.
//
// tile byte count = (puzzle width * puzzle height) / 4 tiles per byte.

#include <algorithm>
#include <fstream>
#include <iomanip>
#include <random>
#include <sstream>
#include <vector>

#include "shared/console.hpp"
#include "shared/json.hpp"

std::string hex(uint8_t i) {
  std::stringstream stream;
  stream << "$" << std::setfill('0') << std::setw(2) << std::hex << (int)i;
  return stream.str();
}

enum Mode { Standard = 1, NoShovel, ShyGhost, TimeAttack };

enum Tile { Empty, Ghost, Grave };

struct Puzzle {
  int seed;

  uint8_t width;
  uint8_t height;
  uint8_t minGhosts;
  uint8_t maxGhosts;

  Mode mode;
  uint8_t minutes;
  uint8_t seconds;
  uint8_t shyLaneHorizontal1;
  uint8_t shyLaneHorizontal2;
  uint8_t shyLaneVertical1;
  uint8_t shyLaneVertical2;

  std::vector<Tile> tiles;
};

struct Data {
  std::string dest;
  std::string prefix;

  std::vector<Puzzle> levels;
};

Data parseConfig(const char *config) {
  Data data;

  try {
    std::ifstream configFile(config);
    nlohmann::json json = nlohmann::json::parse(configFile);

    data.dest = json["dest"].get<std::string>();
    data.prefix = json["prefix"].get<std::string>();

    for (const auto &level : json["puzzles"]) {
      Puzzle puzzle;
      puzzle.seed = level["seed"].get<int>();

      puzzle.width = level["width"].get<uint8_t>();
      puzzle.height = level["height"].get<uint8_t>();
      puzzle.minGhosts = level["minGhosts"].get<uint8_t>();
      puzzle.maxGhosts = level["maxGhosts"].get<uint8_t>();

      puzzle.shyLaneHorizontal1 =
          level.contains("shyLaneH1") ? level["shyLaneH1"].get<uint8_t>() : 15;
      puzzle.shyLaneHorizontal2 =
          level.contains("shyLaneH2") ? level["shyLaneH2"].get<uint8_t>() : 15;
      puzzle.shyLaneVertical1 =
          level.contains("shyLaneV1") ? level["shyLaneV1"].get<uint8_t>() : 15;
      puzzle.shyLaneVertical2 =
          level.contains("shyLaneV2") ? level["shyLaneV2"].get<uint8_t>() : 15;

      std::string mode = level["mode"].get<std::string>();
      if (mode == "Standard")
        puzzle.mode = Mode::Standard;
      else if (mode == "NoShovel")
        puzzle.mode = Mode::NoShovel;
      else if (mode == "ShyGhost")
        puzzle.mode = Mode::ShyGhost;
      else if (mode == "TimeAttack")
        puzzle.mode = Mode::TimeAttack;

      if (level.contains("minutes")) {
        puzzle.minutes = level["minutes"].get<uint8_t>();
      }
      if (level.contains("seconds")) {
        puzzle.seconds = level["seconds"].get<uint8_t>();
      }

      puzzle.tiles.insert(puzzle.tiles.begin(), puzzle.width * puzzle.height,
                          Tile::Empty);

      data.levels.push_back(puzzle);
    }
  } catch (...) {
    console::error("failed to parse config file");
  }

  return data;
}

void printPuzzle(Puzzle &puzzle) {
  for (int y = 0; y < puzzle.height; ++y) {
    for (int x = 0; x < puzzle.width; ++x) {
      std::cout << puzzle.tiles[x + (y * puzzle.width)] << " ";
    }
    std::cout << std::endl;
  }

  std::cout << std::endl;
}

std::string serializePuzzle(Puzzle &puzzle) {
  std::string result = ".byte ";
  result += hex(puzzle.mode);

  if (puzzle.mode == Mode::ShyGhost) {
    result += ", " +
              hex((puzzle.shyLaneHorizontal1 << 4) | puzzle.shyLaneHorizontal2);
    result +=
        ", " + hex((puzzle.shyLaneVertical1 << 4) | puzzle.shyLaneVertical2);
  }

  if (puzzle.mode == Mode::TimeAttack) {
    result += ", " + hex(puzzle.minutes);
    result += ", " + hex(puzzle.seconds);
  }

  result += ", " + hex((puzzle.width << 4) | puzzle.height);

  for (int i = 0; i < puzzle.tiles.size();) {
    uint8_t data = 0;

    data |= puzzle.tiles[i] << 6;
    ++i;
    if (i < puzzle.tiles.size())
      data |= puzzle.tiles[i] << 4;
    ++i;
    if (i < puzzle.tiles.size())
      data |= puzzle.tiles[i] << 2;
    ++i;
    if (i < puzzle.tiles.size())
      data |= puzzle.tiles[i];
    ++i;

    result += ", " + hex(data);
  }

  return result;
}

void serializeData(Data &data) {
  std::ofstream file(data.dest);

  file << ";; generated file from createPuzzles utility." << std::endl
       << std::endl;
  file << ".segment \"CODE\"" << std::endl << std::endl;

  file << data.prefix << ":" << std::endl;

  for (int i = 0; i < data.levels.size(); ++i) {
    file << data.prefix << "_level_" << i << ":" << std::endl;
    file << serializePuzzle(data.levels[i]) << std::endl << std::endl;
  }

  file.close();
}

bool addGhosts(Puzzle &puzzle, std::default_random_engine &rng) {
  std::vector<int> indices;
  for (int i = 0; i < puzzle.tiles.size(); ++i) {
    indices.push_back(i);
  }

  std::shuffle(indices.begin(), indices.end(), rng);
  std::uniform_int_distribution<> uid(puzzle.minGhosts, puzzle.maxGhosts);
  int numGhosts = uid(rng);

  int ghostsAdded = 0;
  for (; ghostsAdded < numGhosts && indices.size() > 0;) {
    int index = indices[indices.size() - 1];
    indices.pop_back();

    int x = index % puzzle.width;
    int y = index / puzzle.width;

    bool ok = true;

    const bool is_leftmost = x == 0;
    const bool is_topmost = y == 0;
    const bool is_rightmost = x == puzzle.width - 1;
    const bool is_bottommost = y == puzzle.height - 1;

    // cross
    ok = ok && (is_leftmost || (puzzle.tiles[index - 1] == Tile::Empty));
    ok = ok && (is_rightmost || (puzzle.tiles[index + 1] == Tile::Empty));
    ok = ok &&
         (is_topmost || (puzzle.tiles[index - puzzle.width] == Tile::Empty));
    ok = ok &&
         (is_bottommost || (puzzle.tiles[index + puzzle.width] == Tile::Empty));

    // diag
    ok = ok && (is_leftmost || is_topmost ||
                (puzzle.tiles[index - puzzle.width - 1] == Tile::Empty));
    ok = ok && (is_rightmost || is_bottommost ||
                (puzzle.tiles[index + puzzle.width + 1] == Tile::Empty));
    ok = ok && (is_rightmost || is_topmost ||
                (puzzle.tiles[index - puzzle.width + 1] == Tile::Empty));
    ok = ok && (is_leftmost || is_bottommost ||
                (puzzle.tiles[index + puzzle.width - 1] == Tile::Empty));

    if (!ok)
      continue;

    puzzle.tiles[index] = Tile::Ghost;
    ghostsAdded++;
  }

  return ghostsAdded == numGhosts;
}

bool addGraves(Puzzle &puzzle, std::default_random_engine &rng) {
  for (int y = 0; y < puzzle.height; ++y) {
    for (int x = 0; x < puzzle.width; ++x) {
      const int index = x + (y * puzzle.width);

      if (puzzle.tiles[index] != Tile::Ghost)
        continue;

      const bool is_leftmost = x == 0;
      const bool is_topmost = y == 0;
      const bool is_rightmost = x == puzzle.width - 1;
      const bool is_bottommost = y == puzzle.height - 1;

      std::vector<int> options;

      if (!is_leftmost)
        options.push_back(index - 1);
      if (!is_rightmost)
        options.push_back(index + 1);
      if (!is_topmost)
        options.push_back(index - puzzle.width);
      if (!is_bottommost)
        options.push_back(index + puzzle.width);

      std::shuffle(options.begin(), options.end(), rng);

      bool ok = false;
      for (int i = 0; i < options.size(); ++i) {
        int grave = options[i];
        if (puzzle.tiles[grave] == Tile::Empty) {
          puzzle.tiles[grave] = Tile::Grave;
          ok = true;
          break;
        }
      }
      if (!ok)
        return false;
    }
  }

  return true;
}

int main(int argc, const char *argv[]) {
  if (argc != 2)
    console::error("missing args passed to createPuzzles");

  Data data = parseConfig(argv[1]);

  for (auto &level : data.levels) {
    auto rng = std::default_random_engine(level.seed);
    bool ok = addGhosts(level, rng) && addGraves(level, rng);

    if (!ok)
      console::error("failed to create valid puzzle from seed " +
                     std::to_string(level.seed));

    // printPuzzle(level);
  }

  serializeData(data);

  std::string path = data.dest;
  std::string filename = path.substr(path.find_last_of("/\\") + 1);
  console::success("generated " + std::to_string(data.levels.size()) +
                   " levels to " + filename);
}
