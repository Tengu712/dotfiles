#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
	if (argc < 3) {
		return 1;
	}

	const char *fname = argv[1];

	const int line = std::stoi(std::string(argv[2]));
	if (line <= 0) {
		return 1;
	}

	const int start = (line > 200) ? line - 200 : 1;
	const int end   = line + 200;

	std::ifstream fh(argv[1]);
	if (!fh) {
		return 1;
	}

	std::string buf;
	int i = 0;

	while (std::getline(fh, buf)) {
		++i;

		if (i < start) continue;
		if (i > end)   break;

		std::cout << (i == line ? ">" : " ") << i << ": " << buf << "\n";
	}

	return 0;
}
