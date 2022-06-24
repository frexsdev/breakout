const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const FPS = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @intToFloat(f32, FPS);
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const PROJ_SIZE: f32 = 25;
const PROJ_SPEED: f32 = 500;
const BAR_LEN: f32 = 100;
const BAR_THICCNESS: f32 = PROJ_SIZE;
const BAR_Y: f32 = WINDOW_HEIGHT - BAR_THICCNESS - 100;
const BAR_SPEED: f32 = PROJ_SPEED;

var quit = false;
var proj_x: f32 = 100;
var proj_y: f32 = 100;
var proj_dx: f32 = 1;
var proj_dy: f32 = 1;
var bar_x: f32 = 0;
var bar_dx: f32 = 0;
var pause = false;

fn proj_rect() c.SDL_Rect {
    return .{
        .x = @floatToInt(i32, proj_x),
        .y = @floatToInt(i32, proj_y),
        .w = PROJ_SIZE,
        .h = PROJ_SIZE,
    };
}

fn bar_rect() c.SDL_Rect {
    return .{
        .x = @floatToInt(i32, bar_x),
        .y = @floatToInt(i32, BAR_Y - BAR_THICCNESS / 2),
        .w = BAR_LEN,
        .h = BAR_THICCNESS,
    };
}

fn update(dt: f32) void {
    if (!pause) {
        bar_x += bar_dx * BAR_SPEED * dt;

        var proj_nx = proj_x + proj_dx * PROJ_SPEED * dt;
        if (proj_nx < 0 or proj_nx + PROJ_SIZE > WINDOW_WIDTH) {
            proj_dx *= -1;
            proj_nx = proj_x + proj_dx * PROJ_SPEED * dt;
        }

        var proj_ny = proj_y + proj_dy * PROJ_SPEED * dt;
        if (proj_ny < 0 or proj_ny + PROJ_SIZE > WINDOW_HEIGHT) {
            proj_dy *= -1;
            proj_ny = proj_y + proj_dy * PROJ_SPEED * dt;
        }

        if (c.SDL_HasIntersection(&proj_rect(), &bar_rect()) != 0) {
            proj_dy *= -1;
            proj_ny = proj_y + proj_dy * PROJ_SPEED * dt;
        }

        proj_x = proj_nx;
        proj_y = proj_ny;
    }
}

fn render(renderer: *c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0xF8, 0xF8, 0xF2, 0xFF);
    _ = c.SDL_RenderFillRect(renderer, &proj_rect());

    _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0x55, 0x55, 0xFF);
    _ = c.SDL_RenderFillRect(renderer, &bar_rect());
}

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("ERROR: unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("Breakout", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, 0) orelse {
        c.SDL_Log("ERROR: unable to initialize SDL window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    _ = c.SDL_SetWindowInputFocus(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("ERROR: unable to initialize SDL renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const keyboard = c.SDL_GetKeyboardState(null);

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            if (event.@"type" == c.SDL_KEYDOWN)
                switch (event.key.keysym.sym) {
                    'q', c.SDLK_ESCAPE => quit = true,
                    'p', c.SDLK_SPACE => pause = !pause,
                    else => {},
                }
            else if (event.@"type" == c.SDL_QUIT) quit = true;
        }

        bar_dx = 0;

        if (keyboard[c.SDL_SCANCODE_LEFT] != 0) bar_dx += -1 //
        else if (keyboard[c.SDL_SCANCODE_RIGHT] != 0) bar_dx += 1;

        update(DELTA_TIME_SEC);

        _ = c.SDL_SetRenderDrawColor(renderer, 0x28, 0x2A, 0x36, 0xFF);
        _ = c.SDL_RenderClear(renderer);

        render(renderer);

        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(1000 / FPS);
    }
}
