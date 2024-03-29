drop table final_cohort;
create table final_cohort as
with OPfollowup as (
	select fpm."Patient_NRIC", "Admission_Visit_Date" as OPdate
	from full_patient_management fpm
	join full_diagnosis fd
	on fpm."Case_No" = fd."Case_No"
	where fpm."Patient_Category" = 'Outpatient Visit'
	and fpm."admission_visit_date" = fd."Admission_Visit_Date"
),
clean_lab as (
	SELECT
		full_lab.*, full_patient_management."Patient_NRIC", "Result Test Date" as labdate, (REGEXP_MATCHES("Test Result", '[0-9]+\.?[0-9]*')) [ 1 ]::float AS labvalue
	FROM
		full_lab
	left join full_patient_management
	on full_lab."Case No" = full_patient_management."Case_No"
),
ULT as (
	select "Patient_NRIC", "Date"
	from full_billing
	where "Service_Description" ilike '%probenecid%'
	or "Service_Description" ilike '%febuxostat%'
	or "Service_Description" ilike '%allopurinol%' 
),
Colchicine as (
	select "Patient_NRIC", "Date"
	from full_billing
	where "Service_Description" ilike '%colchicine%'
),
Reliever as (
select full_billing."Patient_NRIC", "Date"
from full_billing
join full_patient_management
on full_billing."Case_No" = full_patient_management."Case_No"
where
full_patient_management."Patient_Category" in ('Outpatient Visit', 'A&E')
and ( 
"Service_Description" ilike '%naproxen%'
or "Service_Description" ilike '%diclofenac%'
or "Service_Description" ilike '%ibuprofen%'
or "Service_Description" ilike '%arcoxia%'
or "Service_Description" ilike '%celecoxib%'
or "Service_Description" ilike '%synflex%'
or "Service_Description" ilike '%voltaren%'
or "Service_Description" ilike '%brufen%'
or "Service_Description" ilike '%etoricoxib%'
or "Service_Description" ilike '%celebrex%'
or "Service_Description" ilike '%colchicine%'
)),
-- BloodTest as (
-- 	select "Case_No", count(*) as blood_test_done
-- 	from full_billing
-- 	where "Service_Description" in ('"CULTURE AND SENSITIVITY, BLOOD, AEROBIC& ANAEROBI"',
-- 'BLOOD CULTURE', '"CULTURE AND SENSITIVITY, BLOOD, AEROBIC"', 'BLOOD CULTURE- IDC')
-- 	group by "Case_No"
-- -- 	'FULL BLOOD COUNT'
-- ),
-- CRPTest as (
-- 	select "Case_No", count(*) as crp_test_done
-- 	from full_billing
-- 	where "Service_Description" = 'C-REACTIVE PROTEIN (CRP)'
-- 	group by "Case_No"
-- ),
-- antibiotics as (
-- 	SELECT "Case_No", count(*) as antibiotics_done
-- 	FROM full_billing
-- 	WHERE lower("Service_Description") ~ '(augmentin|ceftriaxone|azithromycin|levofloxacin|ceftazidime|piperacillin|tazobactam|cefepime|metronidazole|clindamycin|cefazolin|cloxacillin|vancomycin|cefuroxime|co-trimoxazole|meropenem|benzylpenicillin|cephalexin|amikacin|gentamicin|imipenem|ampicillin|amoxycillin|ciprofloxacin|clarithromycin|co-amoxiclav|rocephine|flagyl|bactrim|fortum|piptazo|imipenam|cilastatin|tazocin)'
-- 	group by "Case_No"
-- ),
IPGoutVisits as (
	select fpm."Patient_NRIC", "admission_visit_date" as pIPVdate
	from full_patient_management fpm
	join full_diagnosis fd
	on fpm."Case_No" = fd."Case_No"
	where "Patient_Category" = 'Inpatient'
	and (fd."Diagnosis_Type" = 'P' or fd."Diagnosis_Type" = 'PD')
)
-- White blood cell count 3.84-10.01 
-- Glucose 
-- - Fasting glu: 3.0-6.0
-- - Random 4.0-7.8 
-- Creatinine 60-107
, WBC as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as WBC_7day
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('WBC','TWBC', '1WBC', 'BWBC')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between 0 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, WBC_ip as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as WBC_ip
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('WBC','TWBC', '1WBC', 'BWBC')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between -1 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, CRE as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as CRE_7day
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('CRE', '1CRE')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between 0 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, CRE_ip as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as CRE_ip
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('CRE', '1CRE')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between -1 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, GLU as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as GLU_7day
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('GLU', 'GLPCT', 'GLPC', 'GLUF', 'GLUPC', 'ZGLPY', '2GLUF', 'ZGLPZ')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between 0 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, GLU_ip as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as GLU_ip
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('GLU', 'GLPCT', 'GLPC', 'GLUF', 'GLUPC', 'ZGLPY', '2GLUF', 'ZGLPZ')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between -1 and 7
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, URA as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as URA_1year
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('URA', '1URA')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between 0 and 365
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, URA_ip as (
select distinct on (cohort_with_comor.aecaseno) cohort_with_comor.aecaseno, lab.labvalue as URA_ip
from cohort_with_comor
left join (select * from clean_lab where "Test Code" in ('URA', '1URA')) lab
on cohort_with_comor."ae_nric" = lab."Patient_NRIC"
and extract(day from cohort_with_comor."aeadmdate" - lab."labdate") between -1 and 365
where lab.labdate is not null
order by cohort_with_comor.aecaseno, lab.labdate desc
)
, OP as (
select
cohort_with_comor."aecaseno", sum(case when OPdate is not null then 1 else 0 end) as OP_follow_up
from cohort_with_comor
left join OPfollowup
on cohort_with_comor."ae_nric" = OPfollowup."Patient_NRIC" 
and cohort_with_comor."aeadmdate" - OPfollowup."opdate" between 1 and 365
group by cohort_with_comor."aecaseno"
)
, on_ULT as (
	select cohort_with_comor.aecaseno, count(ULT."Date") as onULT
	from cohort_with_comor
	left join ULT
	on cohort_with_comor."ae_nric" = ULT."Patient_NRIC"
	and cohort_with_comor."aeadmdate" - ULT."Date" between 1 and 365
	group by 1
)
, on_colchicine as (
	select cohort_with_comor.aecaseno, count(Colchicine."Date") as onColchicine
	from cohort_with_comor
	left join Colchicine
	on cohort_with_comor."ae_nric" = Colchicine."Patient_NRIC"
	and cohort_with_comor."aeadmdate" - Colchicine."Date" between 1 and 365
	group by 1
)
, on_Reliever as (
	select cohort_with_comor.aecaseno, count(Reliever."Date") as onReliever
	from cohort_with_comor
	left join Reliever
	on cohort_with_comor."ae_nric" = Reliever."Patient_NRIC"
	and cohort_with_comor."aeadmdate" - Reliever."Date" between 1 and 365
	group by 1
)
, pIPVs as (
	select cohort_with_comor.aecaseno
	, count(pIPVdate) filter (where cohort_with_comor."aeadmdate" - pIPVdate between 1 and 365) as IPV_last_year
-- 	, count(pIPVdate) filter (where cohort_URA_OP_ULT."aeadmdate" - pIPVdate between 1 and 30) as IPV_last_month
-- 	, count(pIPVdate) filter (where cohort_URA_OP_ULT."aeadmdate" - pIPVdate between 1 and 7) as IPV_last_week
	from cohort_with_comor
	left join IPGoutVisits
	on cohort_with_comor."ae_nric" = IPGoutVisits."Patient_NRIC"
	group by cohort_with_comor.aecaseno
)
, pAEVs as (
	select cohort_with_comor.aecaseno
	, count(admission_visit_date) filter (where cohort_with_comor."aeadmdate" - admission_visit_date between 1 and 365) as AEV_last_year
	, count(admission_visit_date) filter (where cohort_with_comor."aeadmdate" - admission_visit_date between 1 and 30) as AEV_last_month
	, count(admission_visit_date) filter (where cohort_with_comor."aeadmdate" - admission_visit_date between 1 and 7) as AEV_last_week
	from cohort_with_comor
	left join full_patient_management
	on cohort_with_comor."ae_nric" = full_patient_management."Patient_NRIC"
	where "Patient_Category" = 'A&E'
	group by cohort_with_comor.aecaseno
)
, joints as (
select full_patient_management."Case_No", "Date", "Service_Description" as locat from
full_billing
join full_patient_management
on full_billing."Case_No" = full_patient_management."Case_No"
where full_patient_management."Patient_Category" in ('A&E')
and "Service_Description" ~* '(joint|foot|hand|shoulder|elbow|ankle|knee|wrist)'
and "Service_Description" not ilike '%hip%'
and (("Service_Group" not in ('Prescriptions')) or ("Service_Group" is null))
),
num_joints as (
select cohort_with_comor."aecaseno"
, sum(case when locat like '%BOTH%' then 2 else 1 end) as number_of_joints
, max(case when locat ~ '(ANKLE|KNEE|FOOT)' then 1 else 0 end) as lower_limb_joint
, max(case when locat ~ '(WRIST|HAND|SHOULDER|ELBOW)' then 1 else 0 end) as upper_limb_joint
from joints
join cohort_with_comor
on cohort_with_comor."aecaseno" = joints."Case_No"
group by 1
)
select cohort_with_comor.*
, WBC_7day, CRE_7day, GLU_7day, URA_1year
, WBC_ip, CRE_ip, GLU_ip, URA_ip
, OP_follow_up
, onULT, onReliever, onColchicine
, pIPVs.IPV_last_year
, pAEVs.AEV_last_year, pAEVs.AEV_last_month, pAEVs.AEV_last_week
, num_joints.number_of_joints, num_joints.lower_limb_joint, num_joints.upper_limb_joint
-- , case when BloodTest.blood_test_done is not null then 1 else 0 end as blood_test_done
-- , case when CRPTest.crp_test_done is not null then 1 else 0 end as crp_test_done
-- , case when antibiotics.antibiotics_done is not null then 1 else 0 end as antibiotics_done
from cohort_with_comor
left join WBC on cohort_with_comor."aecaseno" = WBC."aecaseno"
left join CRE on cohort_with_comor."aecaseno" = CRE."aecaseno"
left join GLU on cohort_with_comor."aecaseno" = GLU."aecaseno"
left join URA on cohort_with_comor."aecaseno" = URA."aecaseno"
left join WBC_ip on cohort_with_comor."aecaseno" = WBC_ip."aecaseno"
left join CRE_ip on cohort_with_comor."aecaseno" = CRE_ip."aecaseno"
left join GLU_ip on cohort_with_comor."aecaseno" = GLU_ip."aecaseno"
left join URA_ip on cohort_with_comor."aecaseno" = URA_ip."aecaseno"
left join OP on cohort_with_comor."aecaseno" = OP."aecaseno"
left join on_ULT on cohort_with_comor."aecaseno" = on_ULT."aecaseno"
left join on_Colchicine on cohort_with_comor."aecaseno" = on_Colchicine."aecaseno"
left join on_Reliever on cohort_with_comor."aecaseno" = on_Reliever."aecaseno"
left join pIPVs on cohort_with_comor."aecaseno" = pIPVs."aecaseno"
left join pAEVs on cohort_with_comor."aecaseno" = pAEVs."aecaseno"
left join num_joints on cohort_with_comor."aecaseno" = num_joints."aecaseno"

-- left join BloodTest on cohort_URA_OP_ULT."aecaseno" = BloodTest."Case_No"
-- left join CRPTest on cohort_URA_OP_ULT."aecaseno" = CRPTest."Case_No"
-- left join antibiotics on cohort_URA_OP_ULT."aecaseno" = antibiotics."Case_No"




