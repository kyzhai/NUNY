/**@file audio_emulator.h
 * @brief the header for the device driver for the AUDIO Emulator
 */

#ifndef _AUDIO_H
#define _AUDIO_H

#include <linux/ioctl.h>

#define AUDIO_DIGITS 2

typedef struct {
  unsigned char digit;   
  unsigned int segments; 
} audio_arg_t;

#define AUDIO_MAGIC 'q'

/* ioctls and their arguments */
#define AUDIO_WRITE_DIGIT _IOW(AUDIO_MAGIC, 1, audio_arg_t *)
#define AUDIO_READ_DIGIT  _IOWR(AUDIO_MAGIC, 2, audio_arg_t *)

#endif
