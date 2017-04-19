/**@file vga_led.h
 * @brief the header for the device driver for the VGA LED Emulator
 */

#ifndef _VGA_LED_H
#define _VGA_LED_H

#include <linux/ioctl.h>
#include "configuration.h"

#define VGA_LED_DIGITS 2
#define RADIUS 32

typedef struct {
    unsigned char digit;    
    unsigned int segments; 
} vga_led_arg_t;


#define VGA_LED_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_LED_WRITE_DIGIT _IOW(VGA_LED_MAGIC, 1, vga_led_arg_t *)
#define VGA_LED_READ_DIGIT  _IOWR(VGA_LED_MAGIC, 2, vga_led_arg_t *)

#endif

