# Simple Prompt Hub in Snowflake

## Purpose

The Prompt-Managing App is designed to help users create, manage,
and test prompts for advanced Large Language Model (LLM) applications.
It provides a user-friendly interface for managing prompt versions, historization,
and testing, making it an essential tool for prompt engineering workflows.

## Setup database objects

To set up the necessary database objects, execute the SQL script provided in the `sql/setup.sql` file. This script creates the required tables, schemas, and other database components to support the Simple Prompt Hub App. Ensure you have the appropriate permissions to run the script in your Snowflake environment.

## Setup Streamlit in Snowflake

To set up the Streamlit app in Snowflake, follow these steps:

1. Navigate to the Snowflake UI and access the "Streamlit" section.
2. Create a new Streamlit app by clicking on the "Create App" button.
3. Open the newly created app and copy the content of the `streamlit_app.py` file.
4. Paste the copied content into the code editor of the new Streamlit app.
5. Before running the app, ensure you select `PROMPT_HUB_WH` as the warehouse and `PROMPT_HUB` as the database for the app to function correctly.
6. Save and run the app to launch the Simple Prompt Hub interface.

Ensure you have the necessary permissions to create and edit Streamlit apps in your Snowflake account.

## Test in SQL

To see the Prompt Hub in action, execute the queries provided in the `sql/use.sql` file. This file contains example queries to interact with the database objects created during setup. These queries demonstrate how to manage and test prompts using the Simple Prompt Hub.

Ensure you have the appropriate permissions and are connected to the `PROMPT_HUB` database and `PROMPT_HUB_WH` warehouse before running the queries.

> **Note**: This repo is for Medium blog post: https://medium.com/@bart.wrobel/prompt-hub-in-snowflake-e970cd988043
