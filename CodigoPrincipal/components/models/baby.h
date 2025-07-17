#include "cstdint"

typedef struct
{
    char baby_id[32];
    char hospital_id[32];
    char name[64];
    time_t birth_date;
    time_t last_measurement;
    uint8_t measurement_times[4]; // Horários de pesagem (0-23)
} baby_info_t;

esp_err_t baby_load_current(baby_info_t *baby);
esp_err_t baby_save_measurement(const baby_info_t *baby, float weight_in_gr);