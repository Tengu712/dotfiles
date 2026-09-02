#include <cstring>
#include <iostream>
#include <string>

#define IGNORES_LIST(X) \
	X(".git")           \
	X("_build")         \
	X("build")          \
	X("target")         \
	X("dist")           \
	X("node_modules")   \
	X(".opam")          \
	X("_opam")

#define AF_FZF_CMD_BASE(X, Y, Z, W) \
	"fzf"           Y               \
	"--walker-skip" Y               \
	IGNORES_LIST(X) Y               \
	"--preview"     Y               \
	Z(W " {}")

#define AG_FZF_CMD_BASE(Y, Z)  \
	"fzf"                    Y \
	"--delimiter"            Y \
	":"                      Y \
	"--with-nth"             Y \
	"3.."                    Y \
	"--preview"              Y \
	Z("rg-preview {1} {2}")  Y \
	"--preview-label"        Y \
	Z(" ")                   Y \
	"--preview-window"       Y \
	Z("right,border,+{2}/2") Y \
	"--bind"                 Y \
	Z("focus:transform-preview-label:echo {1}")

#define RG_CMD_BASE(X, Y, Z, U) \
	"rg"            Y           \
	"--hidden"      Y           \
	"--line-number" Y           \
	"--no-heading"  Y           \
	"--no-messages" Y           \
	"--color=never" Y           \
	IGNORES_LIST(X) U           \
	Z("")

#if defined(_WIN32)
#	include <Windows.h>
#	define QUOTED(V)    "\"" V "\""
#	define COMMA_ARG(V) V ","
#	define GLOB_ARG(V)  " --glob \"!" V "/**\""

extern char **environ;

constexpr const char *AF_FZF_CMD = AF_FZF_CMD_BASE(COMMA_ARG, " ", QUOTED, "type");
constexpr const char *AG_FZF_CMD = AG_FZF_CMD_BASE(           " ", QUOTED);
constexpr const char *RG_CMD     =     RG_CMD_BASE( GLOB_ARG, " ", QUOTED        , " ");

int run_command_on_windows(std::string cmd) {
	STARTUPINFOA si{ sizeof(si) };
	PROCESS_INFORMATION pi{};

	CreateProcessA(nullptr, cmd.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr, &si, &pi);

	WaitForSingleObject(pi.hProcess, INFINITE);
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);
	return 0;
}

int run_commands_on_windows(std::string formerCmd, std::string latterCmd) {
	SECURITY_ATTRIBUTES sa{ sizeof(sa), nullptr, TRUE };

	HANDLE formerOutRead, formerOutWrite;
	CreatePipe(&formerOutRead, &formerOutWrite, &sa, 0);

	SetHandleInformation(formerOutRead, HANDLE_FLAG_INHERIT, 0);

	// stdin -> former cmd -> formerOutWrite
	STARTUPINFOA siFormer{ sizeof(siFormer) };
	siFormer.dwFlags    = STARTF_USESTDHANDLES;
	siFormer.hStdOutput = formerOutWrite;
	siFormer.hStdError  = GetStdHandle(STD_ERROR_HANDLE);
	siFormer.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
	PROCESS_INFORMATION piFormer{};
	CreateProcessA(nullptr, formerCmd.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr, &siFormer, &piFormer);
	CloseHandle(formerOutWrite);

	SetHandleInformation(formerOutRead, HANDLE_FLAG_INHERIT, 1);

	// formerOutRead -> latter cmd -> stdout
	STARTUPINFOA siLatter{ sizeof(siLatter) };
	siLatter.dwFlags    = STARTF_USESTDHANDLES;
	siLatter.hStdInput  = formerOutRead;
	siLatter.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
	siLatter.hStdError  = GetStdHandle(STD_ERROR_HANDLE);
	PROCESS_INFORMATION piLatter{};
	CreateProcessA(nullptr, latterCmd.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr, &siLatter, &piLatter);
	CloseHandle(formerOutRead);

	WaitForSingleObject(piFormer.hProcess, INFINITE);
	WaitForSingleObject(piLatter.hProcess, INFINITE);
	CloseHandle(piFormer.hProcess);
	CloseHandle(piFormer.hThread);
	CloseHandle(piLatter.hProcess);
	CloseHandle(piLatter.hThread);
	return 0;
}
#elif defined(__APPLE__)
#	include <spawn.h>
#	include <unistd.h>
#	include <sys/wait.h>
#	define NONE
#	define COMMA ,
#	define IDENTITY(V)     V
#	define COMMA_ARG(V) V ","
#	define GLOB_ARG(V)  "--glob" COMMA "!" V "/**" COMMA

extern char **environ;

static const char *AF_FZF_CMD[] = { AF_FZF_CMD_BASE(COMMA_ARG, COMMA, IDENTITY, "cat")      , nullptr };
static const char *AG_FZF_CMD[] = { AG_FZF_CMD_BASE(           COMMA, IDENTITY)             , nullptr };
static const char *RG_CMD[]     = {     RG_CMD_BASE( GLOB_ARG, COMMA, IDENTITY       , NONE), nullptr };

int run_command_on_macos(const char *const argv[]) {
	pid_t pid;
	if (posix_spawnp(&pid, argv[0], nullptr, nullptr, const_cast<char *const *>(argv), environ) != 0) {
		return 1;
	}

	int status;
	waitpid(pid, &status, 0);
	return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}

int run_commands_on_macos(const char *const former[], const char *const latter[]) {
	int pipefd[2];
	if (pipe(pipefd) != 0) {
		return 1;
	}

	posix_spawn_file_actions_t facFormer;
	posix_spawn_file_actions_init(&facFormer);
	posix_spawn_file_actions_adddup2(&facFormer, pipefd[1], STDOUT_FILENO);
	posix_spawn_file_actions_addclose(&facFormer, pipefd[0]);
	posix_spawn_file_actions_addclose(&facFormer, pipefd[1]);

	posix_spawn_file_actions_t facLatter;
	posix_spawn_file_actions_init(&facLatter);
	posix_spawn_file_actions_adddup2(&facLatter, pipefd[0], STDIN_FILENO);
	posix_spawn_file_actions_addclose(&facLatter, pipefd[0]);
	posix_spawn_file_actions_addclose(&facLatter, pipefd[1]);

	pid_t pidFormer, pidLatter;
	int rcFormer = posix_spawnp(&pidFormer, former[0], &facFormer, nullptr, const_cast<char *const *>(former), environ);
	int rcLatter = posix_spawnp(&pidLatter, latter[0], &facLatter, nullptr, const_cast<char *const *>(latter), environ);

	close(pipefd[0]);
	close(pipefd[1]);
	posix_spawn_file_actions_destroy(&facFormer);
	posix_spawn_file_actions_destroy(&facLatter);

	int status = 1;
	if (rcFormer == 0) waitpid(pidFormer, nullptr, 0);
	if (rcLatter == 0) waitpid(pidLatter, &status, 0);

	return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
#endif

int main(int argc, char *argv[]) {
	if (argc < 2) {
		return 1;
	}

#if defined(_WIN32)
	if (std::strcmp(argv[1], "af") == 0) return run_command_on_windows(AF_FZF_CMD);
	if (std::strcmp(argv[1], "ag") == 0) return run_commands_on_windows(RG_CMD, AG_FZF_CMD);
#elif defined(__APPLE__)
	if (std::strcmp(argv[1], "af") == 0) return run_command_on_macos(AF_FZF_CMD);
	if (std::strcmp(argv[1], "ag") == 0) return run_commands_on_macos(RG_CMD, AG_FZF_CMD);
#else
	return 1;
#endif
}
