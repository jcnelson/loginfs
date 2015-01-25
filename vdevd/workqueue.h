/*
   vdev: a virtual device manager for *nix
   Copyright (C) 2014  Jude Nelson

   This program is dual-licensed: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or later as
   published by the Free Software Foundation. For the terms of this
   license, see LICENSE.LGPLv3+ or <http://www.gnu.org/licenses/>.

   You are free to use this program under the terms of the GNU Lesser General
   Public License, but WITHOUT ANY WARRANTY; without even the implied
   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Lesser General Public License for more details.

   Alternatively, you are free to use this program under the terms of the
   Internet Software Consortium License, but WITHOUT ANY WARRANTY; without
   even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   For the terms of this license, see LICENSE.ISC or
   <http://www.isc.org/downloads/software-support-policy/isc-license/>.
*/

#ifndef _VDEV_WORKQUEUE_H_
#define _VDEV_WORKQUEUE_H_

#include "libvdev/util.h"

struct vdev_wreq;

// vdev workqueue callback type
typedef int (*vdev_wq_func_t)( struct vdev_wreq* wreq, void* cls );

// vdev workqueue request
struct vdev_wreq {

   // callback to do work
   vdev_wq_func_t work;

   // user-supplied arguments
   void* work_data;

   // next item 
   struct vdev_wreq* next;
};

// vdev workqueue
struct vdev_wq {

   // worker thread
   pthread_t thread;

   // is the thread running?
   bool running;

   // things to do (double-bufferred)
   struct vdev_wreq* work;
   struct vdev_wreq* tail;

   struct vdev_wreq* work_1;
   struct vdev_wreq* work_2;

   // lock governing access to work
   pthread_mutex_t work_lock;

   // semaphore to signal the availability of work
   sem_t work_sem;
};

C_LINKAGE_BEGIN

int vdev_wq_init( struct vdev_wq* wq );
int vdev_wq_start( struct vdev_wq* wq );
int vdev_wq_stop( struct vdev_wq* wq );
int vdev_wq_free( struct vdev_wq* wq );

int vdev_wreq_init( struct vdev_wreq* wreq, vdev_wq_func_t work, void* work_data );
int vdev_wreq_free( struct vdev_wreq* wreq );

int vdev_wq_add( struct vdev_wq* wq, struct vdev_wreq* wreq );

C_LINKAGE_END

#endif