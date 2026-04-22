#pragma once
#ifndef WEIGHT_SCHEDULER_H
#define WEIGHT_SCHEDULER_H

#include "../../main/main.h"

void init_weight_sensors_timer();
void stop_schedule_timer();
void schedule_next_measure();

#endif // WEIGHT_SCHEDULER_H