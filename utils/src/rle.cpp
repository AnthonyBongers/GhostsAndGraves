// Run length encoding for nametables.
//
// Usage: ./rle input.nam output.rle

#include <fstream>

#include "shared/console.hpp"

using namespace std;

int main(int argc, char *argv[]) {
  if (argc != 3)
    console::error("not enough arguments passed to rle");

  // Open file handles for reading and writing data.
  ifstream input(argv[1], ios::in | ios::binary);
  ofstream output(argv[2], ios::out | ios::binary | ios::trunc);

  // Buffer for output results.
  // Increase if needed, though an NES cart can only carry so much data.
  uint8_t result[1028 * 3] = {0};
  uint32_t index{};
  uint32_t byte = input.get(); // Query first byte of data.

  do {
    const bool isNewByte = byte != result[index + 1] && result[index];
    const bool isAtCountLimit = result[index] == 255;

    index += (isNewByte || isAtCountLimit) << 1;

    // An entry is two bytes:
    // - first byte is the byte run length,
    // - second byte is the byte to encode.
    result[index]++;
    result[index + 1] = (uint8_t)byte;

    byte = input.get();
  } while (input);

  output.write(reinterpret_cast<char *>(&result[0]), index + 3);

  input.close();
  output.close();

  std::string path = std::string(argv[1]);
  std::string filename = path.substr(path.find_last_of("/\\") + 1);
  console::success("compressed " + filename + " to " +
                   std::to_string(index + 3) + " bytes");

  return 0;
}
