create table ccis as
with asd as (
select *
, case 
when (("Diagnosis_Code" ~~* ANY('{14%,15%,16%,18%,170%,171%,172%,174%,175%,176%,179%,190%,191%,192%,193%,194%,1950%,1951%,1952%,1953%,1954%,1955%,1958%,200%,201%,202%,203%,204%,205%,206%,207%,208%,C0%,C1%,C2%,C3%,C40%,C41%,C43%,C45%,C46%,C47%,C48%,C49%,C5%,C6%,C70%,C71%,C72%,C73%,C74%,C75%,C76%,C80%,C81%,C82%,C83%,C84%,C85%,C883%,C887%,C889%,C900%,C901%,C91%,C92%,C93%,C940%,C941%,C942%,C943%,C9451%,C947%,C95%,C96%}'))
	 and ("Diagnosis_Code" <> '2016015'))
then 'cancer'
when "Diagnosis_Code" ~~* ANY('{428%,I50%}')
then 'CHF'
when "Diagnosis_Code" ~~* ANY('{410%,412%,I21%,I22%,I252%}')
then 'AMI'
when "Diagnosis_Code" ~~* ANY('{441%,4439%,7854%,V434%,I71%,I790%,I739%,R02%,Z958%,Z959%}')
then 'PVD'
when (("Diagnosis_Code" ~~* ANY('{430%,431%,432%,433%,434%,435%,436%,437%,438%,I60%,I61%,I62%,I63%,I65%,I66%,G450%,G451%,G452%,G458%,G459%,G46%,I64%,G454%,I670%,I671%,I672%,I674%,I675%,I676%,I677%,I678%,I679%,I681%,I682%,I688%,I69%}'))
	and ("Diagnosis_Code" <> '4301012'))
then 'CVA'
when "Diagnosis_Code" ~~* ANY('{290%,F00%,F01%,F02%,F051%}')
then 'dementia'
when "Diagnosis_Code" ~~* ANY('{490%,491%,492%,493%,494%,495%,496%,500%,501%,502%,503%,504%,505%,J40%,J41%,J42%,J44%,J43%,J45%,J46%,J47%,J67%,J44%,J60%,J61%,J62%,J63%,J66%,J64%,J65%}')
then 'pulmonary_disease'
when (("Diagnosis_Code" ~~* ANY('{7100%,7101%,7104%,7140%,7141%,7142%,71481%,5171%,725%,M32%,M34%,M332%,M053%,M058%,M059%,M060%,M063%,M069%,M050%,M052%,M051%,M353%}'))
	  and ("Diagnosis_Code" <> '7141017'))
then 'connective_tissue_disorder'
when "Diagnosis_Code" ~~* ANY('{531%,532%,533%,534%,K25%,K26%,K27%,K28%}')
then 'peptic_ulcer'
when "Diagnosis_Code" ~~* ANY('{5712%,5714%,5715%,5716%,K702%,K703%,K73%,K717%,K740%,K742%,K746%,K743%,K744%,K745%}')
then 'liver_disease'
when "Diagnosis_Code" ~~* ANY('{2500%, 2501%,2502%,2503%,2507%,E109%,E119%,E139%,E149%,E101%,E111%,E131%,E141%,E105%,E115%,E135%,E145%}')
then 'diabetes'
when "Diagnosis_Code" ~~* ANY('{2504%,2505%,2506%,E102%,E112%,E132%,E142 E103%,E113%,E133%,E143%,E104%,E114%,E134%,E144%}')
then 'diabetes_complications'
when "Diagnosis_Code" ~~* ANY('{342%,3441%,G81%,G041%,G820%,G821%,G822%}')
then 'paraplegia'
when "Diagnosis_Code" ~~* ANY('{582%,5830%,5831%,5832%,5833%,5835%,5836%,5837%,5834%,585%,586%,588%,N03%,N052%,N053%,N054%,N055%,N056%,N072%,N073%,N074%,N01%,N18%,N19%,N25%}')
then 'renal_disease'
when "Diagnosis_Code" ~~* ANY('{196%,197%,198%,1990%,1991%,C77%,C78%,C79%,C80%}')
then 'metastatic_cancer'
when "Diagnosis_Code" ~~* ANY('{5722%,5723%,5724%,5728%,K729%,K766%,K767%,K721%}')
then 'severe_liver_disease'
when "Diagnosis_Code" ~~* ANY('{042%,043%,044%,B20%,B21%,B22%,B23%,B24%}')
then 'HIV'
else null end as com
from full_all_diagnosis)
select * from asd
where com is not null
and length("Diagnosis_Code") <= 7
and "Patient_NRIC" in (select "Patient_NRIC" from final_cohort)