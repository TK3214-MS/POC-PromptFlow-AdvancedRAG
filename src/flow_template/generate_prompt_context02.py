from typing import List
from promptflow import tool
from promptflow_vectordb.core.contracts import SearchResultEntity


@tool
def generate_prompt_context(search_result: List[dict]) -> str:

    existfilename = []
    content = ""

    for result in search_result:

        entity = SearchResultEntity.from_dict(result)
        filename = entity.additional_fields['filepath']

        if filename not in existfilename:
            existfilename.append(filename)
        content += entity.text

    return {"chunk" : content, "filename" : ",".join(existfilename)}