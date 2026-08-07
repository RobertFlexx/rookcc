#ifndef _TERMIOS_H
#define _TERMIOS_H 1
#include <rcc/_types.h>
typedef unsigned int tcflag_t;
typedef unsigned char cc_t;
typedef unsigned int speed_t;
#define NCCS 32
struct termios {
    tcflag_t c_iflag;
    tcflag_t c_oflag;
    tcflag_t c_cflag;
    tcflag_t c_lflag;
    cc_t c_line;
    cc_t c_cc[NCCS];
    speed_t c_ispeed;
    speed_t c_ospeed;
};
#define TCSANOW 0
#define TCSADRAIN 1
#define TCSAFLUSH 2
#define ICANON 0000002
#define ECHO 0000010
#define ISIG 0000001
#define VMIN 6
#define VTIME 5
int tcgetattr(int fd, struct termios *attributes);
int tcsetattr(int fd, int action, const struct termios *attributes);
speed_t cfgetispeed(const struct termios *attributes);
speed_t cfgetospeed(const struct termios *attributes);
int cfsetispeed(struct termios *attributes, speed_t speed);
int cfsetospeed(struct termios *attributes, speed_t speed);
#endif
