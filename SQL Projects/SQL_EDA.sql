SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
order by funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
group by company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
group by industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
group by country
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
group by year(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
group by stage
ORDER BY 2 DESC;

-- ROLLING TOTAL OF LAYOFFS

SELECT substring(`date`, 1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
group by `Month`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT substring(`date`, 1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
group by `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off, SUM(total_off) OVER(ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
group by company
ORDER BY 2 DESC;


SELECT company, SUM(total_laid_off), YEAR(`date`)
FROM layoffs_staging2
group by company, YEAR(`date`)
ORDER by 2 DESC;


WITH company_year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(

SELECT *, dense_rank() OVER(PARTITION BY years order by total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
ORDER BY ranking
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;

WITH industry_year (industry, years, total_laid_off) AS
(
SELECT industry, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry, YEAR(`date`)
), industry_year_rank AS
(

SELECT *, dense_rank() OVER(PARTITION BY years order by total_laid_off DESC) AS ranking
FROM industry_year
WHERE years IS NOT NULL
ORDER BY ranking
)
SELECT *
FROM industry_year_rank
WHERE ranking <= 5;



