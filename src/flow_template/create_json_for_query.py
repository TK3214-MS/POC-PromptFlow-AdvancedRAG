from promptflow import tool
import json


# The inputs section will change based on the arguments of the tool function, after you save the code
# Adding type to arguments and return value will help the system show the types properly
# Please update the function name/signature per need
@tool
def my_python_tool(input1: str) -> str:
    print(input1)
    return input1.split(",")

    #inputを辞書型に変形する
    #クエリの数を取得する
    #「,」の数を調べる
    #「,」の数だけループする
    #keyは「0」から始める
    #辞書型(key:value)をjson形式に変更
    #json_str = json.dumps(input1)