USE ROLE ACCOUNTADMIN;

/**

// I want the time to be in my time zone
ALTER ACCOUNT SET TIMEZONE = "Europe/Berlin";

// if you want to use any model
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

**/

CREATE OR ALTER WAREHOUSE PROMPT_HUB_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  COMMENT = 'HUB WH';

USE WAREHOUSE PROMPT_HUB_WH;

CREATE DATABASE PROMPT_HUB;
USE DATABASE PROMPT_HUB;

// main hybrid table for prompts
CREATE OR REPLACE HYBRID TABLE prompt_hub (
  pkey VARCHAR PRIMARY KEY,
  pname VARCHAR(255),
  pversion INT,
  pcontent VARCHAR,
  pcomment VARCHAR,
  when_changed TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
  INDEX index_pname (pname),
  INDEX index_pversion (pversion)
);

// to run some tests, we need a standard table with some text
CREATE OR REPLACE TABLE ARTICLES(
    SOURCE STRING,
    TOPIC STRING,
    CONTENT STRING
);

// function to apply parameters to the prompt
CREATE OR REPLACE FUNCTION apply_prompt_parameters(prompt STRING, params VARIANT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
HANDLER = 'apply_parameters'
AS $$

def apply_parameters(prompt, params):
    return prompt.format(**params)
$$;


// lert's add some prompts to the table
INSERT INTO PROMPT_HUB(PKEY, PNAME, PVERSION, PCONTENT, PCOMMENT) VALUES
(
'summarize/article-1',
'summarize/article',
1,
$$Summarize the following article in {number} points. Do not any preamble, return just the result.

Article:
{article}
$$,
$$This prompt is used for summarization of articles. It takes 2 parameters:
* `number` - number of points in which the text is to be summarized
* `article` - text of the article to be summarized
$$
),
(
'summarize/short-1',
'summarize/short',
1,
$$Summartize the following article in 2 sentences:
{article}
$$,
''
),
(
'just/answer-1',
'just/answer',
1,
$$Answer the following question using only your knowledge.

Question:
{question}
$$,
''
),
(
'just/answer-2',
'just/answer',
2,
$$Answer the following question using only your knowledge.
Use makdown to format the answer:

Question:
{question}
$$,
$$Ansers a question using only the knowledge of the model. Parameters:
* `question` - question to be answered
$$
)
;

// ...and add some articles to test the prompts
//  * I just copied the a few paragraphs from some articles from different sources
//  * Links to the articles are in the content
//  * I did not check the content of the articles as it was not relevant for the test
//  * I just wanted to have some text to work with
insert into articles (source, topic, content) VALUES (
'https://edition.cnn.com/2025/04/10/health/workout-mantras-mottos-wellness/index.html', -- source
'health', -- topic
$$Editor’s note: Before beginning any new exercise program, consult your doctor. Stop immediately if you experience pain.

CNN
 — 
When Nike unveiled its now-famous slogan “Just do it” in 1988, it helped propel the US-based sportswear company to worldwide fame. Ordinary people also began invoking the catchphrase to motivate themselves to tackle daunting tasks, such as sticking to an exercise routine.

That’s no surprise to researchers, who have found motivational quotes, mantras and positive self-talk help people in myriad ways.

Rear view shot of a group of sporty young people out for a run together
Related article
How long does it take to see benefits from your new workout regimen?

College students who listened to the mantra of their choice were more cheerful and had more clarity of mind afterward, according to a 2018 pilot study in the Journal of Religion and Health, while self-talk strategies facilitated learning and enhanced sports performance, a meta-analysis published in the journal Perspectives on Psychological Science found.

Researchers also uncovered a positive connection between human health and mantra meditation — the practice of focusing your mind by repeatedly chanting a mantra — in a 2022 review published in the International Journal of Yoga. The use of mantra meditation for stress relief and coping with high blood pressure was especially promising.

With mantras and mottos so helpful, many fitness coaches incorporate them when working with their clients.

Don't overthink your mantra or motto for exercising. Just let it come to you and keep it simple, experts say.
Don't overthink your mantra or motto for exercising. Just let it come to you and keep it simple, experts say. Illustration by Agne Jurkenaite/CNN
“I find them extremely useful,” said Alysha Flynn, a women’s running coach and founder of the training program What Runs You based in York, Pennsylvania. “They help people refocus their mind and develop a sustainable habit that keeps them moving and healthy for a long time.”

Motivation can be fleeting, agreed Kaya Luciani, a coach with the virtual training app Future based in Raleigh, North Carolina.

“A more reliable source of drive comes from our mindset,” Luciani said. “While mottos are bite-sized, they are also a really powerful way to hone and train our mindset. They get people thinking, ‘Maybe it is as easy as just doing it.’”$$ -- content
),
(
'https://www.bbc.com/culture/article/20250414-the-1950s-french-horror-that-inspired-psycho', -- source
'culture', -- topic
$$
'The epitome of what the horror film should be': How 1950s French horror Les Diaboliques inspired Psycho
by Adam Scovell
Seventy years old this year, Henri-Georges Clouzot's film about two women plotting murder is a masterclass in macabre dread – and inspired Hitchcock's classic among others.

Famous for writing the novel Psycho (1959), the basis for the influential 1960 Alfred Hitchcock film of the same name, author Robert Bloch understood the horror genre more than most. So when you read that he called a film his "favourite horror of all time", as he did in an interview with French magazine L'Ecran Fantastique, you have to take that appraisal seriously. The film referred to by Bloch wasn't the adaptation of his own story, nor a Hollywood classic, but instead a quietly influential French feature, 70 years old this year, that packs as much of a macabre punch as his own morbid masterpiece: Henri-Georges Clouzot's Les Diaboliques (1955).

Adapted from the novel She Who Was No More (1952) by French crime-writing partnership Pierre Boileau and Thomas Narcejac (also known as Boileau-Narcejac), Clouzot's film was a revolution in chilling cinema. It mixed techniques from film noir and horror to great effect, creating a hybrid that was deeply influential with its heart-stopping atmosphere of suspense.

Les Diaboliques concerns the tumultuous relationships of several teachers in a private boarding school situated in outer Paris. The weak heart of Christina – played by Clouzot's own wife Véra – is continually strained by the actions of her abusive husband Michel (Paul Meurisse), the school's headmaster, especially since fellow teacher Nicole (Simone Signoret) became his mistress. However, Michel's volatile behaviour is now hurting both women, so they hatch a plan. Though reluctant, Christina is convinced by Nicole to help murder Michel and make it appear accidental. Luring him to Nicole's out-of-town flat, they drown him in a bath and dump the body in the school's swimming pool, ready to be found as if the result of a drunken accident. However, when the body disappears the following day, the women are terrified as to what has happened. Did Michel survive? Or are his haunted remains wandering the school in search of revenge?$$ -- content
),
(
'https://www.foxnews.com/health/anti-aging-benefits-linked-one-surprising-health-habit', -- source
'health', -- topic
$$Anti-aging benefits linked to one surprising health habit
Meditation may help extend longevity and reduce stress, says biohacker Dave Asprey
Engaging in a long-term meditation practice could significantly alleviate stress and slow down aging, suggests a new study published in the journal Biomolecules.

Researchers from Maharishi International University (MIU), the University of Siegen, and the Uniformed Services University of the Health Sciences studied the effectiveness of transcendental meditation, which is a program where people silently repeat a mantra in their head to achieve deep relaxation.

"These results support other studies indicating that the transcendental meditation technique can reverse or remove long-lasting effects of stress," co-author Kenneth Walton, a senior researcher at MIU, told Fox News Digital. 

BIOHACKING REVEALED: WHAT TO KNOW ABOUT THE HIP HEALTH TREND EMBRACED BY BROOKE BURKE, TOM BRADY AND OTHERS

"Lasting effects of stress are now recognized as causing or contributing to all diseases and disorders," he added.
The study included two groups of participants — one ranging from 20 to 30 years old and another ranging from 55 to 72. Half of the participants followed transcendental meditation and a control group did not.

For each participant, the researchers analyzed the expression of genes linked to inflammation and aging, according to a press release from MIU.

SECRETS OF LONGEVITY FROM THE WORLD'S 'BLUE ZONES'

They found that people who practiced transcendental meditation had lower expression of the genes associated with inflammation and aging.

"The lower expression of age-related genes … extend the findings of short-term studies indicating that these practices lead to healthy aging and more resilient adaptation to stress," Walton said in the release.$$ -- content
),
(
'https://www.dw.com/en/tree-census-how-is-india-counting-its-trees/a-72252282', -- source
'ecology', -- topic
$$Tree census: How is India counting its trees?
Sonam Mishra in New Delhi
19 hours ago19 hours ago
Trees are essential allies in the fight against desertification, pollution and climate change — and Delhi is currently conducting a massive tree census.

https://p.dw.com/p/4tA7O
A road going through the forest in the Indian state of Chhattisgarh 
Forests across India are threatened by illegal logging (file photo)Image: Adarsh Sharma/DW
Advertisement

India's Forest Research Institute is organizing a count of all trees across Delhi, India's capital territory containing the city of New Delhi, amid a controversy about illegal tree felling. The decision to launch the census was recently confirmed by India's Supreme Court, with the judges instructing the institute to work towards increasing the city's green cover.

The project has been given a timeline of around four years and an estimated budget of around 44.3 million Indian rupees (over $516,600 or €455,800).

In that time, the tree census takers are expected to do more than just count the trees in the territory. Experts and volunteers should also sort the trees into species, record their height, girth, health status and exact location. Most importantly for climate scientists, they are to record the so-called carbon mass of the tree — the carbon absorbed from the atmosphere through photosynthesis.

India: Chennai's ambitious plan to boost its green cover

03:12
'One tree per person'
India aims to achieve net-zero emissions by 2070, and trees have an essential part to play in controlling carbon emissions in the world's most populous country. But there are other reasons to fight deforestation — a 2019 study by the Indian space agency ISRO reported that some 30% of India's territory is at risk of desertification, and having more trees, especially in the cities, can curb the effects of pollution and heat-related deaths.

Plant scientist Dr. Smitha Hegde believes that "at least one tree per person" is needed to achieve net zero on carbon emissions. Hegde made the claim during an interview with content creator Q Head on YouTube, where she also discussed her 2023 tree census in the port city of Mangalore. She and her team of 40 volunteers only found some 19,000 trees in public spaces of Mangalore, which has a population of around 600,000.

Notably, it took one full year to complete the census in a city many times smaller than New Delhi.

AI technology and drones to fill in for humans
Most measuring and counting are still done manually in India, with the data sorted into Excel sheets. At the same time, the census takers have started incorporating modern technologies such as remote sensing, LiDAR (Light Detection and Ranging), drones, and GIS (Geographic Information Systems), improving both the accuracy of data and the speed of the process.

$$ -- content
);
