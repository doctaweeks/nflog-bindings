# nflog-bindings

[![Build Status](https://travis-ci.org/chifflier/nflog-bindings.svg?branch=master)](https://travis-ci.org/chifflier/nflog-bindings)

## Overview

nflog-bindings was written to provide an interface in high-level
languages such as Perl or Python to libnetfilter_log.
The goal is to provide a library to gain access to packets queued by
the kernel packet filter.

It is important to note that these bindings will not follow blindly
libnetfilter_log API. For ex., some higher-level wrappers will be provided
for the open/bind/create mechanism (using one function call instead of
three).

Since libraries to decode ip packets are already available, the bindings
will use them.

Remember that an application connection to libnetfilter_log must run as
root to be able to create the queue. Some extra steps may be required
to drop privileges after if you need more security.

## iptables

You must add rules in netfilter to send packets to the userspace queue.
The number of the queue (--nflog-group option in netfilter) must match the
number provided to create_queue().

Example of iptables rules::

    iptables -A OUTPUT --destination 1.2.3.4 -j NFLOG --nflog-group 1

Of course, you should be more restrictive, depending on your needs.

