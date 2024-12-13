// Convert a BMP image to the NES image format.

#include <algorithm>
#include <fstream>
#include <iostream>
#include <vector>

#include "shared/console.hpp"
#include "shared/json.hpp"

const uint32_t bmpWidth = 128;
const uint32_t bmpHeight = 256;

#pragma pack(push, 1)
struct BMPHeader {
  uint16_t fileType;   // File type (always BM).
  uint32_t fileSize;   // Size of the file in bytes.
  uint16_t reserved1;  // Reserved (always 0).
  uint16_t reserved2;  // Reserved (always 0).
  uint32_t offsetData; // Start position of pixel data (bytes from file start).
};

struct DIBHeader {
  uint32_t size;            // Size of the header (in bytes).
  int32_t width;            // Width of the image (in pixels).
  int32_t height;           // Height of the image (in pixels).
  uint16_t planes;          // Number of color planes (must be 1).
  uint16_t bitCount;        // Bits per pixel.
  uint32_t compression;     // Compression type (must be 0 for uncompressed).
  uint32_t imageSize;       // Image size.
  int32_t xPixelsPerMeter;  // Horizontal resolution.
  int32_t yPixelsPerMeter;  // Vertical resolution.
  uint32_t colorsUsed;      // Number of colors in the color palette.
  uint32_t colorsImportant; // Important colors.
};
#pragma pack(pop)

struct Pixel {
  uint8_t b;
  uint8_t g;
  uint8_t r;
  uint8_t a;

  bool operator==(const Pixel &other) const {
    return r == other.r && g == other.g && b == other.b;
  }
};

std::vector<std::vector<Pixel>> g_palettes;

void parsePalettes(const char *paletteConfig) {
  std::ifstream configFile(paletteConfig);
  nlohmann::json config = nlohmann::json::parse(configFile);

  for (const auto &palette : config) {
    std::vector<Pixel> tempPalette;

    for (const auto &color : palette) {
      tempPalette.push_back(
          {color.at("b").get<uint8_t>(), color.at("g").get<uint8_t>(),
           color.at("r").get<uint8_t>(), color.at("a").get<uint8_t>()});
    }

    g_palettes.push_back(tempPalette);
  }
}

int determinePaletteIndex(int tilex, int tiley,
                          const std::vector<Pixel> &pixels) {
  std::vector<Pixel> uniquePixels;

  // Iterate over each pixel within the 8x8 tile
  for (int y = 0; y < 8; ++y) {
    for (int x = 0; x < 8; ++x) {
      int pixelIndex = (tiley * 8 + y) * bmpWidth + (tilex * 8 + x);
      Pixel pixel = pixels[pixelIndex];

      auto found = std::find(uniquePixels.begin(), uniquePixels.end(), pixel);

      if (found == uniquePixels.end()) {
        uniquePixels.push_back(pixel);
      }
    }
  }

  if (uniquePixels.size() > 4) {
    std::cerr << "Too many colours in " << tilex << "x" << tiley << std::endl;
    abort();
  }

  int paletteIndex = -1;
  for (int i = 0; i < g_palettes.size(); ++i) {
    bool result = std::all_of(
        uniquePixels.begin(), uniquePixels.end(), [i](const Pixel &up) {
          return std::find(g_palettes[i].begin(), g_palettes[i].end(), up) !=
                 g_palettes[i].end();
        });

    if (result) {
      if (paletteIndex != -1) {
        std::cout << "Ambiguity in tile " << tilex << "x" << tiley << std::endl;
      }

      paletteIndex = i;
    }
  }

  if (paletteIndex == -1) {
    std::cerr << "No palette match at " << tilex << "x" << tiley << std::endl;
    abort();
  }

  return paletteIndex;
}

std::vector<uint8_t> convertToCHR(const std::vector<Pixel> &pixels) {
  const int numHorizontalTiles = 16;
  const int numVerticalTiles = 32;
  std::vector<uint8_t> chrData;

  // Iterate over each tile (8x8 blocks)
  for (int ty = numVerticalTiles - 1; ty >= 0; --ty) {
    for (int tx = 0; tx < numHorizontalTiles; ++tx) {
      const std::vector<Pixel> palette =
          g_palettes[determinePaletteIndex(tx, ty, pixels)];

      uint8_t bitplane1[8] = {0};
      uint8_t bitplane2[8] = {0};

      // Iterate over each pixel within the 8x8 tile
      for (int y = 0; y < 8; ++y) {
        for (int x = 0; x < 8; ++x) {
          int pixelIndex = (ty * 8 + y) * bmpWidth + (tx * 8 + x);
          Pixel pixel = pixels[pixelIndex];

          // Map the pixel to one of the 4 colors in the palette
          uint8_t colorIndex = 5;
          for (int i = 0; i < 4; ++i) {
            if (pixel == palette[i]) {
              colorIndex = i;
              break;
            }
          }

          // Split the 2-bit color into two bitplanes
          bitplane1[y] |= ((colorIndex & 0x01) << (7 - x));
          bitplane2[y] |= (((colorIndex & 0x02) >> 1) << (7 - x));
        }
      }

      // Append bitplanes to the CHR data
      for (int i = 7; i >= 0; --i) {
        chrData.push_back(bitplane1[i]);
      }
      for (int i = 7; i >= 0; --i) {
        chrData.push_back(bitplane2[i]);
      }
    }
  }

  return chrData;
}

int main(int argc, char *argv[]) {
  std::ifstream bmpFile(argv[1], std::ios::binary);

  parsePalettes(argv[2]);

  // Parse BMP header data.
  BMPHeader bmpHeader;
  DIBHeader dibHeader;
  bmpFile.read(reinterpret_cast<char *>(&bmpHeader), sizeof(bmpHeader));
  bmpFile.read(reinterpret_cast<char *>(&dibHeader), sizeof(dibHeader));

  // Read pixel data
  bmpFile.seekg(bmpHeader.offsetData, std::ios::beg);
  std::vector<Pixel> pixels(dibHeader.width * dibHeader.height);
  bmpFile.read(reinterpret_cast<char *>(pixels.data()),
               pixels.size() * sizeof(Pixel));
  bmpFile.close();

  // Convert the BMP pixels to CHR format
  std::vector<uint8_t> chrData = convertToCHR(pixels);

  // Write the CHR data to a file
  std::ofstream chrFile(argv[3], std::ios::binary);
  chrFile.write(reinterpret_cast<char *>(chrData.data()), chrData.size());
  chrFile.close();

  std::string path = std::string(argv[1]);
  std::string filename = path.substr(path.find_last_of("/\\") + 1);
  console::success("converted " + filename + " to chr format");

  return 0;
}
