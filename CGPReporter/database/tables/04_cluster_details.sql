CREATE TABLE cluster_details (
    cluster_code                VARCHAR(4)   PRIMARY KEY
  , stage                       VARCHAR(10)
  , geographic_size             NUMBER
  , total_population            INTEGER
  , num_locality                INTEGER
  , num_lsa                     INTEGER
  , num_institute_coordinator   INTEGER  
);