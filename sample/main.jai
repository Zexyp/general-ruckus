#import "Basic";

main :: () {
    log_debug("hello");
    log_info("hello");
    log_warning("hello");
    log_error("hello");
    
    // Create window
    window = create_window(xx width, xx height, "Hello Vulkan");
  
    vContext: VulkanContext;
    // Init Vulkan.
    if !init_vulkan(*vContext) {
        return;
    }
    defer deinit_vulkan(*vContext);

    // Init Surface.
    if !init_surface() {
        print("Window surface creation failed.\n");
        return;
    }
    defer deinit_surface();

    // Init Device.
    if !init_device() {
        print("Device initialization failed.\n");
        return;
    }
    defer deinit_device();    

    // Init Swapchain.
    if !init_swapchain() {
        print("Swapchain initialization failed.\n");
        return;
    }
    defer deinit_swapchain();


    // Init Render.
    init_render();
    defer deinit_render();

    quit := false;
    while !quit {
        update_window_events();

        for events_this_frame {
            if it.type == .QUIT then quit = true;
        }

        draw_frame();
    }
}

init_vulkan :: (vContext: *VulkanContext) -> bool {
    result : VkResult = .ERROR_INITIALIZATION_FAILED;
    
    // not needed
    //app_info: VkApplicationInfo;
    //app_info.apiVersion         = VK_API_VERSION_1_0;
    //app_info.pApplicationName   = "Vulkan example";
    //app_info.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    //app_info.pEngineName        = "No Engine";
    //app_info.engineVersion      = VK_MAKE_VERSION(1, 0, 0);

    print_available_extensions(vContext.*);

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
    } else {
        extensions: [0] *u8;
        // @ToDo: Non-Windows version
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

        result = vkCreateInstance(*debug_create_info, null, *state.instance);

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

        vkCreateDebugReportCallbackEXT  : PFN_vkCreateDebugReportCallbackEXT = xx vkGetInstanceProcAddr(state.instance, "vkCreateDebugReportCallbackEXT");
        vkDestroyDebugReportCallbackEXT = xx vkGetInstanceProcAddr(state.instance, "vkDestroyDebugReportCallbackEXT");
        vkDebugReportMessageEXT         : PFN_vkDebugReportMessageEXT = xx vkGetInstanceProcAddr(state.instance, "vkDebugReportMessageEXT");

        if vkCreateDebugReportCallbackEXT {
            debug_callback_create_info: VkDebugReportCallbackCreateInfoEXT;
            
            debug_callback_create_info.flags |= .INFORMATION_BIT_EXT;
            debug_callback_create_info.flags |= .WARNING_BIT_EXT;
            debug_callback_create_info.flags |= .PERFORMANCE_WARNING_BIT_EXT;
            debug_callback_create_info.flags |= .ERROR_BIT_EXT;
            debug_callback_create_info.flags |= .DEBUG_BIT_EXT;
            debug_callback_create_info.pfnCallback = debug_callback;

            vkCreateDebugReportCallbackEXT(state.instance, *debug_callback_create_info, null, *state.debug_callback_handle);
        }
    } else {
        result = vkCreateInstance(*instance_create_info, null, *state.instance);
    }

    if result != .SUCCESS {
        log_error("Vulkan initialization failed.");
        return false;
    }

    return true;
}

deinit_vulkan :: (vContext: *VulkanContext) {
    #if DEBUG {
        if vkDestroyDebugReportCallbackEXT && state.debug_callback_handle {
            vkDestroyDebugReportCallbackEXT(state.instance, state.debug_callback_handle, null);
        }
    }

    // destroy
    vkDestroyInstance(state.instance, null);
    state.instance = null;
}

init_device :: (vContext: *VulkanContext) -> bool {
    // Picking physical device
    //

    physical_devices_count: u32;
    vkEnumeratePhysicalDevices(state.instance, *physical_devices_count, null);
    physical_devices_array := NewArray(physical_devices_count, VkPhysicalDevice);
    defer free(physical_devices_array.data);
    vkEnumeratePhysicalDevices(state.instance, *physical_devices_count, physical_devices_array.data);

    log_debug("Available physical devices:");
    for device: physical_devices_array {

        device_properties: VkPhysicalDeviceProperties;
        vkGetPhysicalDeviceProperties(device, *device_properties);
        log_debug("    %", to_string(device_properties.deviceName));

        queue_family_count: u32 = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(device, *queue_family_count, null);
        queue_family_array := NewArray(queue_family_count, VkQueueFamilyProperties);
        defer free(queue_family_array.data);
        vkGetPhysicalDeviceQueueFamilyProperties(device, *queue_family_count, queue_family_array.data);

        for queue_family: queue_family_array {
            supports_present := VK_FALSE;
            vkGetPhysicalDeviceSurfaceSupportKHR(device, state.queue_family_index, state.surface, *supports_present);

            log_debug("        queue family properites: %", queue_family);

            if supports_present && (queue_family.queueFlags & .GRAPHICS_BIT) {
                log_debug("            supports present and graphics");

                // we will use this
                state.queue_family_index = cast(u32)it_index;
                state.physical_device = device;

                //break;
            }
        }

        if (state.physical_device) {
            //break;
        }
    }

    if (!state.physical_device) {
        log_error("No physical device");
        return false;
    }

    // Logical device
    //
    queue_create_info: VkDeviceQueueCreateInfo;
    queue_create_info.queueFamilyIndex = state.queue_family_index;
    queue_create_info.queueCount = 1;
    queue_create_info.pQueuePriorities = float.[1.0].data; // lul, this tells that we are very important

    device_create_info: VkDeviceCreateInfo;
    device_create_info.queueCreateInfoCount    = 1;
    device_create_info.pQueueCreateInfos       = *queue_create_info;
    
    // kámen úrazu
    //exexe: [1] *u8;
    //exexe[0] = VK_KHR_SWAPCHAIN_EXTENSION_NAME.data;
//
    //device_create_info.enabledLayerCount       = 0;
    //device_create_info.ppEnabledLayerNames     = null;
    //device_create_info.enabledExtensionCount   = exexe.count;
    //device_create_info.ppEnabledExtensionNames = exexe.data;
    //device_create_info.pEnabledFeatures = null;
    
    result := vkCreateDevice(state.physical_device, *device_create_info, null, *state.device);

    vkGetDeviceQueue(state.device, state.queue_family_index, queueIndex=0, *state.queue);

    return result == .SUCCESS;
}

deinit_device :: (vContext: *VulkanContext) {
    vkDestroyDevice(state.device, null);
}

print_available_extensions :: (vContext: VulkanContext) {
    extension_count: u32;
    vkEnumerateInstanceExtensionProperties(null, *extension_count, null);
    
    extension_array := NewArray(extension_count, VkExtensionProperties);
    defer free(extension_array.data);

    vkEnumerateInstanceExtensionProperties(null, *extension_count, extension_array.data);
    
    log_debug("Available extensions:");
    for extension_array
        log_debug("    % (%)", to_string(it.extensionName.data), it.specVersion);
}