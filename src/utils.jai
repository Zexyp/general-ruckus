#import "Basic";
#import "Print_Color";

log_time :: () {
    calendar := to_calendar(current_time_consensus());
    print("[%:%:%]",
        formatInt(calendar.hour, minimum_digits=2),
        formatInt(calendar.minute, minimum_digits=2),
        formatInt(calendar.second, minimum_digits=2));
}

log_debug :: (format_string: string, args: .. Any) {
    with_console_color(.CYAN, #code {
        print("[DBG]");
        log_time();
        log(format_string, ..args);
    });
}

log_info :: (format_string: string, args: .. Any) {
    print("[INF]");
    log_time();
    log(format_string, ..args);
}

log_warning :: (format_string: string, args: .. Any) {
    with_console_color(.YELLOW, #code {
        print("[WRN]");
        log_time();
        log(format_string, ..args);
    });
}

log_error :: (format_string: string, args: .. Any) {
    with_console_color(.RED, #code {
        print("[ERR]");
        log_time();
        log(format_string, ..args);
    });
}