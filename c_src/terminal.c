#include <lean/lean.h>
#include <termios.h>
#include <unistd.h>
#include <stdio.h>
#include <time.h>

/* Global storage for original termios settings */
static struct termios original_termios;
static int raw_mode_enabled = 0;

/**
 * enable_raw - Set terminal to raw mode
 *
 * Sets VMIN=0 (non-blocking) and VTIME=1 (0.1 second timeout).
 */
LEAN_EXPORT lean_object* enable_raw() {
  struct termios raw;

  if (tcgetattr(STDIN_FILENO, &original_termios) == -1) {
    perror("tcgetattr");
    return lean_io_result_mk_ok(lean_box(0));
  }

  raw = original_termios;
  raw.c_lflag &= ~(ICANON | ECHO);
  raw.c_cc[VMIN] = 0;
  raw.c_cc[VTIME] = 1;

  if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
    perror("tcsetattr");
    return lean_io_result_mk_ok(lean_box(0));
  }

  raw_mode_enabled = 1;
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * disable_raw - Restore terminal to original mode
 */
LEAN_EXPORT lean_object* disable_raw() {
  if (raw_mode_enabled) {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &original_termios);
    raw_mode_enabled = 0;
  }
  return lean_io_result_mk_ok(lean_box(0));
}

/**
 * read_byte - Read one byte from stdin with timeout
 *
 * Returns the byte if available, or 0 on timeout/error.
 */
LEAN_EXPORT lean_object* read_byte() {
  struct timespec start, now;
  clock_gettime(CLOCK_MONOTONIC, &start);

  unsigned char c;
  ssize_t result = read(STDIN_FILENO, &c, 1);

  clock_gettime(CLOCK_MONOTONIC, &now);
  long elapsed = (now.tv_sec  - start.tv_sec)  * 1000000000L
               + (now.tv_nsec - start.tv_nsec);
  long remain  = 100000000L - elapsed;
  if (remain > 0) {
    struct timespec ts = { .tv_sec = 0, .tv_nsec = remain };
    nanosleep(&ts, NULL);
  }

  return (result == 1) ? lean_io_result_mk_ok(lean_box(c))
                       : lean_io_result_mk_ok(lean_box(0));
}
