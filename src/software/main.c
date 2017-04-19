/**@file main.c
 * @brief the entry to the main function
 */

#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <poll.h>
#include <signal.h>
#include <assert.h>

#include "vga_led.h"
#include "audio_emulator.h"

#include "configuration.h"
#include "wiicontroller.h"
#include "gamelogic.h"
#include "gong.h"

#define BUFFER_SIZE     32768       // 32 KB buffers

/** Buffer format specifier. */
#define AL_FORMAT_MONO8                          0x1100
#define AL_FORMAT_MONO16                         0x1101
#define AL_FORMAT_STEREO8                        0x1102
#define AL_FORMAT_STEREO16                       0x1103

int vga_led_fd;
int audio_fd;


void write_segment_vga(gamelogic *pgl)
{
    vga_led_arg_t vla2;

    int i;
    int j = 0;

    //--------------- writing the position of ninja ---------------
    vla2.digit = j++;
    vla2.segments = pgl->ninja_x;
    if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
        perror("ioctl(VGA_LED_WRITE_DIGIT) failed ninjaX");
        return;
    }
    vla2.digit = j++;
    vla2.segments = pgl->ninja_y;
    if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
        perror("ioctl(VGA_LED_WRITE_DIGIT) failed ninjaY");
        return;
    }

    //--------------- writing the position of sprites ---------------
    for (i = 0; i < (MAX_CONCURRENT_SPRITE); i++){
        int x_tmp = 999, y_tmp = 999;
        if(pgl->sprites[i] != NULL && pgl->sprites[i]->is_on){
            x_tmp = (int)((pgl->sprites[i])->x);
            y_tmp = (int)((pgl->sprites[i])->y);
        }

        vla2.digit = j++;
        vla2.segments = x_tmp;
        if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
            perror("ioctl(VGA_LED_WRITE_DIGIT) failed spriteX");
            exit(1);
            return;
        }

        vla2.digit = j++;
        vla2.segments = y_tmp;
        if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
            perror("ioctl(VGA_LED_WRITE_DIGIT) failed spriteY");
            exit(1);
            return;
        }
    }

    assert(j == 12);
    //------------ digit[12] : current screen, win/fail game result -------------
    vla2.digit = j++;
    unsigned int b_tmp = 0x0000; // 16 bit uint
    switch (pgl->cur_screen) {
        case SELECTION:
            b_tmp = 0x0000;
            break;
        case PLAY:
            switch (pgl->level) {
                case 0:
                    b_tmp = 0x0005;
                    break;
                case 1:
                    b_tmp = 0x0009;
                    break;
                case 2:
                    b_tmp = 0x0011;
                    break;
                default: 
                    b_tmp = 0x0005;
                    break;
            }
            break;
        case RESULT:
            if (pgl->result == 0)
                b_tmp = 0x0002;
            else{
                if (pgl->level == 2)
                    b_tmp = 0x0032;
                else
                    b_tmp = 0x002E;
            }

            break;
        default:
            b_tmp = 0x0000;
            break;
    }
    vla2.segments = b_tmp;
    if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
        perror("ioctl(VGA_LED_WRITE_DIGIT) failed control segment");
        exit(1);
        return;
    }

    //------------- digit[13] : score ---------------
    vla2.digit = j++;
    vla2.segments = pgl->score; 
    if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
        perror("ioctl(VGA_LED_WRITE_DIGIT) failed score");
        exit(1);
        return;
    }
    
    //----------- digit[14] : remaining life ------------
    vla2.digit = j++;
    switch (pgl->remaining_lifes){
        case 0: b_tmp = 0x0007;
                break;
        case 1: b_tmp = 0x0006;
                break;
        case 2: b_tmp = 0x0004;
                break;
        case 3: b_tmp = 0x0000;
                break;
        default: b_tmp = 0x0000;
                 break;
    }
    vla2.segments = b_tmp;
    if (ioctl(vga_led_fd, VGA_LED_WRITE_DIGIT, &vla2)) {
        perror("ioctl(VGA_LED_WRITE_DIGIT) failed score");
        exit(1);
        return;
    }
}


void write_segment_vga_audio(const unsigned int segs[2])
{
    audio_arg_t vla;
    int i;
    for (i = 0 ; i < 2; i++) {
        vla.digit = i;
        vla.segments = segs[i];
        if (ioctl(audio_fd, AUDIO_WRITE_DIGIT, &vla)) {
            perror("ioctl(AUDIO_WRITE_DIGIT) failed");
            return;
        }
    }
}


int get_audio_data(unsigned int *audio_data)
{
	char *audio_data_file = "gong.txt";

	FILE *fp;
	char *mode = "r";
	int packets_audio_file = 0;

	unsigned int temp_audio;

	int rv = 1;
        fp = fopen(audio_data_file, mode);
        if (fp == NULL){
            printf("ERROR opening file\n");
            exit(1);
        }

	while (rv != EOF){
		rv = fscanf(fp, "%x", &temp_audio);
		if (rv != EOF){
			packets_audio_file++;
		}
		
	}
	fclose(fp);

	
	unsigned int audio_array[packets_audio_file];
	
	rv = 1;	
        fp = fopen(audio_data_file, mode);
        if (fp == NULL){
            printf("ERROR opening file\n");
            exit(1);
        }
	int c = 0;
	while (rv != EOF){
		rv = fscanf(fp, "%x", &temp_audio);
		if (rv != EOF){
			audio_array[c] = temp_audio;
			c++;
		}
		
	}
	fclose(fp);

	audio_data = audio_array;
	return packets_audio_file;
}


int main()
{
    int     rc = 0;
    int     nfds = 1;
    int     timeout = -1;
    char    buf;
    struct  pollfd fds[1];
    struct timespec current;

    bool is_sprite_intersect = false;

    int count_packets;
    int total_audio_packets = 0;
    int audio_data_index = 0;

    unsigned int *audio_data;
    int packets_audio_file = get_audio_data(&audio_data);

    wiimote_t wiimote = wii_connect();

    gamelogic *pgl = gl_init();
    srand(time(NULL));

    vga_led_arg_t vla;
    audio_arg_t ala;

    unsigned int adcur[2];
    static const char filename[] = "/dev/vga_led";
    static const char filename2[] = "/dev/audio_emulator";

    printf("VGA LED Userspace program started\n");
    if ( (vga_led_fd = open(filename, O_RDWR)) == -1) {
        fprintf(stderr, "could not open %s\n", filename);
        return -1;
    }
    if ( (audio_fd = open(filename2, O_RDWR)) == -1) {
        fprintf(stderr, "could not open %s\n", filename);
        return -1;
    }

    // ----------------------------------
    //           Selection Screen
    // ----------------------------------
TAG_SEL:
    pgl->cur_screen = SELECTION;
    gl_start_selection(pgl);
    write_segment_vga(pgl);

    while (wiimote_is_open(&wiimote)){

        gl_move_ninja(pgl, &wiimote);

        write_segment_vga(pgl);

        size_t i;
        for(i=0; i<LEVELS; ++i){
            if(is_intersect(pgl->sprites[i], pgl)){
                pgl->level = i;
                MULTIPLIER = MULTIPLIERS[i];
                break;
            }
        }

        if(i != LEVELS) // goto next screen
            break;
    }

    printf("Level Selected: %u\n", pgl->level);

    write_segment_vga(pgl);

    // ----------------------------------
    //           Game Screen
    // ----------------------------------
TAG_PLAY:
    gl_reset(pgl);

    float cur_utime = 0.0f;
    pgl->cur_screen = PLAY;
    printf("game: Current screen: %u\n", pgl->cur_screen);

    //Keep audio off by default
    adcur[0] = 0;
    write_segment_vga_audio(adcur);

    printf("game: Current Level: %u\n", pgl->level);
    while (wiimote_is_open(&wiimote) && pgl->time < GAMETIME){

        // update the gamelogic state
        is_sprite_intersect = gl_update(pgl, &wiimote);

        if(!is_sprite_intersect){
            adcur[0] = 0;
            write_segment_vga_audio(adcur);
        }
        else{
            adcur[0] = 1;
            write_segment_vga_audio(adcur);
        }

        write_segment_vga(pgl);

        if (pgl->score >= TARGET || (pgl->remaining_lifes == 0)){

            goto TAG_RES;

            if (pgl->remaining_lifes == 0)
                pgl->result = 0;
            else
                pgl->result = 1;

            pgl->cur_screen = RESULT;
            write_segment_vga(pgl);

            gl_end_screen(pgl);

            while(wiimote_is_open(&wiimote)){

                gl_move_ninja(pgl, &wiimote);
                write_segment_vga(pgl);

                if(is_intersect(pgl->sprites[0], pgl)){
                    goto TAG_SEL;
                }

            }

        }

        // ---- update time time counter ---- //
        cur_utime += 1;
        if(cur_utime >= 100){// 1 second passed, update the displayed time
            pgl->time++;
            cur_utime = 0;
        }
    }

    // ----------------------------------
    //           Result Screen
    // ----------------------------------
TAG_RES:
    if (pgl->remaining_lifes == 0)
        pgl->result = 0;
    else
        pgl->result = 1;

    pgl->cur_screen = RESULT;
    write_segment_vga(pgl);

    gl_end_screen(pgl);

    while(wiimote_is_open(&wiimote)){

        gl_move_ninja(pgl, &wiimote);
        write_segment_vga(pgl);

        if(is_intersect(pgl->sprites[0], pgl)){
            goto TAG_SEL;
        }

    }


    printf("VGA LED Userspace program terminating\n");
    return 0;
}


