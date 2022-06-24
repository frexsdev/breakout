#define HEXCOLOR(color)                                                        \
  (color >> (0 * 8)) & 0xFF, (color >> (1 * 8)) & 0xFF,                        \
      (color >> (2 * 8)) & 0xFF, (color >> (3 * 8)) & 0xFF\
