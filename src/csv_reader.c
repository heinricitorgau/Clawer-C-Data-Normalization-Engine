#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "csv_reader.h"

#define MAX_LINE_LEN 1024
#define MAX_FIELDS 5  // Changed from 11

/* Expected CSV format:
   University,Country,Rank Min,Rank Max,Overall Score
*/

int parse_csv_line(char *line, char **fields, int max_fields) {
    int count = 0;
    char *token = strtok(line, ",");
    while (token != NULL && count < max_fields) {
        fields[count++] = token;
        token = strtok(NULL, ",");
    }
    return count;
}

int load_csv_data(const char *filename, UniversityRecord records[], int max_records) {
    FILE *fp;
    char line[MAX_LINE_LEN];
    char *fields[MAX_FIELDS];
    int record_count = 0;

    if (filename == NULL || records == NULL || max_records <= 0) {
        fprintf(stderr, "Invalid arguments passed to load_csv_data().\n");
        return 0;
    }

    fp = fopen(filename, "r");
    if (fp == NULL) {
        perror("Failed to open CSV file");
        return 0;
    }

    /* Skip header line */
    if (fgets(line, sizeof(line), fp) == NULL) {
        fclose(fp);
        return 0;
    }

    while (fgets(line, sizeof(line), fp) != NULL && record_count < max_records) {
        int field_count;

        field_count = parse_csv_line(line, fields, MAX_FIELDS);
        if (field_count != MAX_FIELDS) {
            fprintf(stderr, "Warning: skipped malformed line: %s", line);
            continue;
        }

        /* CSV column mapping
           0 -> University
           1 -> Country
           2 -> Rank Min
           3 -> Rank Max
           4 -> Overall Score */

        strncpy(records[record_count].raw_name, fields[0], NAME_LEN - 1);
        records[record_count].raw_name[NAME_LEN - 1] = '\0';

        strncpy(records[record_count].raw_country, fields[1], COUNTRY_LEN - 1);
        records[record_count].raw_country[COUNTRY_LEN - 1] = '\0';

        {
            char rank_buffer[64];
            snprintf(rank_buffer, sizeof(rank_buffer), "%s-%s", fields[2], fields[3]);
            strncpy(records[record_count].raw_rank, rank_buffer, RANK_STR_LEN - 1);
            records[record_count].raw_rank[RANK_STR_LEN - 1] = '\0';
        }

        strncpy(records[record_count].raw_score, fields[4], SCORE_STR_LEN - 1);
        records[record_count].raw_score[SCORE_STR_LEN - 1] = '\0';

        record_count++;
    }

    fclose(fp);
    return record_count;
}
