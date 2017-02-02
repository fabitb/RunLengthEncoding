#include <stdio.h> 
#include <stdlib.h>
#include <time.h>



#pragma pack(push,1)

// Explanations: https://msdn.microsoft.com/en-us/library/windows/desktop/dd183376(v=vs.85).aspx
typedef struct {
	char         bfType[2];        // The file type; must be BM.
	unsigned int bfSize;	    // The size, in bytes, of the bitmap file.
	short        bfReserved1;   //  Reserved; must be zero.
	short        bfReserved2;   //  Reserved; must be zero.
	unsigned int bfOffBits;     // The offset, in bytes, from the beginning of the BITMAPFILEHEADER structure to the bitmap bits.
} file_header;


typedef struct {
	file_header  fileheader;
	unsigned int biSize;   // The number of bytes required by the structure.
	int          biWidth;  // The width of the bitmap, in pixels.
	int          biHeight; // The height of the bitmap, in pixels. If biHeight is positive, the bitmap is a bottom-up DIB and its origin is the lower-left corner. If biHeight is negative, the bitmap is a top-down DIB and its origin is the upper-left corner.
	short        biPlanes; // The number of planes for the target device. This value must be set to 1.
	short        biBitCount;  // The number of bits-per-pixel
	unsigned int biCompression;  // The type of compression for a compressed bottom - up bitmap(top - down DIBs cannot be compressed)
	unsigned int biSizeImage;  // The size, in bytes, of the image. This may be set to zero for BI_RGB bitmaps
	int          biXPelsPerMeter; // The horizontal resolution, in pixels-per-meter, of the target device for the bitmap
	int          biYPelsPerMeter;  // The vertical resolution, in pixels-per-meter, of the target device for the bitmap.
	unsigned int biClrUsed;  // The number of color indexes in the color table that are actually used by the bitmap. Further explanation in the doc 
	unsigned int biClrImportant; // The number of color indexes that are required for displaying the bitmap. If this value is zero, all colors are required.
} info_header;

#pragma pack(pop)


typedef struct {
	info_header* pInfo;
	file_header pFile;
	unsigned char *data;
	unsigned char* colorTableData;
} bitmap;

extern int _asm_advanced_compress( char *data, char *result, int result_size, int data_width );

int foo(char* input, char *output);
int readBitmap(char* name, bitmap* bm);
int writeBitmap(char* name, bitmap* bm);
int compressM(bitmap* bm);


int foo(char* input, char *output) {


	bitmap* bmUn = (bitmap*)malloc(sizeof(bitmap));


	readBitmap(input, bmUn);

	int res = compressM(bmUn);

	writeBitmap(output, bmUn);

	// Free all the sub-pointers of our bitmap struct
	free(bmUn->pInfo);
	free(bmUn->colorTableData);
	free(bmUn->data);

	free(bmUn);

	return res;
}


int compressM(bitmap* bm) {
	//get relevant information from header
	//allocate memory space
	int imageSize = bm->pInfo->biSizeImage;
	int width = bm->pInfo->biWidth;
	unsigned char* result = (unsigned char*)malloc(sizeof(unsigned char)*imageSize);
	

	// call asm method
	// save return value ( -1 for failure or size of resul array ) in variable
	int resultSize = _asm_advanced_compress(bm->data, result, imageSize*2, width);

	printf("ASM Result: %d\n", resultSize );
	//printf("osize: %d\n", i);
	//printf("nsize: %d\n", resultIndex);

	free(bm->data);
	bm->data = (unsigned char*)malloc(sizeof(unsigned char)*resultSize);
	bm->data = result;

	// set values
	bm->pInfo->biCompression = 1;
	bm->pInfo->biSizeImage = resultSize;
	bm->pFile.bfSize = resultSize + bm->pFile.bfOffBits;

	return 0;
}




int readBitmap(char* name, bitmap* bm) {

	int n;

	//Open input file:
#pragma warning (disable : 4996)
	FILE* fp = fopen(name, "rb");
	if (fp == NULL) {
		printf("No file found.");
		return -1;
	}

	// Allocate space for the bitmap headers
	bm->pInfo = (info_header*)malloc(sizeof(info_header));
	if (bm->pInfo == NULL)
		return -1;

	// Read the info_header and file_header is encapsulated in the info_header)
	n = fread(bm->pInfo, sizeof(info_header), 1, fp);
	if (n < 1) {
		printf("headers could not be retrieved");
		return -1;
	}

	bm->pFile = bm->pInfo->fileheader;


	// Get color table size
	int structSize = bm->pInfo->biSize;
	int colorTableSize = bm->pFile.bfOffBits - structSize;

	// Allocate space for the color table
	bm->colorTableData = (unsigned char*)malloc(sizeof(unsigned char) * colorTableSize);

	// Read color table info into colorTableData
	fseek(fp, structSize, SEEK_SET);
	n = fread(bm->colorTableData, sizeof(unsigned char), colorTableSize, fp);
	if (n < 1) {
		return -1;
	}

	// Allocate space for the image data
	bm->data = (unsigned char*)malloc(sizeof(unsigned char)*bm->pInfo->biSizeImage);
	if (bm->data == NULL) {
		return -1;
	}

	// Read the image data
	fseek(fp, sizeof(unsigned char)*bm->pInfo->fileheader.bfOffBits, SEEK_SET);

	n = fread(bm->data, sizeof(unsigned char), bm->pInfo->biSizeImage, fp);
	if (n < 1) {
		return -1;
	}

	fclose(fp);

	return 0;
}

int writeBitmap(char* name, bitmap* bm) {
	int n;


	//Open output file:
#pragma warning (disable : 4996)
	FILE* out = fopen(name, "wb");
	if (out == NULL) {
		return -1;
	}


	// Write bitmaps headers
	n = fwrite(bm->pInfo, sizeof(unsigned char), sizeof(info_header), out);
	if (n < 1) {
		return -1;
	}

	// Get the color table size
	int structSize = bm->pInfo->biSize;
	int colorTableSize = bm->pFile.bfOffBits - structSize;

	// Write color table
	fseek(out, structSize, SEEK_SET);
	n = fwrite(bm->colorTableData, sizeof(unsigned char), colorTableSize, out);
	if (n < 1) {
		return -1;
	}

	// Write pixel data
	fseek(out, sizeof(unsigned char)*bm->pInfo->fileheader.bfOffBits, SEEK_SET);
	n = fwrite(bm->data, sizeof(unsigned char), bm->pInfo->biSizeImage, out);
	if (n < 1) {
		return -1;
	}

	fclose(out);




}

int main(int argc, char **argv) {

	char* input = "lena_8bpp_uncompressed.bmp";
	char* output = "lena_compInASM_testrun.bmp";

    if (argc > 1) {
        int i;
        float n = atoi(argv[1]) * 1.0;
        float sumSeconds = 0.0;
        for (i = 0; i < n; i++) {
            clock_t start = clock();
            foo(input, output);
            clock_t end = clock();
            
            
            float seconds = (float)(end - start) / CLOCKS_PER_SEC;
            sumSeconds = sumSeconds + seconds;
            //printf("Runtime: %f seconds", seconds);
            //printf("\n");
        }
        printf("Average Runtime: %f seconds", sumSeconds / n);
        printf("\n");
    }
    else {
        printf("Usage: %s MODE [args...]\n", argv[0]);
        printf("\t %s N              Durchschnittliche Laufzeit nach N Durchläufen\n", argv[0]);
    }

	return 0;
}
