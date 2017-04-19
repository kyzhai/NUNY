/**@file configuration.h
 * @brief the global configuration for the game
 */

#ifndef CONFIGURATION_H_
#define CONFIGURATION_H_ 

//! the resolution of the game screen
#define CANVAS_SIZE_X 640
#define CANVAS_SIZE_Y 480

//! so that a free dropping object shows in the screen for 3 secs
#define GRAVITY 0.03

//! the length of a game (in seconds)
#define GAMETIME 60

//! the target score to win a game
#define TARGET 100

//! the maximum number of concurrent sprites allowed at a same time
#define MAX_CONCURRENT_SPRITE 5

//! the maximum distance the ninja can move an each cycle, to make the sprite more stable
#define MAX_DIFF 10

//! the minimum distance to claim an intersection
#define INTERCTION_THRESHOLD 1000

//! when to claim the missing of an sprite
#define LOWER_THRESHOLD 80

//! number of different game levels
#define LEVELS 3

//! the invalid valid of coordinates
#define NOT_VALID 9999

//! different type of the objects
typedef enum {HOMEWORK, QUIZ, PROJECT, BOMB, PIZZA} sprite_type;

//! the current screen to display
typedef enum {SELECTION, PLAY, RESULT} screen;

//! the difficulty level
typedef enum {EASY, MEDIUM, HARD} difficulty_level;

//! the range of coordinates reported by wiimote
static const unsigned int CAMERA_X_MAX = 1784;
static const unsigned int CAMERA_Y_MAX = 1272;

// the range of coordinates after doing the scaling
static const unsigned int CAMERA_X = 1696;
static const unsigned int CAMERA_Y = 1272; // 4 x 3 ratio

//! the possible initial speeds for sprits
static const float INIT_VX[] = {0.7, 0.8, 0.9, 1.0, 1.2};
static const float INIT_VY[] = {1.4, 1.45, 1.6, 1.5, 1.55};

//! the possibility of generating new sprite for each type of sprites
static const double POSSIBILITY_MUL = 0.1;
static const float POSSIBILITY_SPRITES[] = {0.4, 0.1, 0.05, 0.01, 0.01};

//! the MULTIPLIER to be applied on possibility and speed to control the difficulty level
extern float MULTIPLIER;

//! the value of multiple for each difficulty level
static const float MULTIPLIERS[] = {1.0, 1.5, 2.0};

//! the score of each kind of sprite
static const int SPRITE_SCORE[] = {1, 2, 3, 0, 4};

//! the position of the difficulty selection buttons
static const int POS_SELECTIONS_X[] = {187, 287, 387};
static const int POS_SELECTIONS_Y[] = {300, 300, 300};

//! the position of the try again button
static const int POS_TRY_AGAIN_X = 481;
static const int POS_TRY_AGAIN_Y = 50;

#endif

