/**@file audio_emulator.c
 * @brief Device driver for the AUDIO Emulator
 *
 * A Platform device implemented using the misc subsystem
 * Devired from the vga_led.c file originally developed by Stephen A. Edwards, Columbia University
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include "audio_emulator.h"

#define DRIVER_NAME "audio_emulator"

/*
 * Information about our device
 */
struct audio_dev {
    struct resource res; /* Resource: our registers */
    void __iomem *virtbase; /* Where registers can be accessed in memory */
    u16 segments[2];
} dev;

/*
 * Write segments of a single digit
 * Assumes digit is in range and the device information has been set up
 */
static void write_digit(int digit, u16 segments)
{   
    iowrite16(segments, dev.virtbase + digit*2);
    dev.segments[digit] = segments;
}

/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long audio_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
    audio_arg_t vla;

    switch (cmd) {
    case AUDIO_WRITE_DIGIT:
        if (copy_from_user(&vla, (audio_arg_t *) arg,
                   sizeof(audio_arg_t)))
            return -EACCES;
        if (vla.digit > (2))
            return -EINVAL;
        write_digit(vla.digit, vla.segments);
        break;
    default:
        return -EINVAL;
    }

    return 0;
}

/* The operations our device knows how to do */
static const struct file_operations audio_fops = {
    .owner      = THIS_MODULE,
    .unlocked_ioctl = audio_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice audio_misc_device = {
    .minor      = MISC_DYNAMIC_MINOR,
    .name       = DRIVER_NAME,
    .fops       = &audio_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init audio_probe(struct platform_device *pdev)
{
    /*static unsigned int welcome_message[VGA_LED_DIGITS] = {
        0x003E, 0x007D};*/
    int i, ret;

    /* Register ourselves as a misc device: creates /dev/audio */
    ret = misc_register(&audio_misc_device);

    /* Get the address of our registers from the device tree */
    ret = of_address_to_resource(pdev->dev.of_node, 0, &dev.res);
    if (ret) {
        ret = -ENOENT;
        goto out_deregister;
    }

    /* Make sure we can use these registers */
    if (request_mem_region(dev.res.start, resource_size(&dev.res),
                   DRIVER_NAME) == NULL) {
        ret = -EBUSY;
        goto out_deregister;
    }

    /* Arrange access to our registers */
    dev.virtbase = of_iomap(pdev->dev.of_node, 0);
    if (dev.virtbase == NULL) {
        ret = -ENOMEM;
        goto out_release_mem_region;
    }

    return 0;

out_release_mem_region:
    release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
    misc_deregister(&audio_misc_device);
    return ret;
}

/* Clean-up code: release resources */
static int audio_remove(struct platform_device *pdev)
{
    iounmap(dev.virtbase);
    release_mem_region(dev.res.start, resource_size(&dev.res));
    misc_deregister(&audio_misc_device);
    return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id audio_of_match[] = {
    { .compatible = "altr,audio_emulator" },
    {},
};
MODULE_DEVICE_TABLE(of, audio_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver audio_driver = {
    .driver = {
        .name   = DRIVER_NAME,
        .owner  = THIS_MODULE,
        .of_match_table = of_match_ptr(audio_of_match),
    },
    .remove = __exit_p(audio_remove),
};

/* Called when the module is loaded: set things up */
static int __init audio_init(void)
{
    pr_info(DRIVER_NAME ": init\n");
    return platform_driver_probe(&audio_driver, audio_probe);
}

/* Called when the module is unloaded: release resources */
static void __exit audio_exit(void)
{
    platform_driver_unregister(&audio_driver);
    pr_info(DRIVER_NAME ": exit\n");
}

module_init(audio_init);
module_exit(audio_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Stephen A. Edwards, Columbia University");
MODULE_DESCRIPTION("Audio Emulator");
