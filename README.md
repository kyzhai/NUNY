NUNY
====

Ninja University in the City of New York Videogame

In this project, we design and implement a Fruit Ninja like video game on the Arrow SoCKit development board. Fruit Ninja is a popular video game where the player slices fruit with their finger(s) on a touch screen. The theme of our game will be based on undergraduate/graduate school life so that rather than slicing fruit, the object of the game will be to slice assignments, exams, thesis writing, food (like pizza), and books. The game will generate several moving objects on the screen and the player will destroy objects using an on screen ninja with a sword controlled by a wiimote controller.


NUNY has three levels to the game representing each stage of higher education (i.e. bachelors, masters, and doctorate). Each stage varies in level of difficulty, with the doctorate being the toughest to complete. The ninja student will have to earn a minimum score and have lives remaining (out of three) to pass each stage. There will be several objects appearing and disappearing from the screen and the player will have to slice certain objects in order to increase their score. There will also be objects that the player should not slice, such as the letter F, as it will cause them to lose one life. The player must slice a valid object in time before it disappears from the screen in order to obtain points, otherwise they will lose one life for each object that they do not slice in time. The entire game is won when the player completes their doctorate degree successfully.

## Directory organization:

```
src/
 |_ analysis/
    |_ hardware/
       |_ audio_mifs/
       |_ clock_pll/
       |_ db/
       |_ hc_output/
       |_ greybox_tmp/
       |_ lab3/
       |_ newnums/
       |_ hps_isw_handoff/
       |_ rbf/
       |_ mifs/
       |_ output_files/
       |_ sprites
    |_ software/
doc/

```




