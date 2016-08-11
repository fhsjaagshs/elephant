//
//  MacroWrappers.c
//  Elephant
//
//  Created by Nathaniel Symer on 8/11/16.
//  Copyright © 2016 Nathaniel Symer. All rights reserved.
//

#include "MacroWrappers.h"

#include <sys/stat.h>
#include <sys/mman.h>

int isReg(mode_t m) { return S_ISREG(m); }
int isMapFailed(void *b) { return b == MAP_FAILED; }