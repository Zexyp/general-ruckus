#import "Vulkan";

VK_CALL :: (result: VkResult) -> VkResult #expand {
    assert(result == .SUCCESS);
    return result;
}