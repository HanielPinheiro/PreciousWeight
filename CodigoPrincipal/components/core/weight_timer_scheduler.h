#pragma once
#ifndef SENSORS_TASK_H
#define SENSORS_TASK_H

#include "process_mqtt_data.h"
#include "mqtt3.h"
#include "bios.h"

void init_weight_sensors_timer();
void stop_schedule_timer();
void schedule_next_measure();

#endif // SENSORS_TASK_H