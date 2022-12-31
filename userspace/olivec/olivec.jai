//
// This file was auto-generated using the following command:
//
// jai build.jai
//



OLIVEC_AA_RES :: 2;

OLIVEC_DEFAULT_FONT_HEIGHT :: 6;
OLIVEC_DEFAULT_FONT_WIDTH :: 6;

size_t :: u64;

Olivec_Font :: struct {
    width:  size_t;
    height: size_t;
    glyphs: *u8;
}

Olivec_Canvas :: struct {
    pixels: *u32;
    width:  size_t;
    height: size_t;
    stride: size_t;
}

olivec_canvas :: (pixels: *u32, width: size_t, height: size_t, stride: size_t) -> Olivec_Canvas #foreign olivec;

olivec_subcanvas :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32) -> Olivec_Canvas #foreign olivec;

olivec_blend_color :: (c1: *u32, c2: u32) -> void #foreign olivec;

olivec_fill :: (oc: Olivec_Canvas, color: u32) -> void #foreign olivec;

olivec_rect :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32, color: u32) -> void #foreign olivec;

olivec_frame :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32, thiccness: size_t, color: u32) -> void #foreign olivec;

olivec_circle :: (oc: Olivec_Canvas, cx: s32, cy: s32, r: s32, color: u32) -> void #foreign olivec;

olivec_ellipse :: (oc: Olivec_Canvas, cx: s32, cy: s32, rx: s32, ry: s32, color: u32) -> void #foreign olivec;

// TODO: lines with different thiccness
olivec_line :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, color: u32) -> void #foreign olivec;

olivec_normalize_triangle :: (width: size_t, height: size_t, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, lx: *s32, hx: *s32, ly: *s32, hy: *s32) -> bool #foreign olivec;

// NOTE: we imply u3 = det - u1 - u2
olivec_barycentric :: (x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, xp: s32, yp: s32, u1: *s32, u2: *s32, det: *s32) -> bool #foreign olivec;

// TODO: AA for triangle
olivec_triangle :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, color: u32) -> void #foreign olivec;

olivec_triangle3c :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, c1: u32, c2: u32, c3: u32) -> void #foreign olivec;

olivec_triangle3z :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, z1: float, z2: float, z3: float) -> void #foreign olivec;

olivec_triangle3uv :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, tx1: float, ty1: float, tx2: float, ty2: float, tx3: float, ty3: float, z1: float, z2: float, z3: float, texture: Olivec_Canvas) -> void #foreign olivec;

olivec_triangle3uv_bilinear :: (oc: Olivec_Canvas, x1: s32, y1: s32, x2: s32, y2: s32, x3: s32, y3: s32, tx1: float, ty1: float, tx2: float, ty2: float, tx3: float, ty3: float, z1: float, z2: float, z3: float, texture: Olivec_Canvas) -> void #foreign olivec;

olivec_text :: (oc: Olivec_Canvas, text: *u8, x: s32, y: s32, font: Olivec_Font, size: size_t, color: u32) -> void #foreign olivec;

olivec_sprite_blend :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32, sprite: Olivec_Canvas) -> void #foreign olivec;

olivec_sprite_copy :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32, sprite: Olivec_Canvas) -> void #foreign olivec;

olivec_sprite_copy_bilinear :: (oc: Olivec_Canvas, x: s32, y: s32, w: s32, h: s32, sprite: Olivec_Canvas) -> void #foreign olivec;

// TODO: olivec_pixel_bilinear does not check for out-of-bounds
// But maybe it shouldn't. Maybe it's a responsibility of the caller of the function.
olivec_pixel_bilinear :: (sprite: Olivec_Canvas, nx: s32, ny: s32, w: s32, h: s32) -> u32 #foreign olivec;

Olivec_Normalized_Rect :: struct {
    // Safe ranges to iterate over.
    x1:  s32;
    // Safe ranges to iterate over.
    x2:  s32;
    y1:  s32;
    y2:  s32;

    // Original uncut ranges some parts of which may be outside of the canvas boundaries.
    ox1: s32;
    // Original uncut ranges some parts of which may be outside of the canvas boundaries.
    ox2: s32;
    oy1: s32;
    oy2: s32;
}

// The point of this function is to produce two ranges x1..x2 and y1..y2 that are guaranteed to be safe to iterate over the canvas of size pixels_width by pixels_height without any boundary checks.
//
// Olivec_Normalized_Rect nr = {0};
// if (olivec_normalize_rect(x, y, w, h, WIDTH, HEIGHT, &nr)) {
//     for (int x = nr.x1; x <= nr.x2; ++x) {
//         for (int y = nr.y1; y <= nr.y2; ++y) {
//             OLIVEC_PIXEL(oc, x, y) = 0x69696969;
//         }
//     }
// } else {
//     // Rectangle is invisible cause it's completely out-of-bounds
// }
olivec_normalize_rect :: (x: s32, y: s32, w: s32, h: s32, canvas_width: size_t, canvas_height: size_t, nr: *Olivec_Normalized_Rect) -> bool #foreign olivec;

mix_colors2 :: (c1: u32, c2: u32, u1: s32, det: s32) -> u32 #foreign olivec;

mix_colors3 :: (c1: u32, c2: u32, c3: u32, u1: s32, u2: s32, det: s32) -> u32 #foreign olivec;

#scope_file

olivec :: #library,no_dll "olivec";
