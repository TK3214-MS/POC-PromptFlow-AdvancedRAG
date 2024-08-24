import shutil

# フォルダをzip化する関数
def zip_folder(folder_path, output_zip_path):
    shutil.make_archive(output_zip_path, 'zip', folder_path)

# メイン処理
def main():
    folder_path = 'src/flow_template'  # 圧縮するフォルダ
    output_zip_path = 'flow_template'  # 出力するzipファイルのパス（拡張子不要）

    zip_folder(folder_path, output_zip_path)
    print(f"{folder_path} has been zipped as {output_zip_path}.zip")

if __name__ == "__main__":
    main()