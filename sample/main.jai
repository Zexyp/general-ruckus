#import "Basic";
#import "String";
#import "jai-vulkan";

DEBUG :: true;

#load "../src/utils.jai";

main :: () {
    instance: VkInstance;

    if !init_vulkan(*instance) {
        return;
    }
    defer deinit_vulkan(instance);
    defer instance = null;
}

debug_callback :: (flags: VkDebugReportFlagsEXT, objType: VkDebugReportObjectTypeEXT, obj: u64, location: u64, code: s32, layerPrefix: *u8, msg: *u8, userData: *void) -> VkBool32 #c_call {
    push_context {
        print("VULKAN VALIDATION: %\n", to_string(msg));
    }
    
    return VK_FALSE;
}

debug_callback_khronos :: (messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT,
                           messageType: VkDebugUtilsMessageTypeFlagBitsEXT,
                           pCallbackData: *VkDebugUtilsMessengerCallbackDataEXT,
                           pUserData: *void) -> VkBool32 #c_call {
    push_context {
        print("VULKAN DEBUG: %\n", to_string(pCallbackData.*.pMessage));
    }
    
    return VK_FALSE;
}

debug_callback_handle : VkDebugReportCallbackEXT;

vkDestroyDebugReportCallbackEXT : PFN_vkDestroyDebugReportCallbackEXT;

init_vulkan :: (instance: *VkInstance) -> bool {
    result : VkResult = .ERROR_INITIALIZATION_FAILED;
    
    // not needed
    //app_info: VkApplicationInfo;
    //app_info.apiVersion         = VK_API_VERSION_1_0;
    //app_info.pApplicationName   = "Vulkan example";
    //app_info.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    //app_info.pEngineName        = "No Engine";
    //app_info.engineVersion      = VK_MAKE_VERSION(1, 0, 0);

    print_available_extensions();

    instance_create_info: VkInstanceCreateInfo;
    //create_info.pApplicationInfo        = *app_info;

    // windows specific
    #if OS == .WINDOWS {
        extensions: [..] *u8;

        array_add(*extensions, VK_KHR_SURFACE_EXTENSION_NAME.data);
        array_add(*extensions, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.data);

        // this is fucking stupid, can't have conditional compilation to just modify the the initializer ig
        #if DEBUG {
            array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);
            array_add(*extensions, VK_EXT_DEBUG_REPORT_EXTENSION_NAME.data);
        }
    } else #if OS == .LINUX {
        extensions: [..] *u8;

        array_add(*extensions, VK_KHR_SURFACE_EXTENSION_NAME.data);
        array_add(*extensions, VK_KHR_XLIB_SURFACE_EXTENSION_NAME.data);

        #if DEBUG {
            array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);
            array_add(*extensions, VK_EXT_DEBUG_REPORT_EXTENSION_NAME.data);
        }
    } else {
        extensions: [0] *u8;
        #assert(false);
    }


    instance_create_info.enabledExtensionCount = cast(u32)extensions.count;
    instance_create_info.ppEnabledExtensionNames = extensions.data;

    // validation layers
    #if DEBUG {
        debug_create_info := instance_create_info;
        requested_layers := *u8.[
            "VK_LAYER_KHRONOS_validation"
        ];
        debug_create_info.enabledLayerCount = requested_layers.count;
        debug_create_info.ppEnabledLayerNames = requested_layers.data;

        // VK_LAYER_KHRONOS_validation
        debug_info: VkDebugUtilsMessengerCreateInfoEXT;
        debug_info.messageSeverity = .VERBOSE_BIT_EXT | .INFO_BIT_EXT | .WARNING_BIT_EXT | .ERROR_BIT_EXT;
        debug_info.messageType = .GENERAL_BIT_EXT | .VALIDATION_BIT_EXT | .PERFORMANCE_BIT_EXT;
        debug_info.pfnUserCallback = xx debug_callback_khronos;
        
        debug_create_info.pNext = *debug_info;

        result = vkCreateInstance(*debug_create_info, null, instance);

        instance_layers_count: u32;
        vkEnumerateInstanceLayerProperties(*instance_layers_count, null);
		instance_layers_array := NewArray(instance_layers_count, VkLayerProperties);
        defer free(instance_layers_array.data);
		vkEnumerateInstanceLayerProperties(*instance_layers_count, instance_layers_array.data);

        for layer_name: requested_layers {
			layer_available := false;
			for instance_layer : instance_layers_array {
				if compare(to_string(instance_layer.layerName), to_string(layer_name)) == 0 {
					layer_available = true;
					break;
				}
			}

			if (!layer_available) {
				log_error("layer '%' is unavailable", to_string(layer_name));
                return false;
			}
		}

        if result != .SUCCESS {
            log_error("Vulkan initialization failed.");
            return false;
        }

        
    } else {
        result = vkCreateInstance(*instance_create_info, null, instance);
    }

    if result != .SUCCESS {
        log_error("Vulkan initialization failed.");
        return false;
    }

    return true;
}

deinit_vulkan :: (instance: VkInstance) {
    #if DEBUG {
        if vkDestroyDebugReportCallbackEXT && debug_callback_handle {
            vkDestroyDebugReportCallbackEXT(instance, debug_callback_handle, null);
        }
    }

    // destroy
    vkDestroyInstance(instance, null);
    instance = null;
}

print_available_extensions :: () {
    extension_count: u32;
    vkEnumerateInstanceExtensionProperties(null, *extension_count, null);
    
    extension_array := NewArray(extension_count, VkExtensionProperties);
    defer free(extension_array.data);

    vkEnumerateInstanceExtensionProperties(null, *extension_count, extension_array.data);
    
    log_debug("Available extensions:");
    for extension_array
        log_debug("    % (%)", to_string(it.extensionName.data), it.specVersion);
}