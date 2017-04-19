/**@file readogg.c
 * @brief Decodes Ogg files
 * 
 * Decodes Ogg files using Ogg Vorbis SDK. Partially converts to MIF format.
 * Original code written by Anthony Yuen, 
 * http://archive.gamedev.net/archive/reference/articles/article2031.html   
 * Modified by Van Bui                                
 */

#include <stdio.h>
#include <string.h>

#include <vorbis/vorbisfile.h>

#define BUFFER_SIZE     32768       // 32 KB buffers

/** Buffer format specifier. */
#define AL_FORMAT_MONO8                          0x1100
#define AL_FORMAT_MONO16                         0x1101
#define AL_FORMAT_STEREO8                        0x1102
#define AL_FORMAT_STEREO16                       0x1103

#define BIG_ENDIAN

int LoadOGG(char *fileName, char *buffer, int *format, int *freq)
{
  int endian = 1;                // 0 for Little-Endian, 1 for Big-Endian
  int bitStream;
  long bytes;
  char array[BUFFER_SIZE];        // Local fixed size array
  FILE *f;
  int i;
  int offset;
  int numbytes;

  numbytes=0;
  offset=0;

  // Open for binary reading
  f = fopen(fileName, "rb");

  if (f == NULL)
   {
     printf( "Cannot open file!\n");
     exit(-1);
   }
  // end if

  vorbis_info *pInfo;
  OggVorbis_File oggFile;

  // Try opening the given file
  if (ov_open(f, &oggFile, NULL, 0) != 0)
    {
      printf( "Error opening file for decoding...");
      exit(-1);
    }
  // end if

 // Get some information about the OGG file
  pInfo = ov_info(&oggFile, -1);

  // Check the number of channels... always use 16-bit samples
  if (pInfo->channels == 1)
    *format = AL_FORMAT_MONO16;
  else
    *format = AL_FORMAT_STEREO16;
  // end if

  // The frequency of the sampling rate
  *freq = pInfo->rate;

  // Keep reading until all is read
  do
    {
      // Read up to a buffer's worth of decoded sound data
      bytes = ov_read(&oggFile, array, BUFFER_SIZE, endian, 2, 1, &bitStream);
      
      if (bytes < 0)
	{
            ov_clear(&oggFile);
            printf("Error decoding file...\n");
            exit(-1);
	}
      // end if

      // Append to end of buffer
      for (i=0; i < bytes; i++)
	buffer[i+offset]=array[i];
      
      numbytes=numbytes+bytes;
      offset = offset+bytes;

    }
  
  while (bytes > 0);

  // Clean up!
  ov_clear(&oggFile);

  return numbytes;
}


int main(int argc, char** argv)
{

    int i,j;
    int format;                         // The sound data format
    int freq;                           // The frequency of the sound data
    char bufferData[BUFFER_SIZE*100];   // The sound buffer data from file
    int numbytes;

    numbytes = LoadOGG("bomb.ogg", bufferData, &format, &freq);
    
    j=0;

    for (i=0; i < numbytes/2; i+=4) {
      printf("%4d :%13u;\n", j, (bufferData[i] << 8) + bufferData[i+2]);
      j++;
    }

    return 0;
}
