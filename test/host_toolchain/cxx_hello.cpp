//! expect-stdout: hi from C++: 3 words, 18 letters

// #1915 (:no-host-toolchain): `with cc --driver-mode=g++` compiles and links
// a C++ program against the compiler's own libc++ (libc++abi and libunwind
// in it), no host libstdc++ or toolchain in reach. The exception crosses
// the unwinder.
#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>

static std::size_t letters(const std::vector<std::string> &words) {
    std::size_t n = 0;
    for (const auto &w : words) n += w.size();
    if (n == 0) throw std::runtime_error("no letters");
    return n;
}

int main() {
    std::vector<std::string> words{"hello", "from", "cplusplus"};
    try {
        std::cout << "hi from C++: " << words.size() << " words, " << letters(words) << " letters\n";
        letters({});
    } catch (const std::runtime_error &e) {
        return std::string(e.what()) == "no letters" ? 0 : 1;
    }
    return 2;
}
