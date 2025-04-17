import streamlit as st
from datetime import datetime
from enum import Enum
from snowflake.snowpark.context import get_active_session
from textwrap import dedent
import re

MODELS = ["claude-3-5-sonnet", "snowflake-llama-3.1-405b", "deepseek-r1"]


class PageView(Enum):
    ADD_PROMPT = "add_prompt"
    EDIT_PROMPT = "edit_prompt"
    DELETE_PROMPT = "delete_prompt"
    DEFAULT = "default"


session = get_active_session()

if "prompt_to_edit" not in st.session_state:
    st.session_state.prompt_to_edit = {}

if "prompt_to_delete" not in st.session_state:
    st.session_state.prompt_to_delete = {}

if "prompt_to_test" not in st.session_state:
    st.session_state.prompt_to_test = {}

if "active_prompt_name" not in st.session_state:
    st.session_state.active_prompt_name = None

if "navigation_active_page" not in st.session_state:
    st.session_state.navigation_active_page = PageView.DEFAULT.value


def db_save_prompt(name, content, version, comment=None):
    query = dedent(
        f"""
        INSERT INTO prompt_hub.public.prompt_hub(
            pkey, pname, pversion, pcontent, pcomment
        )
        VALUES (
            '{name}-{version}',
            '{name}',
            {version},
            $${content}$$,
            $${comment}$$
        )
    """
    )
    return session.sql(query).collect()


def db_delete_prompt(name_with_version):
    query = dedent(
        f"""
        DELETE FROM prompt_hub.public.prompt_hub
        WHERE PKEY=$${name_with_version}$$
        """
    )
    return session.sql(query).collect()


def db_get_prompt_names():
    query = dedent(
        """
        SELECT DISTINCT PNAME
        FROM prompt_hub.public.prompt_hub
        ORDER BY PNAME
        """
    )
    result = session.sql(query).to_pandas()
    return result["PNAME"].tolist()


def db_get_number_of_prompt_versions(prompt_name):
    query = dedent(
        f"""
        SELECT count(*) as NO_OF_PROMPTS
        FROM prompt_hub.public.prompt_hub
        WHERE PNAME=$${prompt_name}$$
        """
    )
    result = session.sql(query).to_pandas()
    return result["NO_OF_PROMPTS"].iloc[0]


def db_get_max_prompt_version(prompt_name):
    query = dedent(
        f"""
        SELECT NVL(max(PVERSION), 0) as MAX_PROMPT_VERSION
        FROM prompt_hub.public.prompt_hub
        WHERE PNAME=$${prompt_name}$$
        """
    )
    result = session.sql(query).to_pandas()
    return result["MAX_PROMPT_VERSION"].iloc[0]


def db_get_all_prompt_details(prompt_name, version=None):
    query = dedent(
        f"""
        SELECT * 
        FROM prompt_hub.public.prompt_hub 
        WHERE PNAME=$${prompt_name}$$
        """
    )
    if version:
        query += f" AND PVERSION={version}"

    records = session.sql(query).to_pandas().to_dict(orient="records")
    return transform_prompts(records)


def db_get_specific_prompt_version_content(prompt_key):
    query = dedent(
        f"""
        SELECT * 
        FROM prompt_hub.public.prompt_hub 
        WHERE PKEY=$${prompt_key}$$
        """
    )

    content = session.sql(query).to_pandas().to_dict(orient="records")[0]["PCONTENT"]
    return content


def db_run_test_prompt(model, prompt):
    q = f"""SELECT SNOWFLAKE.CORTEX.COMPLETE('{model}', $${prompt}$$)"""
    return session.sql(q).to_pandas().iloc[0][0]


def save_prompt(name, content, comment=None):
    try:
        version = db_get_max_prompt_version(name) + 1
    except:
        version = 1
    versioned_name = f"{name}-v{version}"
    st.toast(db_save_prompt(name, content, version, comment)[0])
    return versioned_name


def set_add_prompt_form():
    st.session_state.navigation_active_page = PageView.ADD_PROMPT.value


def set_edit_prompt_values(prompt_name, version):
    st.session_state.prompt_to_edit = {
        "prompt_name": prompt_name,
        "version": version,
    }
    st.session_state.navigation_active_page = PageView.EDIT_PROMPT.value


def set_delete_prompt_values(prompt_name, version):
    st.session_state.prompt_to_delete = {
        "prompt_name": prompt_name,
        "version": version,
    }
    st.session_state.navigation_active_page = PageView.DELETE_PROMPT.value


@st.dialog("Test prompt")
def test_prompt_dialog(prompt_components):
    st.write("Testing Prompt")
    st.write(prompt_components)

    # Extract parameters from the prompt using regex
    parameters = re.findall(r"\{(.*?)\}", prompt_components)
    st.write("Detected Parameters:", parameters)

    # Create input fields for each parameter
    parameter_values = {}
    for param in parameters:
        parameter_values[param] = st.text_area(f"Value for `{param}`", key=f"input_{param}")

    # Select model
    model = st.selectbox("Model", MODELS)

    # Buttons for running the test and closing the dialog
    c1, c2 = st.columns(2)
    run_test = c1.button("Run test", use_container_width=True)
    close = c2.button("Close", use_container_width=True)

    if run_test:
        # Replace parameters in the prompt with user-provided values
        filled_prompt = prompt_components
        for param, value in parameter_values.items():
            filled_prompt = filled_prompt.replace(f"{{{param}}}", value)

        # Run the test with the filled prompt
        with st.spinner("Wait for it...", show_time=True):
            res = db_run_test_prompt(model, filled_prompt)

        st.markdown("#### Test Result")
        st.markdown(res)
        st.session_state.navigation_active_page = PageView.DEFAULT.value

    if close:
        st.session_state.navigation_active_page = PageView.DEFAULT.value
        st.rerun()


def test_prompt(prompt_name, version):
    prompt_components = db_get_specific_prompt_version_content(f"{prompt_name}-{version}")
    test_prompt_dialog(prompt_components)


def set_list_prompts_form():
    st.session_state.navigation_active_page = PageView.DEFAULT.value


def prompt_form(header, prompt_name="", content="", comment="", on_submit=None):
    form = st.form(f"form_{header.lower().replace(' ', '_')}", clear_on_submit=True)
    form.header(header)

    name = form.text_input("Prompt Name (format: prompt/name)", value=prompt_name)
    content = form.text_area("Prompt Content", value=content)
    comment = form.text_area("Comment (optional)", value=comment)
    submitted = form.form_submit_button("Save")

    if submitted and on_submit:
        on_submit(name, content, comment)


def add_prompt_form():
    st.session_state.navigation_active_page = PageView.ADD_PROMPT.value

    def on_submit(name, content, comment):
        st.write(save_prompt(name, content, comment))
        st.write("Prompt saved")
        st.session_state.navigation_active_page = PageView.DEFAULT.value
        st.session_state.active_prompt_name = name
        st.rerun()

    prompt_form("Add a New Prompt", on_submit=on_submit)


def edit_prompt_form(prompt_name, version):
    st.session_state.navigation_active_page = PageView.EDIT_PROMPT.value
    old_details = db_get_all_prompt_details(prompt_name)[prompt_name][version]
    old_content = old_details["content"]
    old_comment = old_details.get("comment", "")

    def on_submit(name, content, comment):
        st.write(save_prompt(name, content, comment))
        st.write("Prompt saved")
        st.session_state.navigation_active_page = PageView.DEFAULT.value
        st.session_state.active_prompt_name = name
        st.session_state.prompt_to_edit = {}
        st.rerun()

    prompt_form("Edit the Prompt", prompt_name, old_content, old_comment, on_submit=on_submit)


def delete_prompt_version(prompt_name, version):
    db_delete_prompt(f"{prompt_name}-{version}")
    st.session_state.navigation_active_page = PageView.DEFAULT.value
    st.session_state.prompt_to_delete = {}
    st.rerun()


def transform_prompts(data):
    transformed = {}
    for item in data:
        pname = item["PNAME"]
        pversion = str(item["PVERSION"])
        content = item["PCONTENT"]
        comment = item["PCOMMENT"]
        when_added = item["WHEN_CHANGED"]

        if pname not in transformed:
            transformed[pname] = {}

        transformed[pname][pversion] = {
            "content": content,
            "when_added": when_added,
            "comment": comment,
        }

    return transformed


def main():
    st.title("Prompt Managing App")
    st.sidebar.title("Menu")

    navigation_page = st.session_state.navigation_active_page

    if navigation_page == PageView.DEFAULT.value:
        render_default_page()
    elif navigation_page == PageView.ADD_PROMPT.value:
        add_prompt_form()
    elif navigation_page == PageView.EDIT_PROMPT.value:
        edit_prompt_form(
            st.session_state.prompt_to_edit["prompt_name"],
            st.session_state.prompt_to_edit["version"],
        )
    elif navigation_page == PageView.DELETE_PROMPT.value:
        delete_prompt_version(
            st.session_state.prompt_to_delete["prompt_name"],
            st.session_state.prompt_to_delete["version"],
        )
    # elif navigation_page == PageView.TEST_PROMPT.value:
    #     test_prompt(st.session_state.prompt_to_test)

    render_sidebar()


def render_default_page():
    if prompt_names := db_get_prompt_names():
        try:
            prompt_index = prompt_names.index(st.session_state.active_prompt_name)
        except Exception:
            prompt_index = 0

        active_prompt_name = st.sidebar.selectbox(
            "Select a Prompt", prompt_names, index=prompt_index
        )
        st.session_state.active_prompt_name = active_prompt_name

        num_versions = db_get_number_of_prompt_versions(active_prompt_name)
        _suffix = "s" if num_versions != 1 else ""
        st.markdown(
            f"### Prompt: {st.session_state.active_prompt_name} ({num_versions} version{_suffix})"
        )

        prompts = db_get_all_prompt_details(st.session_state.active_prompt_name)
        for version, details in sorted(prompts[st.session_state.active_prompt_name].items()):
            render_prompt_details(version, details)
    else:
        st.write("No prompts available to view.")


def render_prompt_details(version, details):
    st.divider()
    st.markdown(
        f"##### Version: {st.session_state.active_prompt_name}-{version}, added: {details['when_added']}"
    )
    st.caption(details.get("comment", "no comment"))
    st.code(
        details["content"],
        wrap_lines=True,
        language="python",
        line_numbers=True,
    )
    l, c, r = st.columns(3)
    l.button(
        "Edit",
        key=f"btn_edit={st.session_state.active_prompt_name}-{version}",
        kwargs={"prompt_name": st.session_state.active_prompt_name, "version": version},
        type="secondary",
        use_container_width=True,
        on_click=set_edit_prompt_values,
    )

    c.button(
        "Test",
        key=f"btn_test={st.session_state.active_prompt_name}-{version}",
        kwargs={"prompt_name": st.session_state.active_prompt_name, "version": version},
        type="secondary",
        use_container_width=True,
        on_click=test_prompt,
    )

    r.button(
        "Delete",
        key=f"btn_delete={st.session_state.active_prompt_name}-{version}",
        kwargs={"prompt_name": st.session_state.active_prompt_name, "version": version},
        type="secondary",
        use_container_width=True,
        on_click=set_delete_prompt_values,
    )


def render_sidebar():
    with st.sidebar:
        c1, c2 = st.columns(2)
        c1.button("List prompts", on_click=set_list_prompts_form, use_container_width=True)
        c2.button("New prompt", on_click=set_add_prompt_form, use_container_width=True)


if __name__ == "__main__":
    main()

# st.write("Session state:")
# st.write(st.session_state)
