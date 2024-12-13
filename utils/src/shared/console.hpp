#ifndef __NES_UTILS_CONSOLE__
#define __NES_UTILS_CONSOLE__

#include <cassert>

#include <iostream>
#include <string>
#include <vector>

namespace console
{
  void error(std::string message) {
    std::cerr << "\033[31m\033[1m• error: \033[22m\033[39m" << message << std::endl;
    std::exit(0);
  }

  void warn(std::string message) {
    std::cout << "\033[33m\033[1m• warn: \033[22m\033[39m" << message << std::endl;
  }

  void success(std::string message) {
    std::cout << "\033[34m\033[1m• done: \033[22m\033[39m" << message << std::endl;
  }

  void info(std::string message) {
    std::cout << "\033[37m\033[1m• info: \033[22m\033[39m" << message << std::endl;
  }
};

#endif
