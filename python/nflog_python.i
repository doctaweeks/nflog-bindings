
// Grab a Python function object as a Python object.
%typemap(in) PyObject *pyfunc {
  if (!PyCallable_Check($input)) {
      PyErr_SetString(PyExc_TypeError, "Need a callable object!");
      return NULL;
  }
  $1 = $input;
}

%{
#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include <nflog_utils.h>

int  swig_nflog_callback(struct nflog_g_handle *gh, struct nfgenmsg *nfmsg,
                       struct nflog_data *nfad, void *data)
{
        int id = 0;
        struct nfulnl_msg_packet_hdr *ph;
        char *payload_data;
        int payload_len;

        if (data == NULL) {
                fprintf(stderr,"No callback set !\n");
                return -1;
        }

        ph = nflog_get_msg_packet_hdr(nfad);
        /*
        if (ph){
                id = ntohl(ph->packet_id);
        }
        */

        payload_len = nflog_get_payload(nfad, &payload_data);

        /*printf("callback called\n");
        printf("callback argument: %p\n",data);*/

        {
                PyObject *func, *arglist, *payload_obj;
                PyObject *result;
                struct log_payload *p;

                SWIG_PYTHON_THREAD_BEGIN_ALLOW;
                func = (PyObject *) data;
                p = malloc(sizeof(struct log_payload));
                if (!p) {
                        fprintf(stderr, "callback malloc failure !\n");
                        PyErr_Print();
                }
                p->data = payload_data;
                p->len = payload_len;
                p->id = id;
                p->gh = gh;
                p->nfad = nfad;
                payload_obj = SWIG_NewPointerObj((void*) p, SWIGTYPE_p_log_payload, SWIG_POINTER_OWN );
                arglist = Py_BuildValue("(N)",payload_obj);
                result = PyEval_CallObject(func,arglist);
                Py_DECREF(arglist);
                if (result) {
                        Py_DECREF(result);
                }
                result = PyErr_Occurred();
                if (result) {
                        fprintf(stderr, "callback failure !\n");
                        PyErr_Print();
                }
                SWIG_PYTHON_THREAD_END_ALLOW;
        }

        return 0;
}

void raise_swig_error(const char *errstr)
{
        //fprintf(stderr,"ERROR %s\n",errstr);
        SWIG_Error(SWIG_RuntimeError, errstr); 
}
%}

%extend log {

int set_callback(PyObject *pyfunc)
{
        self->_cb = (void*)pyfunc;
        /*printf("callback argument: %p\n",pyfunc);*/
        Py_INCREF(pyfunc);
        return 0;
}

int loop()
{
	int rv;
	char buf[65535];

	Py_BEGIN_ALLOW_THREADS
	while ((rv = recv(self->fd, buf, sizeof(buf), 0)) && rv >= 0 && self->_h) {
		Py_BLOCK_THREADS
		nflog_handle_packet(self->_h, buf, rv);
		Py_UNBLOCK_THREADS
	}
	Py_END_ALLOW_THREADS

	return 0;
}

};

%typemap (out) const char* get_data {
        $result = PyString_FromStringAndSize($1,arg1->len);
}

%typemap (out) const char* get_hwhdr {
        uint16_t hwhdr_len;
        hwhdr_len = nflog_get_msg_packet_hwhdrlen(arg1->nfad);
        $result = PyString_FromStringAndSize($1,hwhdr_len);
}

%extend log_payload {
const char* get_data(void) {
        return self->data;
}

const char* get_hwhdr(void) {
        const char *hwhdr;
        hwhdr = nflog_get_msg_packet_hwhdr(self->nfad);
        return hwhdr;
}
};

