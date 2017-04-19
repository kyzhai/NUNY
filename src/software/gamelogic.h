/**@file gamelogic.h
 * @brief the struct difinitions for the gamelogic and the exposed functions to operate on gamelogic
 */

#ifndef GAMELOGIC_H_
#define GAMELOGIC_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "configuration.h"
#include "vga_led.h"
#include "wiicontroller.h"


/**@brief encapsulate the information need for sprites
 */
typedef struct {
    bool is_on; // whether this sprite should be displayed

    double x, y; // the x, y oridinates of sprite

    double vx, vy; // the speed in x, y direction

    sprite_type my_type; // the type of the sprite

    bool is_pointed; // whether the ninja is intersect with the sprit
} sprite;


/**@brief all the information need for the game
 */
typedef struct {
    screen cur_screen;

    difficulty_level level;

    unsigned int remaining_lifes; 

    unsigned int score; 

    unsigned int time;

    unsigned int result;

    //! the current position of the ninja
    unsigned int ninja_x, ninja_y;

    //! the last known position of ninja. Used in case of signal losing 
    unsigned int last_x, last_y; 

    //! the array containing pointers to sprites
    sprite *sprites[MAX_CONCURRENT_SPRITE];
} gamelogic;


// ------- the functions operating on the game logic ----------

gamelogic *gl_init();

bool gl_update(gamelogic *pgl, wiimote_t *pwii);

void gl_start_selection(gamelogic *pgl);

void gl_end_screen(gamelogic *pgl);

void gl_reset(gamelogic *pgl);

void gl_move_ninja(gamelogic *pgl, wiimote_t *pwii);

#endif

