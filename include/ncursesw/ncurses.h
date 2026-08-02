#ifndef _RCC_NCURSESW_NCURSES_H
#define _RCC_NCURSESW_NCURSES_H 1










#include <stddef.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <wchar.h>

#ifndef CURSES
#define CURSES 1
#endif
#ifndef CURSES_H
#define CURSES_H 1
#endif
#ifndef _XOPEN_CURSES
#define _XOPEN_CURSES 1
#endif
#ifndef NCURSES_WIDECHAR
#define NCURSES_WIDECHAR 1
#endif
#ifndef NCURSES_MOUSE_VERSION
#define NCURSES_MOUSE_VERSION 2
#endif
#ifndef NCURSES_OPAQUE
#define NCURSES_OPAQUE 1
#endif
#ifndef NCURSES_EXT_COLORS
#define NCURSES_EXT_COLORS 1
#endif
#ifndef NCURSES_COLOR_T
#define NCURSES_COLOR_T short
#endif
#ifndef NCURSES_PAIRS_T
#define NCURSES_PAIRS_T short
#endif
#ifndef NCURSES_ATTR_T
#define NCURSES_ATTR_T int
#endif

#if NCURSES_WIDECHAR != 1
#error "this ncursesw ABI facade requires wide-character support"
#endif
#if NCURSES_MOUSE_VERSION != 2
#error "this ncursesw ABI facade requires mouse ABI version 2"
#endif
#if NCURSES_OPAQUE != 1
#error "this ncursesw ABI facade requires opaque WINDOW and SCREEN records"
#endif
#if !NCURSES_EXT_COLORS
#error "this ncursesw ABI facade requires the extended-color cchar_t layout"
#endif

typedef struct _win_st WINDOW;
typedef struct screen SCREEN;

typedef uint32_t chtype;
typedef chtype attr_t;
typedef uint32_t mmask_t;

#define CCHARW_MAX 5
typedef struct {
    attr_t attr;
    wchar_t chars[CCHARW_MAX];
    int ext_color;
} cchar_t;

typedef struct {
    short id;

    int x;
    int y;
    int z;
    mmask_t bstate;
} MEVENT;

typedef int (*NCURSES_OUTC)(int);
typedef int (*NCURSES_WINDOW_CB)(WINDOW *, void *);
typedef int (*NCURSES_SCREEN_CB)(SCREEN *, void *);

#ifndef ERR
#define ERR (-1)
#endif
#ifndef OK
#define OK 0
#endif
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define COLOR_BLACK 0
#define COLOR_RED 1
#define COLOR_GREEN 2
#define COLOR_YELLOW 3
#define COLOR_BLUE 4
#define COLOR_MAGENTA 5
#define COLOR_CYAN 6
#define COLOR_WHITE 7

#define NCURSES_ATTR_SHIFT 8
#define A_NORMAL ((chtype)0x00000000U)
#define A_CHARTEXT ((chtype)0x000000ffU)
#define A_COLOR ((chtype)0x0000ff00U)
#define A_STANDOUT ((chtype)0x00010000U)
#define A_UNDERLINE ((chtype)0x00020000U)
#define A_REVERSE ((chtype)0x00040000U)
#define A_BLINK ((chtype)0x00080000U)
#define A_DIM ((chtype)0x00100000U)
#define A_BOLD ((chtype)0x00200000U)
#define A_ALTCHARSET ((chtype)0x00400000U)
#define A_INVIS ((chtype)0x00800000U)
#define A_PROTECT ((chtype)0x01000000U)
#define A_HORIZONTAL ((chtype)0x02000000U)
#define A_LEFT ((chtype)0x04000000U)
#define A_LOW ((chtype)0x08000000U)
#define A_RIGHT ((chtype)0x10000000U)
#define A_TOP ((chtype)0x20000000U)
#define A_VERTICAL ((chtype)0x40000000U)
#define A_ITALIC ((chtype)0x80000000U)
#define A_ATTRIBUTES ((chtype)0xffffff00U)

#define WA_NORMAL A_NORMAL
#define WA_STANDOUT A_STANDOUT
#define WA_UNDERLINE A_UNDERLINE
#define WA_REVERSE A_REVERSE
#define WA_BLINK A_BLINK
#define WA_DIM A_DIM
#define WA_BOLD A_BOLD
#define WA_ALTCHARSET A_ALTCHARSET
#define WA_INVIS A_INVIS
#define WA_PROTECT A_PROTECT
#define WA_HORIZONTAL A_HORIZONTAL
#define WA_LEFT A_LEFT
#define WA_LOW A_LOW
#define WA_RIGHT A_RIGHT
#define WA_TOP A_TOP
#define WA_VERTICAL A_VERTICAL
#define WA_ITALIC A_ITALIC

#define COLOR_PAIR(number) \
    ((chtype)(((unsigned int)(number) << NCURSES_ATTR_SHIFT) & A_COLOR))
#define PAIR_NUMBER(attributes) \
    ((int)(((chtype)(attributes) & A_COLOR) >> NCURSES_ATTR_SHIFT))

#define KEY_CODE_YES 0400
#define KEY_MIN 0401
#define KEY_BREAK 0401
#define KEY_DOWN 0402
#define KEY_UP 0403
#define KEY_LEFT 0404
#define KEY_RIGHT 0405
#define KEY_HOME 0406
#define KEY_BACKSPACE 0407
#define KEY_F0 0410
#define KEY_F(number) (KEY_F0 + (number))
#define KEY_DL 0510
#define KEY_IL 0511
#define KEY_DC 0512
#define KEY_IC 0513
#define KEY_EIC 0514
#define KEY_CLEAR 0515
#define KEY_EOS 0516
#define KEY_EOL 0517
#define KEY_SF 0520
#define KEY_SR 0521
#define KEY_NPAGE 0522
#define KEY_PPAGE 0523
#define KEY_STAB 0524
#define KEY_CTAB 0525
#define KEY_CATAB 0526
#define KEY_ENTER 0527
#define KEY_PRINT 0532
#define KEY_LL 0533
#define KEY_A1 0534
#define KEY_A3 0535
#define KEY_B2 0536
#define KEY_C1 0537
#define KEY_C3 0540
#define KEY_BTAB 0541
#define KEY_BEG 0542
#define KEY_CANCEL 0543
#define KEY_CLOSE 0544
#define KEY_COMMAND 0545
#define KEY_COPY 0546
#define KEY_CREATE 0547
#define KEY_END 0550
#define KEY_EXIT 0551
#define KEY_FIND 0552
#define KEY_HELP 0553
#define KEY_MARK 0554
#define KEY_MESSAGE 0555
#define KEY_MOVE 0556
#define KEY_NEXT 0557
#define KEY_OPEN 0560
#define KEY_OPTIONS 0561
#define KEY_PREVIOUS 0562
#define KEY_REDO 0563
#define KEY_REFERENCE 0564
#define KEY_REFRESH 0565
#define KEY_REPLACE 0566
#define KEY_RESTART 0567
#define KEY_RESUME 0570
#define KEY_SAVE 0571
#define KEY_SBEG 0572
#define KEY_SCANCEL 0573
#define KEY_SCOMMAND 0574
#define KEY_SCOPY 0575
#define KEY_SCREATE 0576
#define KEY_SDC 0577
#define KEY_SDL 0600
#define KEY_SELECT 0601
#define KEY_SEND 0602
#define KEY_SEOL 0603
#define KEY_SEXIT 0604
#define KEY_SFIND 0605
#define KEY_SHELP 0606
#define KEY_SHOME 0607
#define KEY_SIC 0610
#define KEY_SLEFT 0611
#define KEY_SMESSAGE 0612
#define KEY_SMOVE 0613
#define KEY_SNEXT 0614
#define KEY_SOPTIONS 0615
#define KEY_SPREVIOUS 0616
#define KEY_SPRINT 0617
#define KEY_SREDO 0620
#define KEY_SREPLACE 0621
#define KEY_SRIGHT 0622
#define KEY_SRSUME 0623
#define KEY_SSAVE 0624
#define KEY_SSUSPEND 0625
#define KEY_SUNDO 0626
#define KEY_SUSPEND 0627
#define KEY_UNDO 0630
#define KEY_MOUSE 0631
#define KEY_RESIZE 0632
#define KEY_MAX 0777

#define NCURSES_MOUSE_MASK(button, event) \
    ((mmask_t)(event) << (((button) - 1) * 5))
#define NCURSES_BUTTON_RELEASED 001U
#define NCURSES_BUTTON_PRESSED 002U
#define NCURSES_BUTTON_CLICKED 004U
#define NCURSES_DOUBLE_CLICKED 010U
#define NCURSES_TRIPLE_CLICKED 020U
#define NCURSES_RESERVED_EVENT 040U

#define BUTTON1_RELEASED NCURSES_MOUSE_MASK(1, NCURSES_BUTTON_RELEASED)
#define BUTTON1_PRESSED NCURSES_MOUSE_MASK(1, NCURSES_BUTTON_PRESSED)
#define BUTTON1_CLICKED NCURSES_MOUSE_MASK(1, NCURSES_BUTTON_CLICKED)
#define BUTTON1_DOUBLE_CLICKED NCURSES_MOUSE_MASK(1, NCURSES_DOUBLE_CLICKED)
#define BUTTON1_TRIPLE_CLICKED NCURSES_MOUSE_MASK(1, NCURSES_TRIPLE_CLICKED)
#define BUTTON2_RELEASED NCURSES_MOUSE_MASK(2, NCURSES_BUTTON_RELEASED)
#define BUTTON2_PRESSED NCURSES_MOUSE_MASK(2, NCURSES_BUTTON_PRESSED)
#define BUTTON2_CLICKED NCURSES_MOUSE_MASK(2, NCURSES_BUTTON_CLICKED)
#define BUTTON2_DOUBLE_CLICKED NCURSES_MOUSE_MASK(2, NCURSES_DOUBLE_CLICKED)
#define BUTTON2_TRIPLE_CLICKED NCURSES_MOUSE_MASK(2, NCURSES_TRIPLE_CLICKED)
#define BUTTON3_RELEASED NCURSES_MOUSE_MASK(3, NCURSES_BUTTON_RELEASED)
#define BUTTON3_PRESSED NCURSES_MOUSE_MASK(3, NCURSES_BUTTON_PRESSED)
#define BUTTON3_CLICKED NCURSES_MOUSE_MASK(3, NCURSES_BUTTON_CLICKED)
#define BUTTON3_DOUBLE_CLICKED NCURSES_MOUSE_MASK(3, NCURSES_DOUBLE_CLICKED)
#define BUTTON3_TRIPLE_CLICKED NCURSES_MOUSE_MASK(3, NCURSES_TRIPLE_CLICKED)
#define BUTTON4_RELEASED NCURSES_MOUSE_MASK(4, NCURSES_BUTTON_RELEASED)
#define BUTTON4_PRESSED NCURSES_MOUSE_MASK(4, NCURSES_BUTTON_PRESSED)
#define BUTTON4_CLICKED NCURSES_MOUSE_MASK(4, NCURSES_BUTTON_CLICKED)
#define BUTTON4_DOUBLE_CLICKED NCURSES_MOUSE_MASK(4, NCURSES_DOUBLE_CLICKED)
#define BUTTON4_TRIPLE_CLICKED NCURSES_MOUSE_MASK(4, NCURSES_TRIPLE_CLICKED)
#define BUTTON5_RELEASED NCURSES_MOUSE_MASK(5, NCURSES_BUTTON_RELEASED)
#define BUTTON5_PRESSED NCURSES_MOUSE_MASK(5, NCURSES_BUTTON_PRESSED)
#define BUTTON5_CLICKED NCURSES_MOUSE_MASK(5, NCURSES_BUTTON_CLICKED)
#define BUTTON5_DOUBLE_CLICKED NCURSES_MOUSE_MASK(5, NCURSES_DOUBLE_CLICKED)
#define BUTTON5_TRIPLE_CLICKED NCURSES_MOUSE_MASK(5, NCURSES_TRIPLE_CLICKED)
#define BUTTON_CTRL NCURSES_MOUSE_MASK(6, 0001U)
#define BUTTON_SHIFT NCURSES_MOUSE_MASK(6, 0002U)
#define BUTTON_ALT NCURSES_MOUSE_MASK(6, 0004U)
#define REPORT_MOUSE_POSITION NCURSES_MOUSE_MASK(6, 0010U)
#define ALL_MOUSE_EVENTS ((mmask_t)(REPORT_MOUSE_POSITION - 1U))

#define BUTTON_RELEASE(event, button) \
    ((event) & NCURSES_MOUSE_MASK((button), NCURSES_BUTTON_RELEASED))
#define BUTTON_PRESS(event, button) \
    ((event) & NCURSES_MOUSE_MASK((button), NCURSES_BUTTON_PRESSED))
#define BUTTON_CLICK(event, button) \
    ((event) & NCURSES_MOUSE_MASK((button), NCURSES_BUTTON_CLICKED))
#define BUTTON_DOUBLE_CLICK(event, button) \
    ((event) & NCURSES_MOUSE_MASK((button), NCURSES_DOUBLE_CLICKED))
#define BUTTON_TRIPLE_CLICK(event, button) \
    ((event) & NCURSES_MOUSE_MASK((button), NCURSES_TRIPLE_CLICKED))


extern WINDOW *curscr;
extern WINDOW *newscr;
extern WINDOW *stdscr;
extern char ttytype[];
extern int COLORS;
extern int COLOR_PAIRS;
extern int COLS;
extern int ESCDELAY;
extern int LINES;
extern int TABSIZE;


extern WINDOW *initscr(void);
extern SCREEN *newterm(const char *terminal, FILE *output, FILE *input);
extern SCREEN *set_term(SCREEN *screen);
extern void delscreen(SCREEN *screen);
extern int endwin(void);
extern bool isendwin(void);
extern WINDOW *newwin(int lines, int columns, int begin_row, int begin_column);
extern WINDOW *newpad(int lines, int columns);
extern WINDOW *subwin(WINDOW *window, int lines, int columns,
                      int begin_row, int begin_column);
extern WINDOW *derwin(WINDOW *window, int lines, int columns,
                      int begin_row, int begin_column);
extern WINDOW *subpad(WINDOW *pad, int lines, int columns,
                      int begin_row, int begin_column);
extern WINDOW *dupwin(WINDOW *window);
extern int delwin(WINDOW *window);
extern int mvwin(WINDOW *window, int row, int column);
extern int mvderwin(WINDOW *window, int parent_row, int parent_column);
extern int wresize(WINDOW *window, int lines, int columns);


extern int cbreak(void);
extern int nocbreak(void);
extern int raw(void);
extern int noraw(void);
extern int echo(void);
extern int noecho(void);
extern int nl(void);
extern int nonl(void);
extern int halfdelay(int tenths);
extern int keypad(WINDOW *window, bool enabled);
extern int meta(WINDOW *window, bool enabled);
extern int intrflush(WINDOW *window, bool enabled);
extern int nodelay(WINDOW *window, bool enabled);
extern int notimeout(WINDOW *window, bool enabled);
extern void timeout(int milliseconds);
extern void wtimeout(WINDOW *window, int milliseconds);
extern int curs_set(int visibility);
extern int napms(int milliseconds);
extern int set_escdelay(int milliseconds);
extern int get_escdelay(void);
extern int typeahead(int descriptor);
extern int flushinp(void);


extern int refresh(void);
extern int wrefresh(WINDOW *window);
extern int wnoutrefresh(WINDOW *window);
extern int doupdate(void);
extern int prefresh(WINDOW *pad, int pad_row, int pad_column,
                    int screen_min_row, int screen_min_column,
                    int screen_max_row, int screen_max_column);
extern int pnoutrefresh(WINDOW *pad, int pad_row, int pad_column,
                       int screen_min_row, int screen_min_column,
                       int screen_max_row, int screen_max_column);
extern int erase(void);
extern int werase(WINDOW *window);
extern int clear(void);
extern int wclear(WINDOW *window);
extern int clrtobot(void);
extern int wclrtobot(WINDOW *window);
extern int clrtoeol(void);
extern int wclrtoeol(WINDOW *window);
extern int move(int row, int column);
extern int wmove(WINDOW *window, int row, int column);
extern int touchwin(WINDOW *window);
extern int untouchwin(WINDOW *window);
extern int touchline(WINDOW *window, int start, int count);
extern int wtouchln(WINDOW *window, int row, int count, int changed);
extern int redrawwin(WINDOW *window);
extern int wredrawln(WINDOW *window, int row, int count);
extern int scroll(WINDOW *window);
extern int scrl(int count);
extern int wscrl(WINDOW *window, int count);
extern int scrollok(WINDOW *window, bool enabled);
extern int leaveok(WINDOW *window, bool enabled);
extern int clearok(WINDOW *window, bool enabled);
extern int idlok(WINDOW *window, bool enabled);
extern void idcok(WINDOW *window, bool enabled);
extern void immedok(WINDOW *window, bool enabled);
extern int syncok(WINDOW *window, bool enabled);
extern void wsyncup(WINDOW *window);
extern void wsyncdown(WINDOW *window);
extern void wcursyncup(WINDOW *window);


extern int getattrs(const WINDOW *window);
extern int getcurx(const WINDOW *window);
extern int getcury(const WINDOW *window);
extern int getbegx(const WINDOW *window);
extern int getbegy(const WINDOW *window);
extern int getmaxx(const WINDOW *window);
extern int getmaxy(const WINDOW *window);
extern int getparx(const WINDOW *window);
extern int getpary(const WINDOW *window);
extern WINDOW *wgetparent(const WINDOW *window);
extern int wgetdelay(const WINDOW *window);
extern int wgetscrreg(const WINDOW *window, int *top, int *bottom);


extern int addch(const chtype character);
extern int waddch(WINDOW *window, const chtype character);
extern int mvaddch(int row, int column, const chtype character);
extern int mvwaddch(WINDOW *window, int row, int column,
                    const chtype character);
extern int addchnstr(const chtype *text, int count);
extern int waddchnstr(WINDOW *window, const chtype *text, int count);
extern int addchstr(const chtype *text);
extern int waddchstr(WINDOW *window, const chtype *text);
extern int addstr(const char *text);
extern int waddstr(WINDOW *window, const char *text);
extern int addnstr(const char *text, int count);
extern int waddnstr(WINDOW *window, const char *text, int count);
extern int mvaddstr(int row, int column, const char *text);
extern int mvwaddstr(WINDOW *window, int row, int column, const char *text);
extern int mvaddnstr(int row, int column, const char *text, int count);
extern int mvwaddnstr(WINDOW *window, int row, int column,
                      const char *text, int count);
extern int insch(chtype character);
extern int winsch(WINDOW *window, chtype character);
extern int insstr(const char *text);
extern int winsstr(WINDOW *window, const char *text);
extern int insnstr(const char *text, int count);
extern int winsnstr(WINDOW *window, const char *text, int count);
extern int delch(void);
extern int wdelch(WINDOW *window);
extern int deleteln(void);
extern int wdeleteln(WINDOW *window);
extern int insertln(void);
extern int winsertln(WINDOW *window);
extern int insdelln(int count);
extern int winsdelln(WINDOW *window, int count);
extern int hline(chtype character, int count);
extern int whline(WINDOW *window, chtype character, int count);
extern int vline(chtype character, int count);
extern int wvline(WINDOW *window, chtype character, int count);
extern int border(chtype left, chtype right, chtype top, chtype bottom,
                  chtype upper_left, chtype upper_right,
                  chtype lower_left, chtype lower_right);
extern int wborder(WINDOW *window, chtype left, chtype right,
                   chtype top, chtype bottom, chtype upper_left,
                   chtype upper_right, chtype lower_left,
                   chtype lower_right);
extern int box(WINDOW *window, chtype vertical, chtype horizontal);
extern int bkgd(chtype character);
extern int wbkgd(WINDOW *window, chtype character);
extern void bkgdset(chtype character);
extern void wbkgdset(WINDOW *window, chtype character);


extern int getch(void);
extern int wgetch(WINDOW *window);
extern int mvgetch(int row, int column);
extern int mvwgetch(WINDOW *window, int row, int column);
extern int ungetch(int character);
extern int getstr(char *text);
extern int wgetstr(WINDOW *window, char *text);
extern int getnstr(char *text, int count);
extern int wgetnstr(WINDOW *window, char *text, int count);
extern chtype inch(void);
extern chtype winch(WINDOW *window);
extern int inchnstr(chtype *text, int count);
extern int winchnstr(WINDOW *window, chtype *text, int count);
extern int innstr(char *text, int count);
extern int winnstr(WINDOW *window, char *text, int count);


extern int attrset(NCURSES_ATTR_T attributes);
extern int attron(NCURSES_ATTR_T attributes);
extern int attroff(NCURSES_ATTR_T attributes);
extern int wattrset(WINDOW *window, int attributes);
extern int wattron(WINDOW *window, int attributes);
extern int wattroff(WINDOW *window, int attributes);
extern int attr_get(attr_t *attributes, NCURSES_PAIRS_T *pair, void *options);
extern int attr_set(attr_t attributes, NCURSES_PAIRS_T pair, void *options);
extern int attr_on(attr_t attributes, void *options);
extern int attr_off(attr_t attributes, void *options);
extern int wattr_get(WINDOW *window, attr_t *attributes,
                     NCURSES_PAIRS_T *pair, void *options);
extern int wattr_set(WINDOW *window, attr_t attributes,
                     NCURSES_PAIRS_T pair, void *options);
extern int wattr_on(WINDOW *window, attr_t attributes, void *options);
extern int wattr_off(WINDOW *window, attr_t attributes, void *options);
extern int chgat(int count, attr_t attributes, NCURSES_PAIRS_T pair,
                 const void *options);
extern int wchgat(WINDOW *window, int count, attr_t attributes,
                  NCURSES_PAIRS_T pair, const void *options);
extern bool has_colors(void);
extern bool can_change_color(void);
extern int start_color(void);
extern int use_default_colors(void);
extern int assume_default_colors(int foreground, int background);
extern int init_pair(NCURSES_PAIRS_T pair, NCURSES_COLOR_T foreground,
                     NCURSES_COLOR_T background);
extern int pair_content(NCURSES_PAIRS_T pair, NCURSES_COLOR_T *foreground,
                        NCURSES_COLOR_T *background);
extern int init_color(NCURSES_COLOR_T color, NCURSES_COLOR_T red,
                      NCURSES_COLOR_T green, NCURSES_COLOR_T blue);
extern int color_content(NCURSES_COLOR_T color, NCURSES_COLOR_T *red,
                         NCURSES_COLOR_T *green, NCURSES_COLOR_T *blue);
extern int color_set(NCURSES_PAIRS_T pair, void *options);
extern int wcolor_set(WINDOW *window, NCURSES_PAIRS_T pair, void *options);


extern int printw(const char *format, ...);
extern int wprintw(WINDOW *window, const char *format, ...);
extern int mvprintw(int row, int column, const char *format, ...);
extern int mvwprintw(WINDOW *window, int row, int column,
                     const char *format, ...);
extern int scanw(const char *format, ...);
extern int wscanw(WINDOW *window, const char *format, ...);
extern int mvscanw(int row, int column, const char *format, ...);
extern int mvwscanw(WINDOW *window, int row, int column,
                    const char *format, ...);
extern int vw_printw(WINDOW *window, const char *format, va_list arguments);
extern int vw_scanw(WINDOW *window, const char *format, va_list arguments);
extern int vwprintw(WINDOW *window, const char *format, va_list arguments);
extern int vwscanw(WINDOW *window, const char *format, va_list arguments);


extern int addnwstr(const wchar_t *text, int count);
extern int waddnwstr(WINDOW *window, const wchar_t *text, int count);
extern int addwstr(const wchar_t *text);
extern int waddwstr(WINDOW *window, const wchar_t *text);
extern int mvaddnwstr(int row, int column, const wchar_t *text, int count);
extern int mvwaddnwstr(WINDOW *window, int row, int column,
                       const wchar_t *text, int count);
extern int get_wch(wint_t *character);
extern int wget_wch(WINDOW *window, wint_t *character);
extern int mvget_wch(int row, int column, wint_t *character);
extern int mvwget_wch(WINDOW *window, int row, int column,
                      wint_t *character);
extern int unget_wch(const wchar_t character);
extern int get_wstr(wint_t *text);
extern int wget_wstr(WINDOW *window, wint_t *text);
extern int getn_wstr(wint_t *text, int count);
extern int wgetn_wstr(WINDOW *window, wint_t *text, int count);
extern int add_wch(const cchar_t *character);
extern int wadd_wch(WINDOW *window, const cchar_t *character);
extern int add_wchnstr(const cchar_t *text, int count);
extern int wadd_wchnstr(WINDOW *window, const cchar_t *text, int count);
extern int add_wchstr(const cchar_t *text);
extern int wadd_wchstr(WINDOW *window, const cchar_t *text);
extern int ins_wch(const cchar_t *character);
extern int wins_wch(WINDOW *window, const cchar_t *character);
extern int ins_nwstr(const wchar_t *text, int count);
extern int wins_nwstr(WINDOW *window, const wchar_t *text, int count);
extern int in_wch(cchar_t *character);
extern int win_wch(WINDOW *window, cchar_t *character);
extern int in_wchnstr(cchar_t *text, int count);
extern int win_wchnstr(WINDOW *window, cchar_t *text, int count);
extern int innwstr(wchar_t *text, int count);
extern int winnwstr(WINDOW *window, wchar_t *text, int count);
extern int setcchar(cchar_t *character, const wchar_t *text,
                    const attr_t attributes, NCURSES_PAIRS_T pair,
                    const void *options);
extern int getcchar(const cchar_t *character, wchar_t *text,
                    attr_t *attributes, NCURSES_PAIRS_T *pair,
                    void *options);
extern int bkgrnd(const cchar_t *character);
extern int wbkgrnd(WINDOW *window, const cchar_t *character);
extern void bkgrndset(const cchar_t *character);
extern void wbkgrndset(WINDOW *window, const cchar_t *character);
extern int box_set(WINDOW *window, const cchar_t *vertical,
                   const cchar_t *horizontal);
extern int hline_set(const cchar_t *character, int count);
extern int whline_set(WINDOW *window, const cchar_t *character, int count);
extern int vline_set(const cchar_t *character, int count);
extern int wvline_set(WINDOW *window, const cchar_t *character, int count);


extern bool has_mouse(void);
extern int getmouse(MEVENT *event);
extern int ungetmouse(MEVENT *event);
extern mmask_t mousemask(mmask_t new_mask, mmask_t *old_mask);
extern int mouseinterval(int milliseconds);
extern bool wenclose(const WINDOW *window, int row, int column);
extern bool wmouse_trafo(const WINDOW *window, int *row, int *column,
                         bool to_screen);
extern bool mouse_trafo(int *row, int *column, bool to_screen);
extern int resize_term(int lines, int columns);
extern int resizeterm(int lines, int columns);
extern bool is_term_resized(int lines, int columns);


extern int tigetflag(const char *capability);
extern int tigetnum(const char *capability);
extern char *tigetstr(const char *capability);
extern int putp(const char *text);
extern char *tparm(const char *capability, ...);
extern char *tiparm(const char *capability, ...);
extern const char *curses_version(void);
extern const char *keyname(int character);
extern const char *key_name(wchar_t character);
extern int define_key(const char *definition, int keycode);
extern int key_defined(const char *definition);
extern int keyok(int keycode, bool enabled);
extern int use_window(WINDOW *window, NCURSES_WINDOW_CB callback, void *data);
extern int use_screen(SCREEN *screen, NCURSES_SCREEN_CB callback, void *data);





#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
_Static_assert(sizeof(short) == 2, "ncurses ABI requires 16-bit short");
_Static_assert(_Alignof(short) == 2, "short alignment must be 2");
_Static_assert(sizeof(int) == 4, "ncurses ABI requires 32-bit int");
_Static_assert(_Alignof(int) == 4, "int alignment must be 4");
_Static_assert(sizeof(void *) == 8, "ncurses ABI requires LP64 pointers");
_Static_assert(_Alignof(void *) == 8, "pointer alignment must be 8");
_Static_assert(sizeof(uint32_t) == 4, "uint32_t must be 32 bits");
_Static_assert(_Alignof(uint32_t) == 4, "uint32_t alignment must be 4");
_Static_assert(sizeof(chtype) == 4, "chtype must be 32 bits");
_Static_assert(_Alignof(chtype) == 4, "chtype alignment must be 4");
_Static_assert((chtype)-1 > (chtype)0, "chtype must be unsigned");
_Static_assert(sizeof(attr_t) == 4, "attr_t must be 32 bits");
_Static_assert(_Alignof(attr_t) == 4, "attr_t alignment must be 4");
_Static_assert(sizeof(mmask_t) == 4, "mmask_t must be 32 bits");
_Static_assert(_Alignof(mmask_t) == 4, "mmask_t alignment must be 4");
_Static_assert((mmask_t)-1 > (mmask_t)0, "mmask_t must be unsigned");
_Static_assert(sizeof(NCURSES_COLOR_T) == 2,
               "ncurses color values must be 16 bits");
_Static_assert(_Alignof(NCURSES_COLOR_T) == 2,
               "ncurses color alignment must be 2");
_Static_assert(sizeof(NCURSES_PAIRS_T) == 2,
               "ncurses pair values must be 16 bits");
_Static_assert(_Alignof(NCURSES_PAIRS_T) == 2,
               "ncurses pair alignment must be 2");
_Static_assert(sizeof(NCURSES_ATTR_T) == 4,
               "legacy ncurses attributes must be 32 bits");
_Static_assert(sizeof(wchar_t) == 4, "Linux wchar_t must be 32 bits");
_Static_assert(_Alignof(wchar_t) == 4, "wchar_t alignment must be 4");
_Static_assert((wchar_t)-1 < (wchar_t)0,
               "Linux wchar_t must be signed");
_Static_assert(sizeof(wint_t) == 4, "Linux wint_t must be 32 bits");
_Static_assert(_Alignof(wint_t) == 4, "wint_t alignment must be 4");
_Static_assert((wint_t)-1 > (wint_t)0,
               "Linux wint_t must be unsigned");
_Static_assert(sizeof(bool) == 1, "bool must use the one-byte _Bool ABI");
_Static_assert(_Alignof(bool) == 1, "bool alignment must be 1");
_Static_assert((bool)2 == (bool)1, "bool must normalize to zero or one");
_Static_assert(sizeof(mbstate_t) == 8, "Linux mbstate_t must be 8 bytes");
_Static_assert(_Alignof(mbstate_t) == 4, "mbstate_t alignment must be 4");
_Static_assert(sizeof(va_list) == 24, "SysV AMD64 va_list must be 24 bytes");
_Static_assert(_Alignof(va_list) == 8, "SysV AMD64 va_list alignment must be 8");

_Static_assert(offsetof(cchar_t, attr) == 0, "cchar_t.attr offset");
_Static_assert(offsetof(cchar_t, chars) == 4, "cchar_t.chars offset");
_Static_assert(offsetof(cchar_t, ext_color) == 24,
               "cchar_t.ext_color offset");
_Static_assert(_Alignof(cchar_t) == 4, "cchar_t alignment must be 4");
_Static_assert(sizeof(cchar_t) == 28, "cchar_t size must be 28");

_Static_assert(offsetof(MEVENT, id) == 0, "MEVENT.id offset");
_Static_assert(offsetof(MEVENT, x) == 4, "MEVENT.x offset");
_Static_assert(offsetof(MEVENT, y) == 8, "MEVENT.y offset");
_Static_assert(offsetof(MEVENT, z) == 12, "MEVENT.z offset");
_Static_assert(offsetof(MEVENT, bstate) == 16, "MEVENT.bstate offset");
_Static_assert(_Alignof(MEVENT) == 4, "MEVENT alignment must be 4");
_Static_assert(sizeof(MEVENT) == 20, "MEVENT size must be 20");

_Static_assert(A_BOLD == (chtype)0x00200000U, "A_BOLD ABI value");
_Static_assert(COLOR_PAIR(1) == (chtype)0x00000100U,
               "COLOR_PAIR shift");
_Static_assert(COLOR_PAIR(255) == A_COLOR, "COLOR_PAIR mask");
_Static_assert(BUTTON1_PRESSED == (mmask_t)0x00000002U,
               "button 1 mask");
_Static_assert(BUTTON4_PRESSED == (mmask_t)0x00010000U,
               "button 4 mask");
_Static_assert(BUTTON5_PRESSED == (mmask_t)0x00200000U,
               "button 5 mask");
#endif

#endif
