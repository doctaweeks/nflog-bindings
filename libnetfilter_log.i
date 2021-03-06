%module nflog

%{
#include <nflog.h>

#include <nflog_common.h>

#include <exception.h>
%}

%include timeval.i
%include exception.i

%apply unsigned int { uint32_t }
%apply unsigned long long { uint64_t }


enum CfgFlags {
        CfgSeq,
        CfgSeqGlobal,
};

enum CopyMode {
        CopyNone,
        CopyMeta,
        CopyPacket,
};


%feature("autodoc","1");
%include docstrings.i

#if defined(SWIGPYTHON)
%include python/nflog_python.i
#elif defined(SWIGPERL)
%include perl/nflog_perl.i
#endif

%extend log {

%exception {
        char *err;
        clear_exception();
        $action
        if ((err = check_exception())) {
                SWIG_exception(SWIG_RuntimeError, err);
        }
}

        int open();
        void close();
        int bind(int family);
        int unbind(int family);
        int create_queue(int num);
        int fast_open(int num, int family);
        int set_bufsiz(int nlbufsiz);
        int set_qthresh(uint32_t qthresh);
        int set_timeout(uint32_t timeout);
        int set_flags(enum CfgFlags flags);
        int set_mode(enum CopyMode mode, uint32_t range);
        int prepare();
        int loop();
        int stop_loop();
};

%extend log_payload {
        uint32_t get_nfmark();
        struct timeval get_timestamp();
        int get_indev();
        int get_physindev();
        int get_outdev();
        int get_physoutdev();
        uint32_t get_uid();
        uint32_t get_gid();
        uint32_t get_seq();
        uint32_t get_seq_global();
        const char * get_prefix();
        uint16_t get_hwtype();

unsigned int get_length(void) {
        return self->len;
}

};



%include "nflog.h"

const char * nflog_bindings_version(void);

