USE ROLE ACCOUNTADMIN;
USE WAREHOUSE PROMPT_HUB_WH;
USE DATABASE PROMPT_HUB;


// let's check if the data is there
select * from prompt_hub;

SELECT * FROM ARTICLES;


// let's test it!

// just a question
SELECT
    OBJECT_CONSTRUCT('question', 'Why Snowflake is the best platform for GenAI?') as my_question
    , apply_prompt_parameters(p.pcontent, my_question) AS filled_prompt
    , SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet', filled_prompt) as answer
FROM prompt_hub p
WHERE p.pkey = 'just/answer-2';


// just a question, we can compare versions of the prompt or different models
SELECT
    OBJECT_CONSTRUCT('question', 'Why Snowflake is the best platform for GenAI?') as my_question
    , apply_prompt_parameters(p.pcontent, my_question) AS filled_prompt
    , SNOWFLAKE.CORTEX.COMPLETE('snowflake-llama-3.3-70b', filled_prompt) as answer
FROM prompt_hub p
WHERE p.pkey = 'just/answer-1'
UNION ALL
SELECT
    OBJECT_CONSTRUCT('question', 'Why Snowflake is the best platform for GenAI?') as my_question
    , apply_prompt_parameters(p.pcontent, my_question) AS filled_prompt
    , SNOWFLAKE.CORTEX.COMPLETE('snowflake-llama-3.1-405b', filled_prompt) as answer
FROM prompt_hub p
WHERE p.pkey = 'just/answer-2'
;


// we can join with other tables -- and this is the power of Snowflake!
// hybrid table joined with standard table!
SELECT
    a.source
    , a.topic
    , a.content
    , p.pcontent
    , OBJECT_CONSTRUCT('article', a.content) as my_object
    , apply_prompt_parameters(p.pcontent, my_object) AS filled_prompt
    , SNOWFLAKE.CORTEX.COMPLETE('snowflake-llama-3.3-70b', filled_prompt) as summary
FROM articles a
JOIN prompt_hub p
    ON p.pkey = 'summarize/short-1';

// we can also use multiple parameters in our prompts
SELECT
    a.source
    , a.topic
    , a.content
    , p.pcontent
    , OBJECT_CONSTRUCT('number', '3', 'article', a.content) as my_object
    , apply_prompt_parameters(p.pcontent, my_object) AS filled_prompt
    , SNOWFLAKE.CORTEX.COMPLETE('snowflake-arctic', filled_prompt) as summary
FROM articles a
JOIN prompt_hub p
    ON p.pkey = 'summarize/article-1';

// that's it! we can now use our prompts in SQL queries!
