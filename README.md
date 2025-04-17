# Prompt-Managing App

## Purpose

The Prompt-Managing App is designed to help users create, manage, and test prompts for advanced Large Language Model (LLM) applications. It provides a user-friendly interface for managing prompt versions, historization, and testing, making it an essential tool for prompt engineering workflows.

---

## Functionalities

### 1. Add New Prompt

- Users can add new prompts by providing:
  - **Name**: The name of the prompt, which must follow the format `prompt/name`.
  - **Content**: The actual text of the prompt.
  - **Comment** (optional): A description or note about the prompt.
- The application automatically assigns a timestamp to indicate when the prompt was created.
- The first version of a prompt is named `prompt/name-1`.

---

### 2. Edit Existing Prompts

- Users can edit any previously added prompt.
- Editing a prompt creates a new version instead of overwriting the existing one.
- The new version is automatically assigned an incremented version number (e.g., `prompt/name-2`, `prompt/name-3`).
- Users can:
  - Modify the content of the prompt.
  - Update the comment associated with the prompt.

---

### 3. Delete Prompt Versions

- Users can delete specific versions of a prompt.
- If all versions of a prompt are deleted, the prompt itself is removed from the system.

---

### 4. View Prompts

- Users can view all prompts and their versions in a structured format.
- The application displays:
  - The name of the prompt.
  - The number of versions available.
  - The latest version of the prompt.
  - A table listing all versions with details:
    - **Version Number**
    - **Content**
    - **Timestamp**
    - **Comment**
- Prompts are selectable from a sidebar, which is always visible for easy navigation.

---

### 5. Test Prompts

- Users can test prompts directly within the application.
- A **Test** button opens a modal dialog where:
  - The prompt content is displayed.
  - Parameters in the prompt (e.g., `{parameter_1}`) are automatically detected using regex.
  - Input fields are dynamically created for each parameter, allowing users to provide values.
  - Users can select a model from a predefined list (e.g., `claude-3-5-sonnet`, `snowflake-llama-3.1-405b`).
  - The filled prompt (with parameters replaced) is sent to a backend function for testing.
  - The test result is displayed in the modal.

---

### 6. Prompt Historization

- Each prompt is versioned and historized automatically.
- Versions are represented as integer suffixes (e.g., `-1`, `-2`).
- Users can view the history of a prompt and access any specific version.

---

### 7. Snowflake Integration

- The application integrates with Snowflake for backend operations:
  - Prompts are stored in a Snowflake table.
  - A Python User-Defined Function (UDF) named `apply_prompt_parameters` is used to dynamically replace placeholders in prompts with values from a JSON object.
  - Example UDF usage:

    ```sql
    SELECT apply_prompt_parameters(
        'summarize the text in 2 sentences: {text_to_summarize}\n\nUse the history if needed:\n{history}.',
        OBJECT_CONSTRUCT('text_to_summarize', 'The quick brown fox', 'history', 'The fox was seen in the forest.')
    );
    ```

  - The UDF is implemented in Python 3.11 and handles dynamic parameter replacement.

---

### 8. Dynamic Prompt Management

- Prompts can include placeholders (e.g., `{parameter_1}`) that are dynamically replaced with user-provided values during testing.
- The application ensures that all placeholders are identified and replaced before testing.

---

### 9. Tech Stack

- **Frontend**: Streamlit 1.39.0
- **Backend**: Snowflake (Python UDFs for dynamic prompt handling)
- **Programming Language**: Python 3.11

---

## Streamlit Implementation Details

### Session State

- The application uses `st.session_state` to manage the state of the application, including:
  - Active prompt name (`st.session_state.active_prompt_name`).
  - Navigation state (`st.session_state.navigation_active_page`).
  - Prompt data for editing, deleting, and testing.

### Sidebar

- The sidebar is used for navigation and prompt selection:
  - Users can select a prompt from a dropdown list.
  - Navigation options include adding, editing, and viewing prompts.

### Modal Dialogs

- Modal dialogs are implemented using `@st.dialog` for testing prompts:
  - The dialog dynamically detects parameters in the prompt and creates input fields for them.
  - Users can provide values for the parameters and run tests directly from the modal.

### Dynamic Tables

- Prompt versions are displayed in a table using `st.table` or `st.dataframe`.
- Each row includes details such as version number, content, timestamp, and comment.

### Buttons and Interactions

- Buttons are used for actions such as:
  - Adding a new prompt.
  - Editing an existing prompt.
  - Deleting a specific version.
  - Testing a prompt.

### Snowflake Integration

- Snowflake is used as the backend database for storing and retrieving prompt data.
- Python UDFs in Snowflake handle dynamic parameter replacement in prompts.

---

## How to Run the Application

