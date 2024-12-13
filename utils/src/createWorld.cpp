// Generate a world config file with random level sizes.
//
// Once the player gets past the worlds that get progressively bigger,
// I wanted to make worlds that are a mix of level sizes for variety.

#include <fstream>
#include <random>

// Return a random lavel size.
std::pair<int, int> getPuzzleDimensions(std::default_random_engine &rng) {
  std::uniform_int_distribution<> width_uid(6, 10);
  std::uniform_int_distribution<> height_uid(6, 11);

  int width = width_uid(rng);
  int height = height_uid(rng);

  return {width, height};
}

// Return a sane amount a graves for a given level size.
std::pair<int, int> getGravesForDimensions(int w, int h) {
  const auto area = w * h;
  const auto maxGraves = area / 5;

  return {maxGraves - 1, maxGraves};
}

// For Time Attack mode, return a sane time limit for a given level size.
std::pair<int, int> getTimeLimitForDimensions(int w, int h) {
  const auto area = w * h;
  const auto seconds = area * 2; // 2 seconds per tile.

  return {seconds / 60, seconds % 60};
}

// For Shy Ghost mode, return a lane within the level size limit.
int getShyLane(int max, std::default_random_engine &rng) {
  std::uniform_int_distribution<> shy_uid(0, max - 1);

  return shy_uid(rng);
}

// Get a random seed for a level in the world.
int getPuzzleSeed(std::default_random_engine &rng) {
  std::uniform_int_distribution<> seed_uid(1000, 9999);

  return seed_uid(rng);
}

int main(int argc, const char *argv[]) {
  std::ofstream confFile(argv[1]);
  const int world = atoi(argv[2]);

  auto rng = std::default_random_engine(time(0));

  confFile << "{" << std::endl;
  confFile << "  \"dest\": \"./assets/levels/world_" << std::to_string(world)
           << ".asm\"," << std::endl;
  confFile << std::endl;
  confFile << "  \"prefix\": \"world_" << std::to_string(world) << "\","
           << std::endl;
  confFile << std::endl;
  confFile << "  \"puzzles\": [" << std::endl;

  for (int lanes = 0; lanes < 3; ++lanes) {
    for (int puzzle = 0; puzzle < 7; ++puzzle) {
      auto seed = getPuzzleSeed(rng);
      auto dims = getPuzzleDimensions(rng);
      auto graves = getGravesForDimensions(dims.first, dims.second);

      confFile << "    { \"seed\": " << std::to_string(seed)
               << ", \"mode\": \"Standard\",   \"width\": "
               << std::to_string(dims.first)
               << ", \"height\": " << std::to_string(dims.second)
               << ", \"minGhosts\": " << std::to_string(graves.first)
               << ", \"maxGhosts\": " << std::to_string(graves.second) << " },"
               << std::endl;
    }

    confFile << std::endl;
  }

  {
    auto seed = getPuzzleSeed(rng);
    auto dims = getPuzzleDimensions(rng);
    auto graves = getGravesForDimensions(dims.first, dims.second);

    auto shyLane1 = getShyLane(dims.second, rng);
    auto shyLane2 = getShyLane(dims.first, rng);

    confFile << "    { \"seed\": " << std::to_string(seed)
             << ", \"mode\": \"ShyGhost\",   \"width\": "
             << std::to_string(dims.first)
             << ", \"height\": " << std::to_string(dims.second)
             << ", \"minGhosts\": " << std::to_string(graves.first)
             << ", \"maxGhosts\": " << std::to_string(graves.second)
             << ", \"shyLaneH1\": " << std::to_string(shyLane1)
             << ", \"shyLaneV1\": " << std::to_string(shyLane2) << " },"
             << std::endl;
  }

  {
    auto seed = getPuzzleSeed(rng);
    auto dims = getPuzzleDimensions(rng);
    auto graves = getGravesForDimensions(dims.first, dims.second);

    auto shyLane1 = getShyLane(dims.second, rng);
    auto shyLane2 = getShyLane(dims.second, rng);

    confFile << "    { \"seed\": " << std::to_string(seed)
             << ", \"mode\": \"ShyGhost\",   \"width\": "
             << std::to_string(dims.first)
             << ", \"height\": " << std::to_string(dims.second)
             << ", \"minGhosts\": " << std::to_string(graves.first)
             << ", \"maxGhosts\": " << std::to_string(graves.second)
             << ", \"shyLaneH1\": " << std::to_string(shyLane1)
             << ", \"shyLaneH2\": " << std::to_string(shyLane2) << " },"
             << std::endl;
  }

  {
    auto seed = getPuzzleSeed(rng);
    auto dims = getPuzzleDimensions(rng);
    auto graves = getGravesForDimensions(dims.first, dims.second);

    auto shyLane1 = getShyLane(dims.second, rng);
    auto shyLane2 = getShyLane(dims.first, rng);
    auto shyLane3 = getShyLane(dims.first, rng);

    confFile << "    { \"seed\": " << std::to_string(seed)
             << ", \"mode\": \"ShyGhost\",   \"width\": "
             << std::to_string(dims.first)
             << ", \"height\": " << std::to_string(dims.second)
             << ", \"minGhosts\": " << std::to_string(graves.first)
             << ", \"maxGhosts\": " << std::to_string(graves.second)
             << ", \"shyLaneH1\": " << std::to_string(shyLane1)
             << ", \"shyLaneV1\": " << std::to_string(shyLane2)
             << ", \"shyLaneV2\": " << std::to_string(shyLane3) << " },"
             << std::endl;
  }

  for (int puzzle = 0; puzzle < 3; ++puzzle) {
    auto seed = getPuzzleSeed(rng);
    auto dims = getPuzzleDimensions(rng);
    auto graves = getGravesForDimensions(dims.first, dims.second);

    confFile << "    { \"seed\": " << std::to_string(seed)
             << ", \"mode\": \"NoShovel\",   \"width\": "
             << std::to_string(dims.first)
             << ", \"height\": " << std::to_string(dims.second)
             << ", \"minGhosts\": " << std::to_string(graves.first)
             << ", \"maxGhosts\": " << std::to_string(graves.second) << " },"
             << std::endl;
  }

  {
    auto seed = getPuzzleSeed(rng);
    auto dims = getPuzzleDimensions(rng);
    auto graves = getGravesForDimensions(dims.first, dims.second);

    auto timeLimit = getTimeLimitForDimensions(dims.first, dims.second);

    confFile << "    { \"seed\": " << std::to_string(seed)
             << ", \"mode\": \"TimeAttack\", \"width\": "
             << std::to_string(dims.first)
             << ", \"height\": " << std::to_string(dims.second)
             << ", \"minGhosts\": " << std::to_string(graves.first)
             << ", \"maxGhosts\": " << std::to_string(graves.second)
             << ", \"minutes\": " << std::to_string(timeLimit.first)
             << ", \"seconds\": " << std::to_string(timeLimit.second) << " }"
             << std::endl;
  }

  confFile << "  ]" << std::endl;
  confFile << "}";
}
