#import "Vulkan";

VK_CALL :: (result: VkResult) -> VkResult #expand {
    assert(result == .SUCCESS);
    return result;
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