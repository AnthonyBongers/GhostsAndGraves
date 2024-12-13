// Translate a text character string into tile index bytes.
//
// Used in the tutorial screen for displaying chunks of
// information to the user.
//
// A padding of space characters are added to the end of the
// resulting data if the given string is shorter than the
// max allowed length.
//
// Usage: ./tutorialTextGen 'HELLO WORLD.'

#include <iomanip>
#include <iostream>
#include <sstream>

std::string hex(uint8_t i) {
  std::stringstream stream;
  stream << "$" << std::setfill('0') << std::setw(2) << std::hex << (int)i;

  return stream.str();
}

int main(int argc, const char *argv[]) {
  std::string text = argv[1];

  std::cout << ".byte ";
  for (int i = 0; i < text.size(); ++i) {
    switch (text[i]) {
    case '.':
      std::cout << "$ca, ";
      break;
    case ',':
      std::cout << "$cb, ";
      break;
    case ' ':
      std::cout << "$cc, ";
      break;
    default:
      std::cout << hex(text[i] - 'A' + 160 + (text[i] > 'P' ? 16 : 0)) << ", ";
    }
  }

  const int padding = 28 - text.size();
  for (int i = 0; i < padding; ++i) {
    std::cout << "$cc, ";
  }

  return 0;
}
