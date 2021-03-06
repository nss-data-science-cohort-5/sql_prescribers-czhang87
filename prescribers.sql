--PART I
--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count)
FROM prescription
GROUP BY npi
ORDER BY 2 DESC
LIMIT 1;

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name,specialty_description, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name,specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;

--2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;
--Family Practice

--b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 1;
--Nurese Practitioner

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 15;

--d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?
WITH
	all_drug
	AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS all_drug_claim
		FROM prescription
		LEFT JOIN prescriber
		USING (npi)
		LEFT JOIN drug
		USING(drug_name)
		GROUP BY specialty_description
	),
	opioid_drug
	AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS opioid_claim
		FROM prescription
		LEFT JOIN prescriber
		USING (npi)
		LEFT JOIN drug
		USING(drug_name)
		WHERE opioid_drug_flag = 'Y'
		GROUP BY specialty_description
	)
SELECT *, COALESCE(ROUND(opioid_claim/all_drug_claim*100,2),0) AS opioid_pct
FROM all_drug
LEFT JOIN opioid_drug
USING (specialty_description)
ORDER BY opioid_pct DESC;
--Case Manager/Care Coordinator highest

--3. a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 1;
--INSULIN

--b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 1;
--C1 Esterase inhibitor 3495.22

--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, 
		CASE 
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type
FROM drug;

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_type, CAST(SUM(total_drug_cost) AS MONEY)
FROM (
SELECT drug_name, total_drug_cost,
		CASE 
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type
FROM drug
RIGHT JOIN prescription
USING(drug_name)
) AS total_drug_cost_by_type
GROUP BY drug_type
ORDER BY 2 DESC;
-- Opioid higher than antibiotics

--5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM fips_county AS f
LEFT JOIN cbsa AS c
USING(fipscounty)
WHERE f.state = 'TN';
--10

--Jacob code
SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, 
	   SUM(population) AS total_pop
FROM population
LEFT JOIN cbsa
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop;
--Nashville the largest, Morristown the smallest

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, population
FROM population
LEFT JOIN fips_county
USING (fipscounty)
LEFT JOIN cbsa
USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;
--Sevier

--6. a. Find all rows in the  table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	CONCAT(nppes_provider_first_name,' ',nppes_provider_last_org_name) AS prescribers,
	drug_name, 
	total_claim_count, 
	opioid_drug_flag
FROM prescription
LEFT JOIN drug
USING (drug_name)
LEFT JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

/*7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') 
	in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
	**Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.
*/

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';


SELECT npi, drug_name, specialty_description, nppes_provider_city, opioid_drug_flag
FROM prescription 
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

/* b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
	whether or not the prescriber had any claims. You should report the npi, the drug name, 
	and the number of claims (total_claim_count).
*/ 

SELECT npi, prescription.drug_name, total_claim_count
FROM (
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
) as npi_drug
LEFT JOIN prescription
USING(npi, drug_name)
;

--Jacob code
SELECT p1.npi, d.drug_name, COALESCE(total_claim_count, 0) 
FROM prescriber AS p1
CROSS JOIN drug AS d
FULL JOIN prescription AS p2
USING (drug_name,npi)
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
ORDER BY 3 DESC;

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi, prescription.drug_name, COALESCE(total_claim_count, 0) AS total_claim_count
FROM (
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
) as npi_drug
LEFT JOIN prescription
USING(npi, drug_name)
ORDER BY total_claim_count DESC
;

--PART II
--1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT npi
FROM prescriber
EXCEPT 
SELECT npi
FROM prescription;

--2.  a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING (npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

--b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING (npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

--c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists? 
--Combine what you did for parts a and b into a single query to answer this question.
WITH
	Family_Practice_drug AS(
	SELECT generic_name, SUM(total_claim_count) AS Family_Practice_drug_claims
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	LEFT JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Family Practice'
	GROUP BY generic_name
	ORDER BY 2 DESC
	LIMIT 5),
	
	Cardiologists_drug AS (
	SELECT generic_name, SUM(total_claim_count) AS Cardiologists_drug_claims
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	LEFT JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Cardiology'
	GROUP BY generic_name
	ORDER BY 2 DESC
	LIMIT 5)
SELECT 
	generic_name, 
	Family_Practice_drug_claims, 
	Cardiologists_drug_claims
FROM Family_Practice_drug
INNER JOIN Cardiologists_drug
USING (generic_name);

--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of 
--claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT npi, SUM(total_claim_count), nppes_provider_city
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY 2 DESC
LIMIT 5
; 
  
--b. Now, report the same for Memphis.
SELECT npi, SUM(total_claim_count), nppes_provider_city
FROM prescription
LEFT JOIN prescriber
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY 2 DESC
LIMIT 5
;

--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
WITH 
	Nashville_prescriber AS(
	SELECT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY 2 DESC
	LIMIT 5),
	
	Memphis_prescriber AS (
	SELECT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
	ORDER BY 2 DESC
	LIMIT 5),
	
	Knoxville_prescriber AS (
	SELECT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY 2 DESC
	LIMIT 5),
	
	Chattanooga_prescriber AS (
	SELECT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY npi, nppes_provider_city
	ORDER BY 2 DESC
	LIMIT 5)
	
SELECT *
FROM Nashville_prescriber
UNION 
SELECT *
FROM Memphis_prescriber
UNION 
SELECT *
FROM Knoxville_prescriber
UNION 
SELECT *
FROM Chattanooga_prescriber
ORDER BY 3,2 DESC;

--4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. 
--Report the county name and number of overdose deaths.
SELECT county, overdose_deaths
FROM overdose_deaths
LEFT JOIN fips_county
USING(fipscounty)
WHERE year = 2017
	AND overdose_deaths > (
		SELECT AVG(overdose_deaths)
		FROM overdose_deaths
		LEFT JOIN fips_county
		USING(fipscounty)
		WHERE year = 2017)
ORDER BY 2 DESC
;

--5.  a. Write a query that finds the total population of Tennessee.
SELECT SUM(population)
FROM population;
--6597381

--b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name,
--its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT 
	county,
	population,
	ROUND(population/(SELECT SUM(population) FROM population)*100,2) AS pop_pct
FROM population
LEFT JOIN fips_county
USING(fipscounty)
ORDER BY 3 DESC;