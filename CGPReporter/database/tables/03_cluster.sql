CREATE TABLE cluster (
    cluster_code       VARCHAR(4)   PRIMARY KEY
  , cluster_name       VARCHAR(50)
  , area_number        VARCHAR(20)
  , atc_secretary_id   INTEGER
  , ti_coordinator_id  INTEGER
  , primary_abm_id     INTEGER
  , secondary_abm_id   INTEGER
);