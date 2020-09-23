create table cohort_with_comor as
-- ----------Heart Failure----------
WITH hf AS (
    SELECT
        "Patient_NRIC", min(to_Date("Date", 'DD/MM/YYYY')) as minDate
    FROM
        full_all_diagnosis ad
    WHERE
        ad."Diagnosis_Code" IN ('I110', 'I500', 'I509', '428', '4280', '40291', '4281', '4289', '40201', '40211', 'I130', 'I132')
    group BY
        "Patient_NRIC"
),
-- ----------Heart Failure----------

-- -- ----------Kidney----------
kd_diag AS (
    SELECT
        "Patient_NRIC", min(to_Date("Date", 'DD/MM/YYYY')) as minDate
    FROM
        full_all_diagnosis ad
    WHERE
        ad. "Diagnosis_Code" IN ('N181', 'N182', 'N183', 'N184', 'N185', 'N189', '585', '5850', '586', '5860', '5889', 'E8791', 'I120','I131', 'I132', 'T861', 'V420', 'Y841', 'Z940')
    group BY
        "Patient_NRIC"
),
kd_bill AS (
    SELECT
        "Patient_NRIC", min("Date") as minDate
    FROM
        full_billing
    WHERE
        "Service_Description"
        iLIKE '%dialysis%'
	   group BY
		   "Patient_NRIC"
),
cleanlab AS (
	SELECT
		full_lab.*, full_patient_management."Patient_NRIC", (REGEXP_MATCHES("Test Result", '[0-9]+\.?[0-9]*')) [ 1 ]::float AS labvalue
	FROM
		full_lab
	left join full_patient_management
	on full_lab."Case No" = full_patient_management."Case_No"
),
-- lab value higher than 130
cre_process as(
	select
	    "Patient_NRIC", min("Result Test Date") as firstdose from cleanlab
	where "Test Code" in ('CRE', '1CRE')
	and labvalue > 130
	group by "Patient_NRIC"
	order by "Patient_NRIC" asc
	
),
kd_lab AS (
	SELECT
		cleanlab."Patient_NRIC", min("Result Test Date") as cutoff
	FROM
		cleanlab
	join cre_process
	on cleanlab."Patient_NRIC" = cre_process."Patient_NRIC"
	where "Test Code" in ('CRE', '1CRE')
	and labvalue > 130
	and "Result Test Date" - firstdose > interval '3 months' 
	group by cleanlab."Patient_NRIC"
 ORDER BY
	    cleanlab."Patient_NRIC" desc
),
-- ----------Kidney----------

----------Diabetes----------

db_diag AS (
	SELECT "Patient_NRIC", min(to_Date("Date", 'DD/MM/YYYY')) as minDate
   FROM full_all_diagnosis ad
   WHERE lower(ad."Diagnosis_Description") LIKE '%diabetes mellitus%'
   group by "Patient_NRIC"
),
db_drug AS (
	SELECT "Patient_NRIC", min("Date") as minDate
    FROM full_billing
    WHERE lower("Service_Description") ~ '(aspart|novomix|lantus|glargine|jardiance|janumet|januvia|glyburide|diamicron|trajenta|amaryl|insulin|glipizide|glibenclamide|gliclazide|glimepiride|metformin|sitagliptin|linagliptin|empagliflozin|acarbose|rosiglitazone|pioglitazone|tolbutamide)'
	and lower("Service_Description") not in ('aspartate transaminase (ast)', 'aspartate transaminase (ast, got)')
	group by "Patient_NRIC"
),
ghb_process as (
	SELECT *, row_number() OVER (PARTITION BY "Patient_NRIC"
                          ORDER BY "Result Test Date" ASC) AS rank1
   FROM cleanlab
   WHERE "Test Code" in ('GHB', 'GHBPT', 'GHBR')
     AND labvalue > 6.5
     AND "Patient_NRIC" IN
       (SELECT "Patient_NRIC"
        FROM cleanlab
        WHERE "Test Code" in ('GHB', 'GHBPT', 'GHBR')
          AND labvalue > 6.5
        GROUP BY "Patient_NRIC"
        HAVING count(*) > 1)
   ORDER BY "Patient_NRIC" ASC, rank1 ASC
  ),
db_ghb AS
  (SELECT *
   FROM ghb_process
   WHERE rank1 = 2),
glu_process as(
	SELECT *, row_number() OVER (PARTITION BY "Patient_NRIC"
                          ORDER BY "Result Test Date" ASC) AS rank2
   FROM cleanlab
   WHERE (("Test Code" IN ('GLU', 'GLPCT')
     AND labvalue > 11) or ("Test Code" = 'GLUF' and labvalue > 7))
     AND "Patient_NRIC" IN
       (SELECT "Patient_NRIC"
        FROM cleanlab
        WHERE (("Test Code" IN ('GLU', 'GLPCT')
     AND labvalue > 11) or ("Test Code" = 'GLUF' and labvalue > 7))
        GROUP BY "Patient_NRIC"
        HAVING count(*) > 1)
   ORDER BY "Patient_NRIC" ASC, rank2 ASC
),
db_glu AS
  (SELECT *
   FROM glu_process
   WHERE rank2 = 2)
-- ----------Diabetes----------
--------
SELECT pc.*,
       CASE
           WHEN hf.minDate <= "aedisdate" THEN 1
           ELSE 0
       END AS heartfailure,
       CASE
           WHEN kd_diag.minDate <= "aedisdate" THEN 1
           ELSE 0
       END AS kd_diag,
       CASE
           WHEN kd_bill.minDate <= "aedisdate" THEN 1
           ELSE 0
       END AS kd_bill,
       CASE
           WHEN "cutoff" <= "aedisdate" THEN 1
           ELSE 0
       END AS kd_lab,
       CASE
           WHEN db_diag.minDate <= "aedisdate" THEN 1
           ELSE 0
       END AS db_diag,
       CASE
           WHEN db_drug.minDate <= "aedisdate" THEN 1
           ELSE 0
       END AS db_drug,
       CASE
           WHEN db_ghb."Result Test Date" <= "aedisdate" THEN 1
           ELSE 0
       END AS db_ghb,
       CASE
           WHEN db_glu."Result Test Date" <= "aedisdate" THEN 1
           ELSE 0
       END AS db_glu
FROM cohort pc
LEFT JOIN hf ON hf."Patient_NRIC" = pc. "ae_nric"
LEFT JOIN kd_diag ON kd_diag. "Patient_NRIC" = pc. "ae_nric"
LEFT JOIN kd_bill ON kd_bill. "Patient_NRIC" = pc. "ae_nric"
LEFT JOIN kd_lab ON kd_lab."Patient_NRIC" = pc. "ae_nric"
LEFT JOIN db_diag ON db_diag."Patient_NRIC" = pc."ae_nric"
LEFT JOIN db_drug ON db_drug."Patient_NRIC" = pc."ae_nric"
LEFT JOIN db_ghb ON db_ghb."Patient_NRIC" = pc."ae_nric"
LEFT JOIN db_glu ON db_glu."Patient_NRIC" = pc."ae_nric"