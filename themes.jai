
Theme :: struct {
    background: u32 = 0xff603038;
    foreground: u32 = 0xfff8f8f8;
    primary:    u32 = 0xffebbcbc;
    secondary:  u32;
    highlight:  u32 = 0xffebbcbc;
    accent:     u32 = 0xff81c44b;

    shadow: float = 1.0;
}


Thing :: struct { theme: Theme; name: string; }

themes := Thing.[
    .{
        Theme.{
            foreground = 0x00909090,
            background = 0x01000000,
            primary    = 0x0000a0a0,
            secondary  = 0x00a00000,
            highlight  = 0x0000f0ff,
            accent     = 0x00a00000,
            shadow = 0,
        },
        "theos classic"
    },
    .{
        Theme.{
            foreground = 0xffffff,
            background = 0x251c1c,
            primary    = 0xac3128,
            highlight  = 0x7d4640,
            accent     = 0x35545c,
            shadow = 1,
        },
        "simp"
    },
    . {
        Theme.{
            background = 0xffffff,
            foreground = 0x1000000,
            primary    = 0x2000000,
            secondary  = 0x5000000,
            highlight  = 0x3000000,
            accent     = 0x4000000,
            shadow = 0,
        },
        "the untheme"
    },
    . {
        Theme.{
            foreground = 0x261406,
            background = 0xffefcf,
            primary    = 0x1261406,
            highlight  = 0xe04e3b,
            accent     = 0xa33343,
            shadow = 0,
        },
        "wimey"
    },
    . {
        Theme.{
            foreground = 0xebdbb2,
            background = 0x282828,
            primary    = 0xb8bb26,
            secondary  = 0xd3869b,
            highlight  = 0xfabd2f,
            accent     = 0xfb4934,
            shadow = 1,
        },
        "gruvbox"
    },
    . {
        Theme.{
            foreground = 0x3c3836,
            background = 0xfbf1c7,
            primary    = 0x98971a,
            secondary  = 0xb16286, 
            highlight  = 0xd79921,
            accent     = 0xcc241d,
            shadow = 0,
        },
        "gruvbox light"
    },
    . {
        Theme.{
            foreground = 0xd1b897,
            background = 0x062329,
            primary    = 0x2ec09c,
            secondary  = 0x44b340,
            highlight  = 0xefefff,
            accent     = 0x8cde94,
            shadow = 1,
        },
        "naysayer"
    },
    . {
        Theme.{
            foreground = 0x243a73,
            background = 0xf2ebe9,
            primary    = 0x7c3e66,
            secondary  = 0x01a5becc,
            highlight  = 0xa5becc,
            accent     = 0x017c3e66,
            shadow = 0,
        },
        "marooned"
    },
    .{
        Theme.{
            foreground = 0xeaeaea,
            background = 0x252a34,
            primary    = 0x08d9d6,
            secondary  = 0xff2e63,
            highlight  = 0x757a8a,
            accent     = 0x01ff2e63,
            shadow = 1,
        },
        "torii"
    },
    .{
        Theme.{
            foreground = 0x252a34,
            background = 0xeaeaea,
            primary    = 0x069996,
            secondary  = 0xdf1e43,
            highlight  = 0x454a54,
            accent     = 0x01df1e43,
            shadow = 0,
        },
        "torii light"
    },
    .{
        Theme.{
            background =  0xff603038,
            foreground =  0xfff8f8f8,
            primary =     0xffebbcbc,
            secondary =   0xffe4a424,
            highlight =   0xfaebbcbc,
            accent =      0xff81c44b,
         shadow = 1.0,
        },
        "theos"
    }
];
