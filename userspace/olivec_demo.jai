
#import "Basic";
#import "Formosa";
#import "Formosa_Utilities";
#import "Math";

#load "olivec/olivec.jai";



main :: () {
    wh := create_window(WIDTH, HEIGHT);
    buffer := get_window_buffer(wh);
    canvas := olivec_canvas(buffer, WIDTH, HEIGHT, WIDTH);

    last := conv(formosa_get_time());
    while true {
        msg := get_message();
        while msg.kind != .NONE {
            if msg.kind == .KEYBOARD && msg.keyboard.key == .ESCAPE return;
            msg = get_message();
        }

        sleep(conv(last + milliseconds_to_apollo(33) - conv(formosa_get_time())));

        now := conv(formosa_get_time());
        dt := cast(float32) to_float64_seconds(now - last);

        vc_render(dt, canvas);
        repaint();

        last = now;
    }
}



WIDTH :: 960;
HEIGHT :: 720;
BACKGROUND_COLOR :: 0xFF181818;
CIRCLE_RADIUS :: 100;
CIRCLE_COLOR :: 0x99AA2020;

triangle_angle : float = 0;
circle_x : float = WIDTH/2;
circle_y : float = HEIGHT/2;
circle_dx : float = 100;
circle_dy : float = 100;

// PI :: cast(float) 3.14159265359;

rotate_point :: (x: *float, y: *float)
{
    dx := << x - WIDTH/2;
    dy := << y - HEIGHT/2;
    mag := sqrt(dx*dx + dy*dy);
    dir := atan2(dy, dx) + triangle_angle;
    << x = cos(dir)*mag + WIDTH/2;
    << y = sin(dir)*mag + HEIGHT/2;
}

vc_render :: (dt: float, oc: Olivec_Canvas)
{

    olivec_fill(oc, BACKGROUND_COLOR);

    // Triangle
    {
        triangle_angle += 0.5*PI*dt;

        x1: float = WIDTH/2; y1: float = HEIGHT/8;
        x2: float = WIDTH/8; y2: float = HEIGHT/2;
        x3: float = WIDTH*7/8; y3: float = HEIGHT*7/8;
        rotate_point(*x1, *y1);
        rotate_point(*x2, *y2);
        rotate_point(*x3, *y3);
        olivec_triangle3c(oc, xx x1, xx y1, xx x2, xx y2, xx x3, xx y3, 0xFF2020FF, 0xFF20FF20, 0xFFFF2020);
    }

    // Circle
    {
        x := circle_x + circle_dx*dt;
        if (x - CIRCLE_RADIUS < 0 || x + CIRCLE_RADIUS >= WIDTH) {
            circle_dx *= -1;
        } else {
            circle_x = x;
        }

        y := circle_y + circle_dy*dt;
        if (y - CIRCLE_RADIUS < 0 || y + CIRCLE_RADIUS >= HEIGHT) {
            circle_dy *= -1;
        } else {
            circle_y = y;
        }

        olivec_circle(oc, xx circle_x, xx circle_y, CIRCLE_RADIUS, CIRCLE_COLOR);
    }
}
