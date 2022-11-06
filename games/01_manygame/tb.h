#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>

#include <stdlib.h>
#include <stdio.h>

#include "font.h"

class App {
protected:

    SDL_Window*         sdl_window;
    SDL_Renderer*       sdl_renderer;
    SDL_Texture*        sdl_screen_texture;
    Uint32*             screen_buffer;

    int pticks = 0, width, height, scale;
    int keyboard[256];

    uint8_t kbid = 0;

public:

    App(int w = 640, int h = 400, int s = 2, const char* name = "SDL2 Application") {

        if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) {
            exit(1);
        }

        width = w; height = h; scale = s;

        screen_buffer = (Uint32*) malloc(w * h * sizeof(Uint32));
        sdl_window    = SDL_CreateWindow(name, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, s*w, s*h, SDL_WINDOW_SHOWN);
        sdl_renderer  = SDL_CreateRenderer(sdl_window, -1, SDL_RENDERER_PRESENTVSYNC);
        sdl_screen_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_BGRA32, SDL_TEXTUREACCESS_STREAMING, w, h);
        SDL_SetTextureBlendMode(sdl_screen_texture, SDL_BLENDMODE_NONE);
        Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 4096);
    }

    // Реализация фрейма
    virtual void frame() { }

    // Следующая клавиша
    int kbnext() {

        if (kbid == 0) return 0;

        int r = keyboard[0];
        kbid--;

        for (int i = 0; i < kbid; i++) {
            keyboard[i] = keyboard[i+1];
        }

        return r;
    }

    // Ожидание событий
    int main() {

        SDL_Event evt;

        for (;;) {

            Uint32 ticks = SDL_GetTicks();

            // Обработать все новые события
            while (SDL_PollEvent(& evt)) {

                switch (evt.type) {

                    case SDL_QUIT:      return 0;
                    case SDL_KEYDOWN:   keyboard[ kbid++ ] = evt.key.keysym.sym; break;
                }
            }

            // Истечение таймаута: обновление экрана
            if (ticks - pticks >= 20) {

                pticks = ticks;

                frame();
                update();

                return 1;
            }

            SDL_Delay(1);
        }
    }

    void cls(uint32_t color = 0) {

        for (int x = 0; x < height * width; x++)
            screen_buffer[x] = color;
    }

    // Обновить экран
    void update() {

        SDL_Rect dstRect;

        dstRect.x = 0;
        dstRect.y = 0;
        dstRect.w = scale * width;
        dstRect.h = scale * height;

        SDL_UpdateTexture       (sdl_screen_texture, NULL, screen_buffer, width * sizeof(Uint32));
        SDL_SetRenderDrawColor  (sdl_renderer, 0, 0, 0, 0);
        SDL_RenderClear         (sdl_renderer);
        SDL_RenderCopy          (sdl_renderer, sdl_screen_texture, NULL, &dstRect);
        SDL_RenderPresent       (sdl_renderer);
    }

    // Установка точки
    void pset(int x, int y, Uint32 color) {

        if (x < 0 || y < 0 || x > width || y >= height)
            return;

        screen_buffer[y*width + x] = color;
    }

    // Удалить окно
    int destroy() {

        free(screen_buffer);

        Mix_CloseAudio();

        SDL_DestroyTexture  (sdl_screen_texture);
        SDL_DestroyRenderer (sdl_renderer);
        SDL_DestroyWindow   (sdl_window);
        SDL_Quit();

        return 0;
    }
};
