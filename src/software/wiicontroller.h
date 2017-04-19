/**@file wiicontroller.h
 * @brief the header to the 
 */

#include "wiimote.h"
#include "wiimote_api.h"

/**@brief initialize the connection with the wiimote
 *
 * @return the handle to the wiimote
 */
wiimote_t wii_connect();

/**@brief get the current position of the wiimote
 *
 * this function need to be called periodically to keep the wiimote connected
 */
void wii_getpos(wiimote_t *, unsigned int *, unsigned int *);

/**@brief disconnect the wiimote
 */
void wii_disconnect(wiimote_t *);


