/**@file gamelogic.c
 * @brief the implementation of the exposed functions operating on the game logic
 */

#include "gamelogic.h"

//! the multipler to be applied on the possibility and speed of sprites to control the difficulty of different levels
float MULTIPLIER = 0.0;


/**@brief initialize a new sprite and give it random initial position and speed
 */
sprite *sp_init(const sprite_type spt)
{
    sprite *psp = (sprite*)malloc(sizeof(sprite));

    psp->my_type = spt;

    psp->x = rand() % CANVAS_SIZE_X;
    psp->y = CANVAS_SIZE_Y;

    psp->vx = INIT_VX[rand() % 5];
    psp->vy = -3 * INIT_VY[rand() % 5];

    psp->vx *= MULTIPLIER; // adjust speed according to the difficulty level
    psp->vy *= MULTIPLIER; 

    if(psp->x > CANVAS_SIZE_X / 2){// if the sprit comes from the right part, make it move left-ward
        psp->vx = -psp->vx;
    }

    return psp;
}


/**@brief initialize the gamelogic object
 */
gamelogic *gl_init()
{
    printf("line 9\n");
    gamelogic *pgl = (gamelogic*)malloc(sizeof(gamelogic));

    pgl->cur_screen = SELECTION;
    pgl->level = EASY;
    pgl->score = 0;
    pgl->time = 0;
    pgl->result = 0;
    pgl->remaining_lifes = 3;
    pgl->ninja_x = CANVAS_SIZE_X / 2;
    pgl->ninja_y = CANVAS_SIZE_Y / 2;

    size_t i = 0;
    for(i=0; i<MAX_CONCURRENT_SPRITE; ++i)
        pgl->sprites[i] = sp_init(i);

    return pgl;
}


/**@brief reset the value in the gamelogic module
 */
void gl_reset(gamelogic *pgl)
{
    pgl->cur_screen = SELECTION;
    pgl->level = EASY;
    pgl->score = 0;
    pgl->time = 0;
    pgl->result = 0;
    pgl->remaining_lifes = 3;
    pgl->ninja_x = CANVAS_SIZE_X / 2;
    pgl->ninja_y = CANVAS_SIZE_Y / 2;

    size_t i = 0;
    for(i=0; i<MAX_CONCURRENT_SPRITE; ++i)
        pgl->sprites[i]->is_on = false;
}


/**@brief give a sprite a new life
 */
void sp_renew(sprite *psp)
{
    psp->is_on = true;

    psp->x = rand() % CANVAS_SIZE_X;
    psp->y = CANVAS_SIZE_Y;

    psp->vx = INIT_VX[rand() % 5];
    psp->vy = -3 * INIT_VY[rand() % 5];

    psp->vx *= MULTIPLIER; // adjust speed according to the difficulty level
    psp->vy *= MULTIPLIER; 

    if(psp->x > CANVAS_SIZE_X / 2){// if the sprit comes from the right part, make it move left-ward
        psp->vx = -psp->vx;
    }

}


/**@brief update the position of the ninja (stabilized)
 */
void gl_move_ninja(gamelogic *pgl, wiimote_t *pwii)
{
    unsigned int new_x, new_y;
    wii_getpos(pwii, &(new_x), &(new_y));

    bool get_new_pos = true;
    if(new_x == 9999 || new_y == 9999){
        get_new_pos = false;
    }

    if(!get_new_pos){
        new_x = pgl->last_x;
        new_y = pgl->last_y;
    }
    else{
        pgl->last_x = new_x;
        pgl->last_y = new_y;
    }

    new_x = CANVAS_SIZE_X - new_x;

    int diff_x = (int)new_x - (int)pgl->ninja_x;
    int diff_y = (int)new_y - (int)pgl->ninja_y;

    if(diff_x > MAX_DIFF)
        pgl->ninja_x += MAX_DIFF;
    else if(diff_x < -MAX_DIFF)
        pgl->ninja_x -= MAX_DIFF;
    else
        pgl->ninja_x += diff_x;

    if(diff_y > MAX_DIFF)
        pgl->ninja_y += MAX_DIFF;
    else if(diff_y < -MAX_DIFF)
        pgl->ninja_y -= MAX_DIFF;
    else
        pgl->ninja_y += diff_y;

}


/**@brief update the state of the sprite
 *
 * update the position of the sprite according to the previous speed, position
 * and gravity
 *
 */
void sp_move(sprite *psp)
{
    //psp->x = (psp->vx + psp->x) > 640 ? 0 : (psp->vx + psp->x);

    psp->x = psp->vx + psp->x;
    if(psp->x > CANVAS_SIZE_X){
        psp->x = 2 * CANVAS_SIZE_X - psp->x;
        psp->vx = -psp->vx;
    }
    else if(psp->x < 0){
        psp->x = -psp->x;
        psp->vx = -psp->vx;
    }

    psp->y = psp->vy + psp->y;


    psp->vy = psp->vy + GRAVITY * MULTIPLIER * MULTIPLIER;
}


/**@brief whether the ninja intersects with a sprite
 */
bool is_intersect(sprite *psp, gamelogic *pgl)
{
    if(!(pgl->ninja_x < 640 && pgl->ninja_x > 0))
        return false;
    if(!(pgl->ninja_y < 480 && pgl->ninja_y > 0))
        return false;

    double sqx = (psp->x - pgl->ninja_x) * (psp->x - pgl->ninja_x);
    double sqy = (psp->y - pgl->ninja_y) * (psp->y - pgl->ninja_y);

    if((sqx + sqy) < 1000){
        return true;
    }

    return false;
}


/**@brief update the state of the gamelogic. Should be called each update of the time
 * 
 * update ninja and sprites positions
 * judge intersection, update game score, generates new sprites
 *
 * @return true if cutting an object, false otherwise
 */
bool gl_update(gamelogic *pgl, wiimote_t *pwii)
{
    bool sprite_intersected = false;

    gl_move_ninja(pgl, pwii);

    // update the position of all sprits
    size_t i=0;
    for(i=0; i<MAX_CONCURRENT_SPRITE; ++i){
        sprite *psp = pgl->sprites[i];

        if(psp == NULL || psp->is_on == false) continue;

        sp_move(psp); // update the position of sprite

        // whether sprite cut by ninja
        if(is_intersect(pgl->sprites[i], pgl)){
            psp->is_pointed = true;
            //play_sound
            sprite_intersected = true;
        }
        else{
            if(psp->is_pointed == true){ // current out of sprite, after cut by the ninja
                // update the score
                psp->is_pointed = false;
                pgl->score += SPRITE_SCORE[psp->my_type];

                if(psp->my_type == BOMB){// hit a bomb
                    pwii->rumble = 1;// enable the rumble
                    wiimote_update(pwii);

                    pgl->remaining_lifes--;

                    size_t i = 0;
                    for(i=0; i<MAX_CONCURRENT_SPRITE; ++i){
                        pgl->sprites[i]->is_on = false;
                    }

                    sleep(1);
                    pwii->rumble = 0;
                    wiimote_update(pwii);
                }

                psp->is_on = false; // once cut, disable the sprite
            }
        }

        // if a sprite falls below y == 0, remove from array
        if(psp != NULL && psp->y >= CANVAS_SIZE_Y+LOWER_THRESHOLD){
            psp->is_on = false; 

            // the sprite is moving downward
            if(psp->vy > 0 && psp->my_type != BOMB){
                pgl->remaining_lifes--;
            }
        }
    }

    // generate new sprites according to the possibility of each sprite
    for(i=0; i<MAX_CONCURRENT_SPRITE; ++i) {

        if((pgl->sprites[i])->is_on == true) continue;

        float r = (float)rand() / RAND_MAX;

        if(r < (POSSIBILITY_MUL * MULTIPLIER * POSSIBILITY_SPRITES[i])){
            sp_renew(pgl->sprites[i]);
        }
    }

    return sprite_intersected;
}


/**@brief initialize the game logic for the screen of selection
 *
 * The positions for the options currently are not configurable
 * all magic numbers here
 */
void gl_start_selection(gamelogic *pgl)
{
    size_t i;
    for(i=0; i<3; ++i){
        pgl->sprites[i] = sp_init(i);
        pgl->sprites[i]->x = POS_SELECTIONS_X[i];
        pgl->sprites[i]->y = POS_SELECTIONS_Y[i];
    }
}


/**@brief set the first sprit to show the try-again button
 */
void gl_end_screen(gamelogic *pgl)
{
    pgl->sprites[0]->is_on = true;
    pgl->sprites[0]->x = POS_TRY_AGAIN_X;
    pgl->sprites[0]->y = POS_TRY_AGAIN_Y;
}

