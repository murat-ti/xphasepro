/*
* Copyright (C)2018-2021 Beijing XiangFengMingTian Technology Inc. All Rights Reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice,
*   this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice,
*   this list of conditions and the following disclaimer in the documentation
*   and/or other materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS",
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include "PanoMaker/DPPanoMakerProDLLMain.h"

#define MAX_PATH 260

int g_progress = 0;

using namespace std;

/* Struct holding stitching environment */
typedef struct TagStitchEnvironment
{
    char outputDir[MAX_PATH + 16];
    char oriID[20];
    int hdrSel;
    int jpgQuality;
    int outputType;
    int evenMode;
    int sceneMode;
    int gyroMode;
    int wbMode;
    double wbConfB;
    double wbConfG;
    double wbConfR;
    double luminance;
    double contrast;
    int gammaMode;
    pthread_t hThread;
    int stitchResult;
    void* hRawFileReader;
    unsigned char dbgData[256];
} StitchEnvironment;

typedef struct TagRawImageInfo
{
    int deviceId;
    int infoVersion;
    int shootDateYear;
    int shootDateMon;
    int shootDateDay;
    int shootTimeHour;
    int shootTimeMin;
    int shootTimeSec;
    int shootTimeMS;
    int shootIdx;
    int shutterLines0;
    int totalLines0;
    int totalRows0;
    int gain0;
    int shutterLines1;
    int totalLines1;
    int totalRows1;
    int gain1;
    int shutterLines2;
    int totalLines2;
    int totalRows2;
    int gain2;
    int pclkFreq;
    int fNo;
    int focus;
    int focus35mm;
    int evBiasMode;
    int isoMode;
    int hdrMode;
    int wbMode;
    int colorMode;
    int contrastMode;
    int sharpnessMode;
    int oriQuality;
    int pnoQuality;
    int filterMode;
    int twoHalfMode;
    int antiFlickerMode;
    int timerMode;
    int multiShootMode;
    int prevCamIdx;
    int prevExpos;
    int vertexX;
    int vertexY;
    int longitude;
    int latitude;
    int shutterLines3;
    int totalLines3;
    int totalRows3;
    int gain3;
    int shutterLines4;
    int totalLines4;
    int totalRows4;
    int gain4;
    int shutterLines5;
    int totalLines5;
    int totalRows5;
    int gain5;
    int reserve[6];
} RawImageInfo;

void Sleep(u_int32_t ms)
{
    usleep(ms * 1000);
}

/* Stitching should be in a separate thread */
void* StitchThread(void* param)
{
    StitchEnvironment * stitchEnv = (StitchEnvironment *)param;
    stitchEnv->stitchResult = ProMakePanoramaBuf(4, 0, stitchEnv->hRawFileReader, stitchEnv->outputDir,
                                                 stitchEnv->oriID, stitchEnv->hdrSel, stitchEnv->outputType, stitchEnv->evenMode * 2 + ((stitchEnv->outputType == 2) ? 0 : 1), 0,
                                                 1, stitchEnv->jpgQuality, stitchEnv->sceneMode, stitchEnv->gyroMode, 0, "",
                                                 -1, stitchEnv->luminance, stitchEnv->contrast, stitchEnv->gammaMode,
                                                 stitchEnv->wbMode, stitchEnv->wbConfB, stitchEnv->wbConfG, stitchEnv->wbConfR, 1.0, stitchEnv->dbgData);
    stitchEnv->hThread = 0;
    return (void*)((long)(stitchEnv->stitchResult));
}

/* Create a thread for stitching */
bool StartStitch(StitchEnvironment * stitchEnv)
{
    int rlt = pthread_create(&stitchEnv->hThread, NULL, StitchThread, stitchEnv);
    if(rlt == 0)
    {
        return true;
    }
    else
    {
        stitchEnv->hThread = 0;
        return false;
    }
}

/* Wait for end of the stitching thread */
void WaitStitchEnd(StitchEnvironment * stitchEnv)
{
    pthread_t hThread = stitchEnv->hThread;
    if(stitchEnv->hThread != 0)
    {
        pthread_join(hThread, NULL);
        stitchEnv->hThread = 0;
    }
}

/* Send a stop signal and wait for end of the stitching thread */
void StopStitch(StitchEnvironment * stitchEnv)
{
    if(stitchEnv->hRawFileReader != NULL)
    {
        ProUpdateRawFileReader(stitchEnv->hRawFileReader, -1);
        WaitStitchEnd(stitchEnv);
    }
}

/* Allocate buffer for error message */
char* SetErrorMessage(int* responseSize, int* responseStatus, const char* errMsg)
{
    int msgLen = (int)strlen(errMsg);
    char* responseBuf = new char[msgLen + 1];
    *responseSize = msgLen;
    *responseStatus = -1;
    memcpy(responseBuf, errMsg, msgLen + 1);
    return responseBuf;
}

/* Receive a line from http socket */
int GetLine(char *buf, int size, int socket)
{
    int i = 0;
    char c = '\0';
    int n;

    while((i < size - 1) && (c != '\n'))
    {
        n = (int)recv(socket, &c, 1, 0);
        while(n < 0 && (errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN))
        {
            n = (int)recv(socket, &c, 1, 0);
        }
        if(n > 0)
        {
            if(c == '\r')
            {
                n = (int)recv(socket, &c, 1, MSG_PEEK);
                if((n > 0) && (c == '\n'))
                {
                    recv(socket, &c, 1, 0);
                }
                else
                {
                    c = '\n';
                }
            }
            buf[i] = c;
            i++;
        }
        else
        {
            c = '\n';
        }
    }
    buf[i] = '\0';

    return i;
}

/* Communicate with camera through http
   While getting the ori file, stitch ori file to generate jpg, png or dng panorama*/
char* HttpGet(int* responseSize, int* responseStatus, const char* requestParam, StitchEnvironment * stitchEnv)
{
    bool modeGetOri = (strstr(requestParam, "get_file") != NULL);
    if(modeGetOri && stitchEnv == NULL)
    {
        return SetErrorMessage(responseSize, responseStatus, "ERROR stitchEnv is NULL");
    }

    int requestPort = modeGetOri ? 8081 : 8080;
    char requestIP[] = "192.168.6.1";
    char requestHttpHead[1024];
    snprintf(requestHttpHead, sizeof(requestHttpHead), "GET /%s HTTP/1.1\r\n\r\n", requestParam);
    struct sockaddr_in servAddr;
    memset(&servAddr, 0, sizeof(servAddr));
    servAddr.sin_family = AF_INET;
    servAddr.sin_port = htons(requestPort);
    inet_pton(AF_INET, requestIP, &servAddr.sin_addr);

    int sock = -1;
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if(sock < 0)
    {
        return SetErrorMessage(responseSize, responseStatus, "ERROR socket()");
    }

    int timeout = 2000;
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (char*)&timeout, sizeof(int));
    timeout = 2000;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout, sizeof(int));

    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);
    int rlt = connect(sock, (struct sockaddr*)&servAddr, sizeof(servAddr));
    if(rlt < 0)
    {
        if (errno != EINPROGRESS)
        {
            close(sock);
            return SetErrorMessage(responseSize, responseStatus, "ERROR connect()");
        }
        fd_set rset, wset;
        FD_ZERO(&rset);
        FD_SET(sock, &rset);
        wset = rset;
        struct timeval tval;
        tval.tv_sec = 1;
        tval.tv_usec = 0;
        if (select(sock + 1, &rset, &wset, NULL, &tval) == 0)
        {
            close(sock);
            return SetErrorMessage(responseSize, responseStatus, "ERROR connect() Timeout");
        }
        if (FD_ISSET(sock, &rset) || FD_ISSET(sock, &wset))
        {
            int error = 0;
            socklen_t len = sizeof(error);
            if(getsockopt(sock, SOL_SOCKET, SO_ERROR, (char*)&error, &len) < 0 || error != 0)
            {
                close(sock);
                return SetErrorMessage(responseSize, responseStatus, "ERROR connect() getsockopt");
            }
        }
    }

    fcntl(sock, F_SETFL, flags);

    rlt = (int)send(sock, requestHttpHead, (int)(strlen(requestHttpHead)), MSG_NOSIGNAL);
    if(rlt < 0)
    {
        close(sock);
        return SetErrorMessage(responseSize, responseStatus, "ERROR send()");
    }

    *responseSize = 0;

    char buf[65536];
    int readSize = GetLine(buf, sizeof(buf), sock);
    while((readSize > 0) && strcmp("\n", buf))  /* read & discard headers */
    {
        char* key = strstr(buf, "HTTP/1.");
        if(key != NULL)
        {
            *responseStatus = atoi(key + 9);
        }
        key = strstr(buf, "Content-Length:");
        if(key != NULL)
        {
            *responseSize = atoi(key + 15);
        }

        readSize = GetLine(buf, sizeof(buf), sock);
    }

    if(readSize > 0)
    {
        int remainSize = *responseSize;
        if(modeGetOri && (remainSize < 5 * 1024 * 1024 || remainSize > 1000 * 1024 * 1024))
        {
            close(sock);
            return SetErrorMessage(responseSize, responseStatus, "ERROR ORI File Size");
        }

        char* responseBuf = new char[remainSize + 1];
        char* responsePtr = responseBuf;
        g_progress = 0;

        if(modeGetOri)
        {
            memset(responseBuf, 0, remainSize);
            stitchEnv->hRawFileReader = ProInitRawFileReader((unsigned char*)responseBuf, remainSize);
            if(stitchEnv->hRawFileReader != NULL)
            {
                StartStitch(stitchEnv);
            }
        }

        while(remainSize > 0)
        {
            int needSize = (remainSize < (int)sizeof(buf)) ? remainSize : (int)sizeof(buf);
            int recvSize = (int)recv(sock, buf, needSize, 0);
            if(recvSize > 0)
            {
                memcpy(responsePtr, buf, recvSize);
                responsePtr += recvSize;
                remainSize -= recvSize;

                if(modeGetOri && stitchEnv->hRawFileReader != NULL)
                {
                    ProUpdateRawFileReader(stitchEnv->hRawFileReader, (int)(responsePtr - responseBuf));
                }
            }
            else if(recvSize == 0)
            {
                close(sock);
                if(modeGetOri)
                {
                    StopStitch(stitchEnv);
                }
                delete[] responseBuf;
                return SetErrorMessage(responseSize, responseStatus, "ERROR socked closed");
            }
            else if(recvSize < 0 && !(errno == EINTR || errno == EWOULDBLOCK || errno == EAGAIN))
            {
                close(sock);
                if(modeGetOri)
                {
                    StopStitch(stitchEnv);
                }
                delete[] responseBuf;
                return SetErrorMessage(responseSize, responseStatus, "ERROR recv Body");
            }

            if(modeGetOri)
            {
                if((stitchEnv->stitchResult != -1000))
                {
                    close(sock);
                    if(modeGetOri)
                    {
                        StopStitch(stitchEnv);
                    }
                    delete[] responseBuf;
                    return SetErrorMessage(responseSize, responseStatus, "ERROR Stitch");
                }
                else if(stitchEnv->hRawFileReader != NULL)
                {
                    double progress = ProGetProgress(g_progress * 0.0001 + 0.0000000000001, stitchEnv->dbgData);
                    g_progress = (int)(progress * 10000 + 0.5);
                }
            }
        }
        *responsePtr = 0;
        close(sock);
        if(modeGetOri)
        {
            while(stitchEnv->stitchResult == -1000)
            {
                double progress = ProGetProgress(g_progress * 0.0001 + 0.0000000000001, stitchEnv->dbgData);
                g_progress = (int)(progress * 10000 + 0.5);
                Sleep(100);
            }

            ProCleanRawFileReader(stitchEnv->hRawFileReader);
            stitchEnv->hRawFileReader = NULL;
            WaitStitchEnd(stitchEnv);

            if(stitchEnv->stitchResult != 0)
            {
                delete[] responseBuf;
                return SetErrorMessage(responseSize, responseStatus, "ERROR Stitch");
            }
        }
        return responseBuf;
    }
    else
    {
        close(sock);
        return SetErrorMessage(responseSize, responseStatus, "ERROR recv Header");
    }
}

string ExifFromRawImageInfo(RawImageInfo* rawImgInfo)
{
    bool isHdr3 = rawImgInfo->hdrMode <= 3;
    bool isAuto = rawImgInfo->hdrMode % 2 == 0;
    int gain, shutterLines, totalRows;
    if (isHdr3)
    {
        gain = rawImgInfo->gain1;
        shutterLines = rawImgInfo->shutterLines1;
        totalRows = rawImgInfo->totalRows1;
    }
    else
    {
        gain = rawImgInfo->gain3;
        shutterLines = rawImgInfo->shutterLines3;
        totalRows = rawImgInfo->totalRows3;
    }

    string hdrNumStr = (rawImgInfo->hdrMode <= 3) ? "3" : ((rawImgInfo->hdrMode <= 5) ? "6" : "6+");
    int isoSpeed = gain * 100 / 16;
    int evBiasMode = rawImgInfo->evBiasMode;
    double shutterTime = shutterLines * totalRows / 120000000.0;
    string GpsStr = (rawImgInfo->longitude == 0 && rawImgInfo->latitude == 0) ? "NO" : "OK";
    char exifInfoBuf[256];
    char shutterTimeBuf[256];
    char evBiasModeBuf[256];
    if (shutterTime <= 0.01)
    {
        snprintf(shutterTimeBuf, 256, "1/%ds", (int)(1.0 / shutterTime + 0.5));
    }
    else if (shutterTime <= 1.0 / 10)
    {
        snprintf(shutterTimeBuf, 256, "1/%1.1fs", 1.0 / shutterTime);
    }
    else
    {
        snprintf(shutterTimeBuf, 256, "%1.5fs", shutterTime);
    }
    if (isAuto)
    {
        if (evBiasMode >= 0)
        {
            if (evBiasMode % 3 == 0)
            {
                snprintf(evBiasModeBuf, 256, "EV+%d", evBiasMode / 3);
            }
            else
            {
                snprintf(evBiasModeBuf, 256, "EV+%d/3", evBiasMode);
            }
        }
        else
        {
            if (evBiasMode % 3 == 0)
            {
                snprintf(evBiasModeBuf, 256, "EV%d", evBiasMode / 3);
            }
            else
            {
                snprintf(evBiasModeBuf, 256, "EV%d/3", evBiasMode);
            }
        }
    }
    else
    {
        snprintf(evBiasModeBuf, 256, "Manual");
    }
    snprintf(exifInfoBuf, 256, "%s\nISO%d\n%s\nHDR%s\nGPS %s", shutterTimeBuf, isoSpeed, evBiasModeBuf, hdrNumStr.c_str(), GpsStr.c_str());

    return string(exifInfoBuf);
}

string getResponseCore(char* requestStr)
{
    string responseStr;

    StitchEnvironment stitchEnv;
    strcpy(stitchEnv.oriID, "2020-02-03_12-04-05");
    strcpy(stitchEnv.outputDir, "/");
    stitchEnv.hdrSel = 10;
    stitchEnv.jpgQuality = 90;
    stitchEnv.outputType = 0;
    stitchEnv.evenMode = 0;
    stitchEnv.sceneMode = 0;
    stitchEnv.gyroMode = 0;
    stitchEnv.wbMode = 0;
    stitchEnv.wbConfB = 1.0;
    stitchEnv.wbConfG = 1.0;
    stitchEnv.wbConfR = 1.0;
    stitchEnv.luminance = 1.2;
    stitchEnv.contrast = 1.3;
    stitchEnv.gammaMode = 1;
    stitchEnv.hThread = 0;
    stitchEnv.stitchResult = -1000;
    stitchEnv.hRawFileReader = NULL;
    memset(stitchEnv.dbgData, 0, sizeof(stitchEnv.dbgData));
    int capDelay = 0;
    int autoMode = 0;
    int hdrMode = 0;
    int strobeMode = 0;
    int timelapse = 0;
    int isoMode = 0;
    int capEv = 128;
    int exposure = 20000;
    int iso = 100;
    int longitude = 0;
    int latitude = 0;

    char* command = NULL;
    char* para = NULL;

    char* requestPtr = requestStr;
    char* space = strstr(requestPtr, " ");
    if (space == NULL)
    {
        return "ERROR";
    }
    *space = '\0';
    command = requestPtr;
    requestPtr = space + 1;
    space = strstr(requestPtr, " ");
    while (space != NULL)
    {
        *space = '\0';
        if(strlen(requestPtr) > 3)
        {
            para = requestPtr;
            char* value = strstr(para, ":");
            if(value != NULL && value != para && *(value + 1) != 0)
            {
                *value = 0;
                value++;
                if(strcmp(para, "-name") == 0)
                {
                    strcpy(stitchEnv.oriID, value);
                }
                else if(strcmp(para, "-hdrselect") == 0)
                {
                    stitchEnv.hdrSel = atoi(value);
                }
                else if(strcmp(para, "-evenmode") == 0)
                {
                    stitchEnv.evenMode = atoi(value);
                }
                else if(strcmp(para, "-scenemode") == 0)
                {
                    stitchEnv.sceneMode = atoi(value);
                }
                else if(strcmp(para, "-level") == 0)
                {
                    stitchEnv.gyroMode = atoi(value);
                }
                else if(strcmp(para, "-luminance") == 0)
                {
                    stitchEnv.luminance = atof(value);
                }
                else if(strcmp(para, "-contrast") == 0)
                {
                    stitchEnv.contrast = atof(value);
                }
                else if(strcmp(para, "-gamma") == 0)
                {
                    stitchEnv.gammaMode = atoi(value);
                }
                else if(strcmp(para, "-wb") == 0)
                {
                    stitchEnv.wbMode = atoi(value);
                }
                else if(strcmp(para, "-red") == 0)
                {
                    stitchEnv.wbConfR = atof(value);
                }
                else if(strcmp(para, "-green") == 0)
                {
                    stitchEnv.wbConfG = atof(value);
                }
                else if(strcmp(para, "-blue") == 0)
                {
                    stitchEnv.wbConfB = atof(value);
                }
                else if(strcmp(para, "-jpgquality") == 0)
                {
                    stitchEnv.jpgQuality = atoi(value);
                }
                else if(strcmp(para, "-outdir") == 0)
                {
                    strcpy(stitchEnv.outputDir, value);
                    if(stitchEnv.outputDir[strlen(stitchEnv.outputDir) - 1] != '/')
                    {
                        strcat(stitchEnv.outputDir, "/");
                    }
                }
                else if(strcmp(para, "-timer") == 0)
                {
                    capDelay = atoi(value);
                }
                else if(strcmp(para, "-mode") == 0)
                {
                    autoMode = atoi(value);
                }
                else if(strcmp(para, "-hdr") == 0)
                {
                    hdrMode = atoi(value);
                }
                else if(strcmp(para, "-antiflicker") == 0)
                {
                    strobeMode = atoi(value);
                }
                else if(strcmp(para, "-timelapse") == 0)
                {
                    timelapse = atoi(value);
                }
                else if(strcmp(para, "-scene") == 0)
                {
                    isoMode = atoi(value);
                }
                else if(strcmp(para, "-ev") == 0)
                {
                    capEv = atoi(value);
                    capEv += 128;
                }
                else if(strcmp(para, "-speed") == 0)
                {
                    exposure = atoi(value);
                }
                else if(strcmp(para, "-iso") == 0)
                {
                    iso = atoi(value);
                }
                else if(strcmp(para, "-longitude") == 0)
                {
                    longitude = atoi(value);
                }
                else if(strcmp(para, "-latitude") == 0)
                {
                    latitude = atoi(value);
                }
            }
        }
        requestPtr = space + 1;
        space = strstr(requestPtr, " ");
    }

    int responseSize = -1;
    int responseStatus = -1;
    char requestParam[2048];
    char fileName[1024];
    if(strcmp(command, "get_list") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s", command);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            responseStr = responseBuf;
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "get_parameters") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s?filename=%s", command, stitchEnv.oriID);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            RawImageInfo* rawImgInfo = (RawImageInfo*)responseBuf;
            responseStr = ExifFromRawImageInfo(rawImgInfo);
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "get_thumb") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s?filename=%s", command, stitchEnv.oriID);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            snprintf(fileName, sizeof(fileName), "%s%s_thumbnail.jpg", stitchEnv.outputDir, stitchEnv.oriID);
            FILE* jpgFile = fopen(fileName, "wb");
            if(jpgFile)
            {
                if((int)(fwrite(responseBuf, 1, responseSize, jpgFile)) == responseSize)
                {
                    responseStr = fileName;
                }
                else
                {
                    responseStr = "ERROR write thumbnail file";
                }
                fclose(jpgFile);
            }
            else
            {
                responseStr = "ERROR write thumbnail file";
            }
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "del_file") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s?filename=%s", command, stitchEnv.oriID);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            responseStr = "OK";
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "get_information") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s", command);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        responseStr = responseBuf;
        delete[] responseBuf;
    }
    else if(strcmp(command, "get_file") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s?filename=%s", command, stitchEnv.oriID);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, &stitchEnv);
        if(responseStatus == 200)
        {
            snprintf(fileName, sizeof(fileName), "%s%s.ori", stitchEnv.outputDir, stitchEnv.oriID);
            FILE* oriFile = fopen(fileName, "wb");
            if(oriFile)
            {
                if((int)(fwrite(responseBuf, 1, responseSize, oriFile)) == responseSize)
                {
                    snprintf(fileName, sizeof(fileName), "%s%s.jpg", stitchEnv.outputDir, stitchEnv.oriID);
                    responseStr = fileName;
                }
                else
                {
                    responseStr = "ERROR write ori file";
                }
                fclose(oriFile);
            }
            else
            {
                responseStr = "ERROR write ori file";
            }
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "do_capture") == 0)
    {
        int capMode = hdrMode * 2 + autoMode;
        snprintf(requestParam, sizeof(requestParam), "%s?capmode=%d&strobemode=%d&timelapse=%d&isomode=%d&evmode=%d&exposure=%d&iso=%d&delay=%d&longitude=%d&latitude=%d", command, capMode, strobeMode, timelapse, isoMode, capEv, exposure, iso, capDelay, longitude, latitude);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            responseStr = "OK";
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "exit_timelapse") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s", command);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            responseStr = "OK";
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else if(strcmp(command, "shutdown") == 0)
    {
        snprintf(requestParam, sizeof(requestParam), "%s", command);
        char* responseBuf = HttpGet(&responseSize, &responseStatus, requestParam, NULL);
        if(responseStatus == 200)
        {
            responseStr = "OK";
        }
        else
        {
            responseStr = string("ERROR ") + responseBuf;
        }
        delete[] responseBuf;
    }
    else
    {
        responseStr = string("ERROR ") + command;
    }

    return responseStr;
}


extern "C" JNIEXPORT jstring JNICALL
Java_cn_xphase_haodaming_panocreator_MainActivity_getResponseJNI(
        JNIEnv* env,
        jobject, /* this */
        jbyteArray requestStrBytes) {

    char requestStr[2048];
    memset(requestStr, 0, sizeof(requestStr));
    int requestStrLen = env->GetArrayLength(requestStrBytes);
    env->GetByteArrayRegion(requestStrBytes, 0, (unsigned int)((requestStrLen < 2046) ? requestStrLen : 2046), (jbyte*)requestStr);
    strcat(requestStr, " ");
    string responseStr = getResponseCore(requestStr);
    return env->NewStringUTF(responseStr.c_str());
}

extern "C" JNIEXPORT jint JNICALL
Java_cn_xphase_haodaming_panocreator_MainActivity_getProgressJNI(
        JNIEnv* env,
        jobject) {
    return g_progress;
}
