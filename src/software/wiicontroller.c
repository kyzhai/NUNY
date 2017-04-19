/**@file wiicontroller.c
 * @brief implementations of the functions communicating with the wiimote
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "configuration.h"
#include "wiimote.h"
#include "wiimote_api.h"


wiimote_t wii_connect()
{
    wiimote_t wiimote = WIIMOTE_INIT;

    // the address of the wiimote is fixed here
    char *bdaddr = "2C:10:C1:8F:D0:0F";

    printf("Waiting for connection. Press 1+2 to connect...\n");

    if (wiimote_connect(&wiimote, bdaddr) < 0) {
        fprintf(stderr, "unable to open wiimote: %s\n", wiimote_get_error());
        exit(1);
    }

    printf("Successfully Connected!\n");

    // turn on the leftmost led
    wiimote.led.one  = 1;

    wiimote.mode.acc = 1;

    // enable the infrared sensor
    wiimote.mode.ir = 1;

    return wiimote;
}


void wii_getpos(wiimote_t *pwiimote, unsigned int *x, unsigned int *y)
{
    unsigned int x_left_cut = (CAMERA_X_MAX - CAMERA_X)/2;
    unsigned int y_low_cut = (CAMERA_Y_MAX - CAMERA_Y)/2;

    float scale_factor = (float)CANVAS_SIZE_X / (float)CAMERA_X;

    if (wiimote_update(pwiimote) < 0) {
        wiimote_disconnect(pwiimote);
    }

    // project the cooridinates from the wiimote screen to the game screen
    unsigned int x_pos = (pwiimote->ir1.x - x_left_cut) * scale_factor;
    unsigned int y_pos = (pwiimote->ir1.y - y_low_cut) * scale_factor;

    *x = x_pos >=0 && x_pos <= CANVAS_SIZE_X ? x_pos : NOT_VALID;
    *y = y_pos >=0 && y_pos <= CANVAS_SIZE_Y ? y_pos : NOT_VALID;
}


void wii_disconnect(wiimote_t *pwiimote){
    wiimote_disconnect(pwiimote);
}


