#ifndef EXE_OUT

#ifndef __PANOMAKERPRODLLMAIN_H__
#define __PANOMAKERPRODLLMAIN_H__

#if defined WIN32

#define DLL_EXPORT _declspec(dllexport)

#else

#define DLL_EXPORT __attribute__ ((visibility("default")))

#endif

extern "C" DLL_EXPORT int ProMakePanoramaBuf(int threadNum, int memType, void* hRawFileReader, const char* outputDir, const char* fileNo,
	int hdrSel, int outputType, int colorMode, int extendMode, int outputJpgType, int outputQuality, int stitchMode, int gyroMode, int templateMode, const char* templateFileName,
	double logoAngle, double luminance, double contrastRatio, int gammaMode, int wbMode, double wbConfB, double wbConfG, double wbConfR, double saturation, unsigned char* dbgData);

extern "C" DLL_EXPORT void* ProInitRawFileReader(unsigned char* fileBuf, int fileSize);

extern "C" DLL_EXPORT int ProUpdateRawFileReader(void* hRawFileReader, int bufWrPos);

extern "C" DLL_EXPORT int ProCleanRawFileReader(void* hRawFileReader);

extern "C" DLL_EXPORT double ProGetProgress(double lastProgress, unsigned char* dbgData);

#endif

#endif
