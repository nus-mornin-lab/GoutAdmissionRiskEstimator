create table cohort AS
WITH simplified_dg as (
-- 	how many gout P_diag and S_diag does the case have
	select "Case_No",
	sum(case when "Diagnosis_Type" = 'P' or "Diagnosis_Type" = 'PD' then 1 else 0 end) as Pdg,
	sum(case when "Diagnosis_Type" = 'S' or "Diagnosis_Type" = 'SD' or "Diagnosis_Type" is null then 1 else 0 end) as Sdg from full_diagnosis
	group by "Case_No"
	 ),
ae AS
  (SELECT bb."Patient_NRIC" AS ae_nric,
          ceil(("admission_visit_date" - "Patient_DOB")/365) AS ae_age,
          bb."Patient_DOB" AS ae_dob,
          case when bb."Race" in ('Sikh', 'Caucasian', 'Eurasian') then 'Others' else bb."Race" end AS ae_race,
          bb."Gender" AS ae_gender,
          bb."Postal_Code" AS ae_post,
          bb."Patient_Category" as ae_patient_cat,
          bb."Case_No" AS aecaseno,
          bb."admission_visit_date" AS aeadmdate,
          bb."discharge_visit_date" AS aedisdate,
   		  aa."pdg" + aa."sdg" as ae_dg,
   	      rank() over (partition by "Patient_NRIC" order by "admission_visit_date" asc) as ae_time
   FROM full_patient_management AS bb
   left JOIN simplified_dg as aa ON (aa."Case_No" = bb."Case_No")
   WHERE bb."Patient_Category" = 'A&E'
     AND bb."admission_visit_date" BETWEEN '2015-01-01' AND '2017-09-30'),
ip AS
  (SELECT bb."Patient_NRIC" AS ip_nric,
          ceil(("admission_visit_date" - "Patient_DOB")/365) AS ip_age,
          bb."Patient_DOB" AS ip_dob,
          case when bb."Race" in ('Sikh', 'Caucasian', 'Eurasian') then 'Others' else bb."Race" end AS ip_race,
          bb."Gender" AS ip_gender,
          bb."Postal_Code" AS ip_post,
          bb."Patient_Category" as ip_patient_cat,
          bb."Case_No" AS ipcaseno,
          bb."admission_visit_date" AS ipadmdate,
          bb."discharge_visit_date" AS ipdisdate,
      	  aa."pdg" as ip_pdg,
   		  aa."sdg" as ip_sdg
   FROM full_patient_management AS bb
   left JOIN simplified_dg as aa ON (aa."Case_No" = bb."Case_No")
   WHERE bb."Patient_Category" = 'Inpatient'),
lab_time as (
	   select "Case No", min("Result Test Date") as firstLabTime, max("Result Test Date") as lastLabTime
	   from full_lab
	   group by "Case No"
   ),
billing_counts as (
	select "Case_No", count(*) as no_of_lab_billing from full_billing
	where "Service_Group" = 'Lab Investigation'
	group by "Case_No"
),
combined as (
   select ae.*, ipcaseno, ipadmdate, ipdisdate, ip_pdg, ip_sdg,
	   ipdisdate - ipadmdate as ip_alos,
	   ae_lab.firstLabTime as ae_first_lab,
	   ae_lab.lastLabTime as ae_last_lab,
	   ip_lab.firstLabTime as ip_first_lab,
	   ip_lab.lastLabTime as ip_last_lab,
	   ae_billing.no_of_lab_billing as ae_lab_billing,
	   ip_billing.no_of_lab_billing as ip_lab_billing,
-- 	   rank() over (partition by ae_nric order by aeadmdate asc) as aeascrank,
	   rank() over (partition by ipcaseno order by aeadmdate desc) as aedescrank
   from ae
   left join ip on ae_nric = ip_nric
   left join lab_time ae_lab on aecaseno = ae_lab."Case No"
   left join lab_time ip_lab on ipcaseno = ip_lab."Case No"
   left join billing_counts ae_billing on aecaseno = ae_billing."Case_No"
   left join billing_counts ip_billing on ipcaseno = ip_billing."Case_No"
   where 
   (ipadmdate - aedisdate between 0 and 3 or ipcaseno is null) and
   coalesce(ae_dg, ip_pdg, ip_sdg) is not null and
   ((ip_pdg > 0) or (ip_pdg is null))
),
repeated_ip_cases as (
   select ipcaseno from combined where ipcaseno is not null group by ipcaseno having count(*) > 1
)
   select *,
   case when ipcaseno is null then 0 else 1 end as case_group,
   case when (ae_dg is null and ip_pdg > 0) then 1 else 0 end as mis_diagnosis
   from combined
--  exclude patients that had multiple AE admissions within 2 days and went to Inpatient afterwards
   where 
--    (
-- 	   ipcaseno not in (select * from repeated_ip_cases) or
-- 	   ipcaseno is null) and
-- --   aeascrank = 1 and
   ipcaseno is null or
   aedescrank = 1
   order by aeadmdate
   