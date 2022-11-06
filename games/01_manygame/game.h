using namespace std;

#include <vector>
#include <string>

#include "tb.h"

class Game : public App {

protected:

    vector<string> gamelist;

    int current = 0;
    int started = 0;
    int trollmode = 0;
    int trollpos  = 192;

    uint8_t* tface;

    Mix_Music* trollmus;

public:

    Game() : App(320, 200, 4) {

        gamelist.push_back("DARKWING DUCK");
        gamelist.push_back("CONTRA 1");
        gamelist.push_back("CONTRA 2");
        gamelist.push_back("MARIO BROS");
        gamelist.push_back("CHIP AND DALE 1");
        gamelist.push_back("CHIP AND DALE 2");
        gamelist.push_back("SUPER MARIO BROS");
        gamelist.push_back("NUTS AND MILK");
        gamelist.push_back("BATTLE CITY");
        gamelist.push_back("ARKANOID");
        gamelist.push_back("LODE RUNNER");
        gamelist.push_back("DUCK HUNT");
        gamelist.push_back("BATTLE TOADS");
        gamelist.push_back("ASTRIX");
        gamelist.push_back("GUNMAN");
        gamelist.push_back("TETRIS");
        gamelist.push_back("TWEEN BEE");
        gamelist.push_back("LUNNER BALL");
        gamelist.push_back("ADVENTURE ISLAND 1");
        gamelist.push_back("ADVENTURE ISLAND 2");
        gamelist.push_back("ADVENTURE ISLAND 3");
        gamelist.push_back("CLAY SHOOT");
        gamelist.push_back("ADVENTURES OF LOLO 1");
        gamelist.push_back("ADVENTURES OF LOLO 2");
        gamelist.push_back("ADVENTURES OF LOLO 3");

        trollmus = Mix_LoadMUS("src/troll.ogg");
        Mix_Volume(-1, MIX_MAX_VOLUME / 2);

        FILE* fp = fopen("src/tface.bmp", "rb");
        fseek(fp, 62, SEEK_SET);
        tface = (uint8_t*) malloc(8192);
        fread(tface, 1, 8192, fp);
        fclose(fp);
    }

    void draw_face() {

        for (int i = 0; i < 192; i++)
        for (int j = 0; j < 32; j++) {

            int cl = tface[j + i*32];
            for (int x = 0; x < 8; x++) {
                pset(x + j*8 + 40, 192 - i + trollpos, cl & (1 << (7 - x)) ? 0xFFFFFF : 0);
            }
        }
    }

    int start() {

        redraw();

        while (main()) {

            int k = kbnext();

            // Режим троллинга
            if (trollmode) {

                draw_face();
                trollpos--;
                if (trollpos < 0) trollpos = 0;

            } else {

                if (k == SDLK_DOWN) {

                    current++;

                    if (current == 17) {

                        current  = 0;
                        started += 17;
                        if (started > 9999990) started = 0;
                    }

                    redraw();
                }
                else if (k == SDLK_UP) {

                    if (current == 0) {

                        started -= 17;
                        current  = 16;
                        if (started < 0) started = 9999999 - 17;

                    } else {
                        current--;
                    }

                    redraw();
                }
                else if (k == SDLK_PAGEUP) {

                    started -= 17;
                    if (started < 0) started = 9999999 - 17;

                    redraw();
                }
                else if (k == SDLK_PAGEDOWN) {

                    started += 17;
                    if (started > 9999990) started = 0;

                    redraw();
                }
                else if (k == SDLK_RETURN) {

                    trollmode = 1;
                    Mix_PlayMusic(trollmus, 0);
                    Mix_VolumeMusic(128);
                    cls();
                }
            }
        }

        return destroy();
    }

    void redraw() {

        char tmp[48];

        cls();

        fore(0xBBBB80); nesprint(10, 1, "9999999 IN 1");
        fore(0xFD8970); nesprint(4, 3, "PUSH     OR       BUTTON");
        fore(0x86C100); nesprint( 9, 3, "SEL"); nesprint(16, 3, "START");

        for (int i = 0; i < 17; i++) {

            fore(i == current ? 0xF0F0F0 : 0xE0B000);

            int idx = started + i;
            sprintf(tmp, "%07d %s", (idx + 1), idx < gamelist.size() ? gamelist[idx].c_str() : "");
            nesprint(4, 5 + i, tmp);
        }

        fore(0xE0E080); nesprint(2, 23, "@ 2022 TROLLEYBUS GAME CARD");
        fore(0x86C100); nesprn(2, 5 + current, '>');
    }
};
