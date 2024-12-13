// Reads the map file of the generated ROM.
//
// Will output the stats of the ROM segments to the developer.

#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "shared/console.hpp"

struct SegmentEntry {
  std::string name;
  std::string start;
  std::string end;
  std::string size;
  std::string align;
};

// Function to parse the "Segment list" section
void parseSegmentList(std::ifstream &file,
                      std::vector<SegmentEntry> &segments) {
  std::string line;
  while (std::getline(file, line)) {
    if (line.find("Exports list by name:") != std::string::npos) {
      // Rewind the line for the next section parsing.
      file.seekg(-static_cast<int>(line.length()) - 1, std::ios_base::cur);
      break;
    }
    if (line.find("Name") != std::string::npos ||
        line.find("----") != std::string::npos) {
      continue;
    }
    std::stringstream ss(line);
    SegmentEntry segment;
    if (ss >> segment.name >> segment.start >> segment.end >> segment.size >>
        segment.align) {
      segments.push_back(segment);
    }
  }
}

void printSegment(std::string label, std::string name, int limit,
                  const std::vector<SegmentEntry> &segments) {
  auto segment =
      std::find_if(segments.begin(), segments.end(),
                   [label](const SegmentEntry &s) { return s.name == label; });

  int size = (std::stoll(segment->end.c_str(), nullptr, 16) -
              std::stoll(segment->start.c_str(), nullptr, 16));
  int perc = (size / (float)limit) * 100;

  console::info(name + ": " + std::to_string(size) + " / " +
                std::to_string(limit) + " bytes (" + std::to_string(perc) +
                "%)");
}

void printSegmentList(const std::vector<SegmentEntry> &segments) {
  console::success("build succeeded");

  printSegment("ZEROPAGE", "zeropage ", 255, segments);
  printSegment("WRAM", "wram     ", 512, segments);
  printSegment("CODE", "code     ", 32762, segments);
}

int main(int argc, const char *argv[]) {
  std::ifstream file(argv[1]);
  if (!file.is_open()) {
    console::error("could not open the file");
  }

  std::string line;
  std::vector<SegmentEntry> segments;

  while (std::getline(file, line)) {
    if (line.find("Segment list:") != std::string::npos) {
      std::getline(file, line);
      parseSegmentList(file, segments);
    }
  }

  file.close();

  std::cout << std::setw(1);

  printSegmentList(segments);

  return 0;
}
