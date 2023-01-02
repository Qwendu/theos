
#import "Formosa";
#import "Formosa_Utilities";
#import "Pnm";

#load "chess_engine/movegen.jai";
#load "chess_engine/search.jai";
#load "chess_engine/eval.jai";

#import "Random";

window: *u32;
window_size :: 45 * 8;
field_size :: window_size / 8;
piece_size :: 45;
pieces: Pnm;

theme: Theme;

stdin_stop_signal :: () -> bool {
    return false;
}

last_move_square: int;
selected_square: int;
move_start_square: int;

chess: ChessGame;
fifty: int;

cvt_square :: (square: int) -> int {
    x := square % 8;
    y := (63 - square) / 8;
    return x + y * 8;
}

Player :: enum {
    CEIJ;
    HUMAN;
    RANDOM;
}

depth: int;

main :: (white_pieces: Player, black_pieces: Player, _depth: int) {
    depth = _depth;

    has_computer_player := (white_pieces == .CEIJ || black_pieces == .CEIJ);

    repaint();

    if has_computer_player {
        nn, result := read_file("chess_files/nn-04cf2b4ed1da.nnue");
        if result != .success {
            write_string("Could not load neural network... exiting.\n");
            return;
        }
        defer unmap_memory(nn.count, nn.data);
        nnue_init(nn);
    }

    initialize_chess_game_memory(*chess);
    init_between_bitboards();
    init_magic_bitboards();

    clear_hash_table();

    random_seed(<< cast(*Random_State) *formosa_get_time());

    in := input();
    if in.value_pointer {
        write_string("Loading fen...\n");
        if in.type.type == .STRING {
            chess_fen(*chess, tprint("%", in));
        } else write_string("It is the wrong type!\n");
    } else {
        chess_startpos(*chess);
    }

    pieces_pnm, result := read_file("chess_files/chess_pieces.ppm");
    if result != .success {
        write_string("File could not be loaded: chess_files/chess_pieces.ppm\n");
        return;
    }

    pieces = parse_pnm(pieces_pnm);
    window_handle := create_window(window_size, window_size);
    window = get_window_buffer(window_handle);
    defer close_window(window_handle);

    theme = get_theme();

    move_start_square = -1;
    last_move_square = -1;
    draw_board();
    repaint();

    defer write_fen();
    defer sleep(conv(milliseconds_to_apollo(500)));

    while true {
        white_to_move = true;
        if !make_move(white_pieces) return;

        white_to_move = false;
        if !make_move(black_pieces) return;
    }
}

make_move :: (player: Player) -> bool {
    move: Move16;

    if player == .CEIJ {
        adjusted_depth := depth + cast(int) random_get() % 4;
        adjusted_depth = clamp(adjusted_depth, 1, 10);

        start := conv(formosa_get_time());
        move = search(*chess, clamp(adjusted_depth, 1, 10), fifty);
        sleep(conv(start - conv(formosa_get_time()) + milliseconds_to_apollo(500)));

    } else if player == .HUMAN {
        move = human_move();
    } else {
        moves_arr: [..] Move16;
        generate_moves(*chess, *moves_arr);
        index := random_get() % cast(u64) moves_arr.count;
        move = moves_arr[index];
    }

    make_move(*chess, move);
    fifty = fifty_move(*chess, move, fifty);


    type, from, to := decode_move16(move);

    using Move16;
    if type & (King_Castle | Queen_Castle | Ep_Capture) {
        draw_board();
    } else {
        old := last_move_square;
        last_move_square = cvt_square(to);
        draw_square(old);
        draw_square(last_move_square);
        draw_square(cvt_square(from));
    }

    repaint();



    if check_win_condition() return false;
    if check_for_repetition(*chess, fifty) {
        write_string("Draw! (repetition)\n");
        return false;
    }

    trivial, score := trivial_evaluation(*chess, fifty);
    if trivial && score == 0 {
        write_string("Draw! (material)\n");
        return false;
    }



    message := get_message();
    while message.kind != .NONE {
        if message.kind == .KEYBOARD {
            if message.keyboard.key == .ESCAPE {
                return false;
            }
        }
        message = get_message();
    }

    return true;
}

white_to_move: bool;

check_win_condition :: () -> bool {
    moves_arr: [..] Move16;
    generate_moves(*chess, *moves_arr);

    check := in_check(*chess.chess);
    if check && moves_arr.count == 0 {
        print("Checkmate! % wins\n", ifx white_to_move then "White" else "Black");
        return true;
    }

    if !check && moves_arr.count == 0 {
        write_string("Draw! (stalemate)\n");
        return true;
    }

    return false;
}

clamp :: (value: int, min: int, max: int) -> int {
    if value > max return max;
    if value < min return min;
    return value;
}

human_move :: () -> Move16 {
    moves_arr: [..] Move16;
    generate_moves(*chess, *moves_arr);

    need_repaint: bool;
    while true {
        // output(ifx white_to_move "White to move!" else "Black to move!");
        message := wait_for_message();

        if message.kind == .KEYBOARD {
            if message.keyboard.key == .ESCAPE {
                exit(0);
            }
            if message.keyboard.type == .RELEASED continue;
            need_repaint = true;

            old_square := selected_square;
            if message.keyboard.key == {
                case .ARROW_UP;    if selected_square >= 8 selected_square -= 8;
                case .ARROW_LEFT;  if selected_square > 0  selected_square -= 1;
                case .ARROW_RIGHT; if selected_square < 63 selected_square += 1;
                case .ARROW_DOWN;  if selected_square <= (63 - 8) selected_square += 8;
            }
            draw_square(selected_square);
            draw_square(old_square);

            if message.keyboard.key == .ENTER {
                from := cvt_square(selected_square);

                is_valid_start_square := !white_to_move && (chess.pieces[from] > .W_PAWN);
                is_valid_start_square ||= white_to_move && (chess.pieces[from] < .B_KING) && (chess.pieces[from] > .NONE);

                if is_valid_start_square {
                    old := move_start_square;
                    move_start_square = selected_square;
                    draw_square(move_start_square);
                    draw_square(old);
                    draw_square(cvt_square(from));
                } else {
                    to   := cvt_square(selected_square);
                    from := cvt_square(move_start_square);
                    move := to_move16(from, to, 0);

                    move_start_square = -1;
                    for moves_arr {
                        flags, legal_from, legal_to := decode_move16(it);
                        if legal_from == from && legal_to == to {
                            return it;
                        }
                    }
                    draw_square(cvt_square(from));
                }
            }
        } else if message.kind == .NONE {
            if need_repaint {
                repaint();
                need_repaint = false;
            }
            // yield();
        }
    }

    assert(false);
    return 0;
}

draw_board :: () {
    for 0..63 draw_square(it);
}

draw_square :: (square: int) {
    if square == -1 return;
    color: u32;
    sq_x := square % 8;
    sq_y := square / 8;

    if square == last_move_square {
        color = theme.accent;
    } else if sq_x % 2 == sq_y % 2 {
        color = theme.foreground;
    } else {
        color = theme.primary;
    }

    for y: sq_y * field_size..(sq_y + 1) * field_size - 1 for x: sq_x * field_size..(sq_x + 1) * field_size - 1 {
        index := x + y * window_size;
        window[index] = color;

        highlight_size := 10;
        HighlightSquare :: (the_square: int) #expand {
            if `square == the_square { //`
                if (`x % field_size) > (field_size - highlight_size) || (`x % field_size < highlight_size) {
                    window[index] = theme.accent;
                } else if (`y % field_size) > (field_size - highlight_size) || (`y % field_size < highlight_size) {
                    window[index] = theme.accent;
                }
            }
        }
        HighlightSquare(move_start_square);
        HighlightSquare(selected_square);
    }

    for chess.pieces {
        if cvt_square(it_index) == square {
            draw_piece(it, it_index % 8, (63 - it_index) / 8);
        }
    }
}

draw_piece :: (piece: Piece, x_field: int, y_field: int) {
    if piece == .NONE return;
    black: bool = xx piece > Piece.W_PAWN;

    start := piece;
    if black start -= 6;
    cursor: int = (xx start - 1) * piece_size * 3;

    for y: 0..pieces.height-1 {
        for x: 0..pieces.width / 6-1 {
            alpha   := cast(float) pieces.data[cursor] / 255;
            border  := cast(float) pieces.data[cursor + 1] / 255 + alpha;

            index := (x) + (y) * window_size;
            index += x_field * field_size;
            index += y_field * window_size * field_size;

            color : u32 = xx ifx black then theme.background else theme.accent;
            window[index] = blend(color, window[index], alpha);
            window[index] = blend(0x0, window[index], border);

            cursor += 3;
        }
        cursor += piece_size * 15;
    }
}

blend :: (target: u32, source: u32, t: float) -> u32 #expand {
    result: u32;
    c :: (color: u32, offset: u32) -> u32 #expand {
        return (color >> offset) & 0xff;
    }

    result  = (cast(u32) (cast(float) c(target, 16) * (1 - t) + cast(float) c(source, 16) * t)) << 16;
    result |= (cast(u32) (cast(float) c(target,  8) * (1 - t) + cast(float) c(source,  8) * t)) << 8;
    result |= (cast(u32) (cast(float) c(target,  0) * (1 - t) + cast(float) c(source,  0) * t));

    return result;
}

fifty_move :: (chess: *Chess, move: Move16, fifty: int) -> int {
    type := get_move16_flag(move);
    from := get_move16_from(move);

    piece_from := piece_at(chess, from);
    if piece_from != .W_PAWN && piece_from != .B_PAWN && type == .Quiet then {
        return fifty + 1;
    }

    return 0;
}





write_fen :: () {
    piece_table :: " KQRBNPkqrbnp";

    space: [128] u8;
    cursor: int;

    empty_count: int;
    for < chess.pieces {
        index := 63 - it_index;
        if index && index % 8 == 0 {
            if empty_count {
                space[cursor] = cast(u8) (#char "0" + empty_count);
                empty_count = 0;
                cursor += 1;
            }

            space[cursor] = #char "/";
            cursor += 1;
        }

        if it == .NONE {
            empty_count += 1;
            continue;
        } else if empty_count {
            space[cursor] = cast(u8) (#char "0" + empty_count);
            empty_count = 0;
            cursor += 1;
        }

        space[cursor] = piece_table[cast(int) it];
        cursor += 1;
    }
 
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = cast(u8) ifx white_to_move #char "w" else #char "b";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "-";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "-";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "0";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "0";

    apollo := conv(formosa_get_time());
    ct := formosa_apollo_to_calendar(apollo);
    filename := tprint("chess_files/games/%1%2%3", ct.hour, ct.minute, ct.second);

    create_file(filename);

    content: string;
    content.data = space.data;
    content.count = cursor;
    result := write_file(filename, xx content);
    if result != .success {
        write_string("Failed to save game! Could not write file.\n");
    }
}
