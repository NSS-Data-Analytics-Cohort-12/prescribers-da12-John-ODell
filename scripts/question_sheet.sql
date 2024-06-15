
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT
	COUNT(prescriber.npi) AS dr_npi,
	COUNT(prescription.total_claim_count)::money AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY dr_npi
ORDER BY total_claims DESC
LIMIT 1;
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT prescriber.nppes_provider_last_org_name AS last_name,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.specialty_description AS specialty,
	SUM(prescription.total_claim_count):: money AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY last_name,	first_name, specialty
ORDER BY total_claims DESC
-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
    prescriber.specialty_description AS specialty,
    SUM(prescription.total_claim_count):: money AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
WHERE prescription.total_claim_count IS NOT NULL
GROUP BY specialty
ORDER BY total_claims DESC
LIMIT 1;
--     b. Which specialty had the most total number of claims for opioids?
SELECT 
    prescriber.specialty_description AS specialty,
    SUM(prescription.total_claim_count)::money AS total_claims,
    COUNT(drug.opioid_drug_flag) AS opioid_class
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
LEFT JOIN drug
ON drug.drug_name = prescription.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY opioid_class DESC
LIMIT 10;
--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT COUNT(prescriber.specialty_description), 
	prescriber.specialty_description
FROM prescriber
JOIN prescription
USING (npi)
WHERE prescription.npi IS NULL
GROUP BY specialty_description
--HAVING COUNT(prescription.drug_name)= 0

--THIS IS CORRECT WITH THE EXCEPT, LEARN WHAT TO RETURN IN SELECT STATEMENT FOR EXCEPT AND INTERSECT
SELECT prescriber.specialty_description
FROM prescriber
LEFT JOIN prescription
USING(npi)
EXCEPT
SELECT prescriber.specialty_description
FROM prescription
LEFT JOIN prescriber
USING(npi)
--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT
    drug.generic_name AS gen_med_name,
    MAX(prescription.total_drug_cost) AS total_daily_cost
FROM drug
JOIN prescription 
USING (drug_name)
GROUP BY gen_med_name
ORDER BY total_daily_cost DESC
LIMIT 1;
--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT
    drug.generic_name AS gen_med_name,
    ROUND(SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply), 2) AS total_daily_cost
FROM drug
JOIN prescription 
USING (drug_name)
GROUP BY gen_med_name
ORDER BY total_daily_cost DESC
LIMIT 5;
-- EXCEPT, ANTI-JOIN******
-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT 
	drug_name AS med_name,
	CASE WHEN drug.opioid_drug_flag ='Y'THEN 'opioit'
	WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	WHEN drug.antibiotic_drug_flag = 'N'
	AND drug.opioid_drug_flag ='N' THEN 'Neither' END AS drug_type
FROM drug
ORDER BY drug_name
--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT
    CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'Neither'END AS drug_type,
    SUM(prescription.total_drug_cost)::money AS total_cost
FROM drug
JOIN prescription 
USING (drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;
-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(cbsa.cbsaname) AS tn_cbsa_count
FROM cbsa
JOIN fips_county
USING (fipscounty)
WHERE cbsa.nppes_provider_state = 'TN'
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--BOTH COLUMNS SEPERATED, LOOK AT A UNION 
SELECT
	cbsa.cbsaname AS all_name,
	SUM(population.population) AS max_pop
--	MIN(population.population)
FROM cbsa
JOIN population
USING (fipscounty)
GROUP BY all_name
ORDER BY max_pop DESC
LIMIT 1

SELECT
	cbsa.cbsaname AS all_name,
--	MAX(population.population) AS max_pop
	MIN(population.population) AS min_pop
FROM cbsa
JOIN population
USING (fipscounty)
GROUP BY all_name
ORDER BY min_pop ASC
LIMIT 1;

-- MAYBE BETTER ?
SELECT cbsa.cbsaname AS max_all_name,
       MAX(population.population) AS max_pop,
		cbsa.cbsaname AS min_all_name,
       MIN(population.population) AS min_pop
FROM cbsa
JOIN population USING (fipscounty)
GROUP BY max_all_name
INTERSECT
SELECT cbsa.cbsaname AS max_all_name,
 		MAX(population.population) AS max_pop,
		cbsa.cbsaname AS min_all_name,
		MIN(population.population) AS min_pop
FROM cbsa
JOIN population USING (fipscounty)
GROUP BY min_all_name
ORDER BY max_pop DESC , min_pop DESC
LIMIT 2;

--USE UNION HERE, GETTING CLOSER TO THE RIGHT ANSWER
SELECT cbsa.cbsaname AS max_all_name,
       SUM(population.population) AS max_pop,
		cbsa.cbsaname AS min_all_name,
       MIN(population.population) AS min_pop
FROM cbsa
JOIN population USING (fipscounty)
GROUP BY max_all_name
UNION
SELECT cbsa.cbsaname AS max_all_name,
 		SUM(population.population) AS max_pop,
		cbsa.cbsaname AS min_all_name,
		MIN(population.population) AS min_pop
FROM cbsa
JOIN population USING (fipscounty)
GROUP BY min_all_name
ORDER BY max_pop DESC , min_pop ASC
LIMIT 1;
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT
	fips_county.county AS county_name,
	MAX(population.population) AS max_pop
--	MIN(population.population)
FROM population
JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
WHERE fips_county.fipscounty NOT IN (SELECT fipscounty FROM cbsa)
GROUP BY county_name
ORDER BY max_pop DESC
LIMIT 1

-- BRANDON's Answer county or fipsCounty
select max(p.population) as max_pop,
	f.county
from population as p
join fips_county as f
on p.fipscounty = f.fipscounty
where f.county not in (select fipscounty from cbsa)
group by f.county
order by max_pop desc;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT prescription.drug_name AS med_name,
	prescription.total_claim_count As total_claims
FROM prescription
WHERE prescription.total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT prescription.drug_name AS med_name,
	prescription.total_claim_count AS total_claims,
	drug.opioid_drug_flag AS opioite
FROM prescription
JOIN drug
USING (drug_name)
WHERE prescription.total_claim_count >= 3000
	--AND drug.opioid_drug_flag = 'Y'
--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name AS med_name,
	prescription.total_claim_count AS total_claims,
	drug.opioid_drug_flag AS opioite,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.nppes_provider_last_org_name AS last_name
FROM prescription
JOIN drug
USING (drug_name)
JOIN prescriber
USING (npi)
WHERE prescription.total_claim_count >= 3000
	AND drug.opioid_drug_flag = 'Y'

	-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi AS npi_number,
	drug.drug_name AS med_name
FROM prescriber, drug 
WHERE UPPER(prescriber.specialty_description) LIKE 'PAIN MANAGEMENT'
    AND UPPER(prescriber.nppes_provider_city) LIKE 'NASHVILLE'
    AND drug.opioid_drug_flag = 'Y';
--FROM WITH TWO TABLES IS A SHORT CUT FOR CROSS JOIN, USE CROSS JOIN FOR LEGEBILITY SAKE

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


--CROSS JOIN! CROSS JOIN! CROSS JOIN!
SELECT prescriber.npi AS npi_number,
	drug.drug_name AS med_name
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON prescriber.npi = prescription.npi 
	AND drug.drug_name = prescription.drug_name
WHERE UPPER(prescriber.specialty_description) LIKE 'PAIN MANAGEMENT'
    AND UPPER(prescriber.nppes_provider_city) LIKE 'NASHVILLE'
    AND drug.opioid_drug_flag = 'Y';

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
--RE-WRITE WITH CROSS JOIN!! DON'T FULLY FOLLOW DATACAMP ADVICE
SELECT prescriber.npi AS npi_number,
		drug.drug_name AS med_name,
		COALESCE(prescription.total_claim_count, 0) AS total_claims_count
FROM prescriber
JOIN drug 
ON drug.opioid_drug_flag = 'Y'
LEFT JOIN (
    SELECT npi, drug_name, SUM(total_claim_count) AS total_claim_count
    FROM prescription
    GROUP BY npi, drug_name) prescription
ON prescriber.npi = prescription.npi 
	AND drug.drug_name = prescription.drug_name
WHERE UPPER(prescriber.specialty_description) LIKE 'PAIN MANAGEMENT'
    AND UPPER(prescriber.nppes_provider_city) LIKE 'NASHVILLE'
ORDER BY total_claims_count DESC;

--Nested functions/tables, Case statements, When to use group by and from placement statements are a place to revisit**
--
--READ ME BONUS

1. How many npi numbers appear in the prescriber table but not in the prescription table?


SELECT COUNT(prescriber.npi) AS presciber_npi
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi=prescription.npi
WHERE prescription.npi IS NULL 

2.
    a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT COUNT(drug.generic_name) AS med_count,
	drug.generic_name AS med_name
FROM drug
LEFT JOIN prescription
ON drug.drug_name=prescription.drug_name
LEFT JOIN prescriber
ON prescriber.npi = prescription.npi
WHERE UPPER(prescriber.specialty_description) = 'FAMILY PRACTICE'
GROUP BY med_name
ORDER BY COUNT(drug.generic_name) DESC
LIMIT 5;

2.
	 b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT COUNT(drug.generic_name) AS med_count,
	drug.generic_name AS med_name
FROM drug
LEFT JOIN prescription
ON drug.drug_name=prescription.drug_name
LEFT JOIN prescriber
ON prescriber.npi = prescription.npi
WHERE UPPER(prescriber.specialty_description) = 'CARDIOLOGY'
GROUP BY drug.generic_name
ORDER BY COUNT(drug.generic_name) DESC
LIMIT 5;

2.
	c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT
	CASE WHEN UPPER(prescriber.specialty_description) = 'CARDIOLOGY' THEN 'Cardiology'
	WHEN UPPER(prescriber.specialty_description) = 'FAMILY PRACTICE' THEN 'Family Practice'	
	ELSE 'Family_and_Cardio' END AS specialty,
    drug.generic_name AS med_name,
    COUNT(drug.generic_name) AS med_count
FROM drug
LEFT JOIN prescription 
ON drug.drug_name = prescription.drug_name
LEFT JOIN prescriber 
ON prescriber.npi = prescription.npi
--WHERE UPPER(prescriber.specialty_description) = 'CARDIOLOGY'
	--AND UPPER(prescriber.specialty_description) = 'FAMILY PRACTICE'
GROUP BY med_name,prescriber.specialty_description
ORDER BY COUNT(drug.generic_name) DESC
LIMIT 5;

3.. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT prescriber.npi AS npi_prescriber,
	prescriber.nppes_provider_city AS dr_city,
	COUNT(prescription.total_claim_count) AS claims_count
FROM prescriber
LEFT JOIN prescription
USING (npi)
WHERE UPPER(prescriber.nppes_provider_city)= 'NASHVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY COUNT(prescription.total_claim_count) DESC
LIMIT 5;

	 b. Now, report the same for Memphis.

SELECT prescriber.npi AS npi_prescriber,
	prescriber.nppes_provider_city AS dr_city,
	COUNT(prescription.total_claim_count) AS claims_count
FROM prescriber
LEFT JOIN prescription
USING (npi)
WHERE UPPER(prescriber.nppes_provider_city)= 'MEMPHIS'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY COUNT(prescription.total_claim_count) DESC
LIMIT 5;

	c.Combine your results from a and b, along with the results for Knoxville and Chattanooga. 

-- NOT FINISHED OR 100% CORRECT, MAYBE WHERE STATEMENT AND JOIN? MAYBE A CTE?

SELECT
	CASE WHEN UPPER(prescriber.nppes_provider_city)= 'NASHVILLE' THEN 'Nashville  TN'
		WHEN UPPER(prescriber.nppes_provider_city)= 'MEMPHIS' THEN 'Memphis TN'
		WHEN UPPER(prescriber.nppes_provider_city)= 'KNOXVILLE' THEN 'Knoxville TN'
		WHEN UPPER(prescriber.nppes_provider_city)= 'CHATTANOOGA' THEN 'Chattanooga TN'
		ELSE NULL END AS tennessee_cities,
	prescriber.npi AS npi_prescriber,
	COUNT(prescription.total_claim_count) As claims_count
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE prescriber.nppes_provider_city IS NOT NULL
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY COUNT(prescription.total_claim_count) DESC

