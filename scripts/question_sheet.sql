
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT prescriber.nppes_provider_last_org_name AS last_name,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.specialty_description AS specialty,
	COUNT(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY last_name,	first_name, specialty
ORDER BY total_claims DESC
-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

--     b. Which specialty had the most total number of claims for opioids?
SELECT 
    prescriber.specialty_description AS specialty,
    SUM(prescription.total_claim_count) AS total_claims,
    COUNT(drug.opioid_drug_flag) AS opioid_class
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
LEFT JOIN drug
ON drug.drug_name = prescription.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY opioid_class DESC;
--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT
    drug.generic_name AS gen_med_name,
    MAX(prescription.total_drug_cost) AS total_daily_cost
FROM drug
JOIN prescription 
ON drug.drug_name = prescription.drug_name
GROUP BY gen_med_name
ORDER BY total_daily_cost DESC;
--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT
    drug.generic_name AS gen_med_name,
    SUM(prescription.total_drug_cost) / ROUND(MAX(prescription.total_day_supply), 2) AS total_daily_cost
FROM drug
JOIN prescription 
ON drug.drug_name = prescription.drug_name
GROUP BY gen_med_name
ORDER BY total_daily_cost DESC;
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
        ELSE 'Neither'
    END AS drug_type,
    SUM(prescription.total_drug_cost) AS total_cost
FROM drug
JOIN prescription 
ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY total_cost DESC;
-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(cbsa.cbsaname) AS tn_cbsa_count
FROM cbsa
JOIN 
WHERE UPPER(cbsa.cbsaname) LIKE '%TN%'
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT
	cbsa.cbsaname AS all_name,
	MAX(population.population) AS max_pop
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
SELECT prescription.drug_name,
	prescription.total_claim_count
FROM prescription
WHERE prescription.total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.