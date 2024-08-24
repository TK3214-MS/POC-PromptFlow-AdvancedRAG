import os
import re

# .envファイルを読み込む関数
def load_env_file(env_file_path):
    env_vars = {}
    with open(env_file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                env_vars[key.strip()] = value.strip().strip('"')
    return env_vars

# テンプレートファイルの変数を環境変数で置き換える関数
def replace_variables(template_path, output_path, env_vars):
    with open(template_path, 'r') as template_file:
        content = template_file.read()
    
    # <>で囲まれた変数を正規表現で検索して置き換え
    def replacer(match):
        var_name = match.group(1)
        return env_vars.get(var_name, match.group(0))

    pattern = re.compile(r'<(.*?)>')
    replaced_content = pattern.sub(replacer, content)
    
    with open(output_path, 'w') as output_file:
        output_file.write(replaced_content)

# メイン処理
def main():
    env_file_path = '.env'
    template_path = 'src/flow.dag.template.yaml'
    output_path = 'src/flow_template/flow.dag.yaml'

    env_vars = load_env_file(env_file_path)
    replace_variables(template_path, output_path, env_vars)
    print(f"Replaced content saved to {output_path}")

if __name__ == "__main__":
    main()
