/*
 * Copyright 2010, Lloyd Hilaiel.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 * 
 *  3. Neither the name of Lloyd Hilaiel nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */ 

#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <assert.h>

/* memory debugging routines */
typedef struct 
{
    unsigned int numFrees;
    unsigned int numMallocs;    
    /* XXX: we really need a hash table here with per-allocation
     *      information */ 
} yajlTestMemoryContext;

/* cast void * into context */
#define TEST_CTX(vptr) ((yajlTestMemoryContext *) (vptr))

static void yajlTestFree(void * ctx, void * ptr)
{
    assert(ptr != NULL);
    TEST_CTX(ctx)->numFrees++;
    free(ptr);
}

static void * yajlTestMalloc(void * ctx, unsigned int sz)
{
    assert(sz != 0);
    TEST_CTX(ctx)->numMallocs++;
    return malloc(sz);
}

static void * yajlTestRealloc(void * ctx, void * ptr, unsigned int sz)
{
    if (ptr == NULL) {
        assert(sz != 0);
        TEST_CTX(ctx)->numMallocs++;        
    } else if (sz == 0) {
        TEST_CTX(ctx)->numFrees++;                
    }

    return realloc(ptr, sz);
}


/* begin parsing callback routines */
#define BUF_SIZE 2048

static int test_yajl_null(void *ctx)
{
    printf("null\n");
    return 1;
}

static int test_yajl_boolean(void * ctx, int boolVal)
{
    printf("bool: %s\n", boolVal ? "true" : "false");
    return 1;
}

static int test_yajl_integer(void *ctx, long integerVal)
{
    printf("integer: %ld\n", integerVal);
    return 1;
}

static int test_yajl_double(void *ctx, double doubleVal)
{
    printf("double: %g\n", doubleVal);
    return 1;
}

static int test_yajl_string(void *ctx, const unsigned char * stringVal,
                            unsigned int stringLen)
{
    printf("string: '");
    fwrite(stringVal, 1, stringLen, stdout);
    printf("'\n");    
    return 1;
}

static int test_yajl_map_key(void *ctx, const unsigned char * stringVal,
                             unsigned int stringLen)
{
    char * str = (char *) malloc(stringLen + 1);
    str[stringLen] = 0;
    memcpy(str, stringVal, stringLen);
    printf("key: '%s'\n", str);
    free(str);
    return 1;
}

static int test_yajl_start_map(void *ctx)
{
    printf("map open '{'\n");
    return 1;
}


static int test_yajl_end_map(void *ctx)
{
    printf("map close '}'\n");
    return 1;
}

static int test_yajl_start_array(void *ctx)
{
    printf("array open '['\n");
    return 1;
}

static int test_yajl_end_array(void *ctx)
{
    printf("array close ']'\n");
    return 1;
}

static yajl_callbacks callbacks = {
    test_yajl_null,
    test_yajl_boolean,
    test_yajl_integer,
    test_yajl_double,
    NULL,
    test_yajl_string,
    test_yajl_start_map,
    test_yajl_map_key,
    test_yajl_end_map,
    test_yajl_start_array,
    test_yajl_end_array
};

static void usage(const char * progname)
{
    fprintf(stderr,
            "usage:  %s [options] <filename>\n"
            "   -c  allow comments\n"
            "   -b  set the read buffer size\n",
            progname);
    exit(1);
}

int 
main(int argc, char ** argv)
{
    yajl_handle hand;
    const char * fileName;
    static unsigned char * fileData = NULL;
    unsigned int bufSize = BUF_SIZE;
    yajl_status stat;
    size_t rd;
    yajl_parser_config cfg = { 0, 1 };
    int i, j, done;

    /* memory allocation debugging: allocate a structure which collects
     * statistics */
    yajlTestMemoryContext memCtx = { 0,0 };

    /* memory allocation debugging: allocate a structure which holds
     * allocation routines */
    yajl_alloc_funcs allocFuncs = {
        yajlTestMalloc,
        yajlTestRealloc,
        yajlTestFree,
        (void *) NULL
    };

    allocFuncs.ctx = (void *) &memCtx;

    /* check arguments.  We expect exactly one! */
    for (i=1;i<argc;i++) {
        if (!strcmp("-c", argv[i])) {
            cfg.allowComments = 1;
        } else if (!strcmp("-b", argv[i])) {
            if (++i >= argc) usage(argv[0]);

            /* validate integer */
            for (j=0;j<(int)strlen(argv[i]);j++) {
                if (argv[i][j] <= '9' && argv[i][j] >= '0') continue;
                fprintf(stderr, "-b requires an integer argument.  '%s' "
                        "is invalid\n", argv[i]);
                usage(argv[0]);
            }

            bufSize = atoi(argv[i]);
            if (!bufSize) {
                fprintf(stderr, "%d is an invalid buffer size\n",
                        bufSize);
            }
        } else {
            fprintf(stderr, "invalid command line option: '%s'\n",
                    argv[i]);
            usage(argv[0]);
        }
    }

    fileData = (unsigned char *) malloc(bufSize);

    if (fileData == NULL) {
        fprintf(stderr,
                "failed to allocate read buffer of %u bytes, exiting.",
                bufSize);
        exit(2);
    }

    fileName = argv[argc-1];

    /* ok.  open file.  let's read and parse */
    hand = yajl_alloc(&callbacks, &cfg, &allocFuncs, NULL);

    done = 0;
	while (!done) {
        rd = fread((void *) fileData, 1, bufSize, stdin);
        
        if (rd == 0) {
            if (!feof(stdin)) {
                fprintf(stderr, "error reading from '%s'\n", fileName);
                break;
            }
            done = 1;
        }

        if (done)
            /* parse any remaining buffered data */
            stat = yajl_parse_complete(hand);
        else
            /* read file data, pass to parser */
            stat = yajl_parse(hand, fileData, rd);
        
        if (stat != yajl_status_insufficient_data &&
            stat != yajl_status_ok)
        {
            unsigned char * str = yajl_get_error(hand, 0, fileData, rd);
            fflush(stdout);
            fprintf(stderr, "%s", (char *) str);
            yajl_free_error(hand, str);
            break;
        }
    } 

    yajl_free(hand);
    free(fileData);

    /* finally, print out some memory statistics */

/* (lth) only print leaks here, as allocations and frees may vary depending
 *       on read buffer size, causing false failures.
 *
 *  printf("allocations:\t%u\n", memCtx.numMallocs);
 *  printf("frees:\t\t%u\n", memCtx.numFrees);
*/
    fflush(stderr);
    fflush(stdout);
    printf("memory leaks:\t%u\n", memCtx.numMallocs - memCtx.numFrees);    

    return 0;
}
